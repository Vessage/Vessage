//
//  UserService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getUserService() -> UserService{
        return ServiceContainer.getService(UserService)
    }
}

let UserProfileUpdatedUserIdValue = "UserProfileUpdatedUserIdValue"
let UserNoteNameUpdatedValue = "UserNoteNameUpdatedValue"
let UserProfileUpdatedUserValue = "UserProfileUpdatedUserValue"
let UserChatImagesUpdatedValue = "UserChatImagesUpdatedValue"
let USER_LATER_SET_CHAT_BCG_KEY = "SET_CHAT_BCG_LATER"

//MARK:UserService
class UserService:NSNotificationCenter, ServiceProtocol {
    static let userProfileUpdated = "userProfileUpdated"
    static let userNoteNameUpdated = "userNoteNameUpdated"
    static let userChatImagesUpdated = "userChatImagesUpdated"
    static let myChatImagesUpdated = "myChatImagesUpdated"
    @objc static var ServiceName:String {return "User Service"}
    
    private var forceGetUserProfileOnce:Bool = false
    private let notUpdateUserInMinutes:Double = 18
    private let getActiveUserIntervalHours = 6.0
    private let getNearUserIntervalHours = 2.0
    private var userNotedNames = [String:String]()
    private(set) var myProfile:VessageUser!
    private(set) var myChatImages = [ChatImage]()
    private(set) var activeUsers = [VessageUser]()
    private(set) var nearUsers = [VessageUser]()
    
    var isUserMobileValidated:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mobile)
    }
    
    var isUserChatBackgroundIsSeted:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mainChatImage)
    }
    
    @objc func userLoginInit(userId: String) {
        initServiceData(userId)
    }
    
    @objc func userLogout(userId: String) {
        setServiceNotReady()
        removeUserDeviceTokenFromServer(VessageSetting.deviceToken)
        myProfile = nil
        activeUsers.removeAll()
        nearUsers.removeAll()
    }
    
    func setForeceGetUserProfileIgnoreTimeLimit(){
        forceGetUserProfileOnce = true
    }
    
    private func initServiceData(userId: String){
        myProfile = initMyProfile({ (user) -> Void in
            if user != nil{
                if self.myProfile == nil{
                    self.myProfile = user
                    self.prepareServiceAndSetReady()
                }else{
                    self.myProfile = user
                }
            }else if self.myProfile == nil{
                ServiceContainer.instance.postInitServiceFailed("INIT_USER_DATA_ERROR")
            }
        })
        if myProfile != nil{
            self.prepareServiceAndSetReady()
        }
        if let notedNames = UserSetting.getUserValue("UserNotedNames") as? [String:String]{
            self.userNotedNames = notedNames
        }
    }
    
    private func prepareServiceAndSetReady(){
        self.registUserDeviceToken(VessageSetting.deviceToken)
        self.getActiveUsers()
        if let images = PersistentManager.sharedInstance.getModel(UserChatImages.self, idValue: self.myProfile.userId)?.chatImages{
            self.myChatImages = images
        }
        self.fetchUserChatImages(self.myProfile.userId)
        self.setServiceReady()
    }
    
    private func initMyProfile(updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        let req = GetUserInfoRequest()
        let user = PersistentManager.sharedInstance.getModel(VessageUser.self, idValue: UserSetting.userId)
        setForeceGetUserProfileIgnoreTimeLimit()
        getUserProfileByReq(user?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func registNewUserByMobile(mobile:String,noteName:String,updatedCallback:(user:VessageUser?)->Void) {
        let req = RegistMobileUserRequest()
        req.mobile = mobile
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<VessageUser>) -> Void in
            if result.isFailure{
                updatedCallback(user: nil)
            }else if let user = result.returnObject{
                #if DEBUG
                    print("AccountId=\(user.accountId),UserId=\(user.userId)")
                #endif
                user.nickName = noteName
                user.lastUpdatedTime = NSDate()
                user.saveModel()
                self.setUserNoteName(user.userId, noteName: noteName)
                PersistentManager.sharedInstance.saveAll()
                updatedCallback(user: user)
                self.postNotificationNameWithMainAsync(UserService.userProfileUpdated, object: self, userInfo: [UserProfileUpdatedUserValue:user])
            }else{
                updatedCallback(user: nil)
            }
        }
    }
    
    func getCachedUserByMobile(mobile:String) -> VessageUser? {
        let mobileHash = mobile.md5
        return PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ !String.isNullOrWhiteSpace($0.mobile) && (mobile == $0.mobile || mobileHash == $0.mobile)}.first
    }
    
    func getUserProfileByMobile(mobile:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        let result:VessageUser? = getCachedUserByMobile(mobile)
        let req = GetUserInfoByMobileRequest()
        req.mobile = mobile
        getUserProfileByReq(result?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return result
    }
    
    func getCachedUserByAccountId(accountId:String) -> VessageUser? {
        return PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ !String.isNullOrWhiteSpace($0.accountId) && accountId == $0.accountId}.first
    }
    
    func fetchUserByAccountId(accountId:String,updatedCallback:(user:VessageUser?)->Void){
        let req = GetUserInfoByAccountIdRequest()
        req.accountId = accountId
        getUserProfileByReq(nil, req: req){ user in
            updatedCallback(user: user)
        }
    }
    
    func getUserProfileByAccountId(accountId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = getCachedUserByAccountId(accountId)
        let req = GetUserInfoByAccountIdRequest()
        req.accountId = accountId
        getUserProfileByReq(user?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func getCachedUserProfile(userId:String) -> VessageUser?{
        return PersistentManager.sharedInstance.getModel(VessageUser.self, idValue: userId)
    }
    
    func fetchUserProfile(userId:String){
        setForeceGetUserProfileIgnoreTimeLimit()
        let req = GetUserInfoRequest()
        req.userId = userId
        getUserProfileByReq(nil, req: req){ user in}
    }
    
    func getUserProfile(userId:String) -> VessageUser? {
        return getUserProfile(userId) { (user) in
            
        }
    }
    
    func getUserProfile(userId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = getCachedUserProfile(userId)
        let req = GetUserInfoRequest()
        req.userId = userId
        getUserProfileByReq(user?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func fetchLatestUserProfile(cachedUser:VessageUser){
        let req = GetUserInfoRequest()
        req.userId = cachedUser.userId
        getUserProfileByReq(cachedUser.lastUpdatedTime, req: req){ user in
        }
    }
    
    private func getUserProfileByReq(lastUpdatedTime:NSDate?,req:BahamutRFRequestBase,updatedCallback:(user:VessageUser?)->Void){
        if forceGetUserProfileOnce == false{
            if let lt = lastUpdatedTime{
                if NSDate().totalMinutesSince1970.doubleValue - lt.totalMinutesSince1970.doubleValue < notUpdateUserInMinutes{
                    return
                }
            }
        }
        forceGetUserProfileOnce = false
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<VessageUser>) -> Void in
            if result.isFailure{
                updatedCallback(user: nil)
            }else if let user = result.returnObject{
                #if DEBUG
                    print("AccountId=\(user.accountId),UserId=\(user.userId)")
                #endif
                user.lastUpdatedTime = NSDate()
                user.saveModel()
                PersistentManager.sharedInstance.saveAll()
                updatedCallback(user: user)
                self.postNotificationNameWithMainAsync(UserService.userProfileUpdated, object: self, userInfo: [UserProfileUpdatedUserValue:user])
            }else{
                updatedCallback(user: nil)
            }
        }
    }
}

//MARK: Fetch Special Users
extension UserService{
    
    func getActiveUsers(checkTime:Bool = false,callback:(([VessageUser])->Void)? = nil){
        let key = "GET_ACTIVE_USERS_TIME"
        if checkTime{
            if let time = UserSetting.getUserNumberValue(key){
                if NSDate().totalHoursSince1970.doubleValue - time.doubleValue < getActiveUserIntervalHours{
                    return
                }
            }
        }
        let req = GetActiveUsersInfoRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[VessageUser]>) in
            if result.isSuccess{
                if let activeUsers = result.returnObject{
                    UserSetting.setUserNumberValue(key, value: NSDate().totalHoursSince1970)
                    self.activeUsers = activeUsers
                }
            }else{
                self.activeUsers.removeAll()
            }
            callback?(self.activeUsers)
        }
    }
    
    func getNearUsers(location:String,checkTime:Bool = false,callback:(([VessageUser])->Void)? = nil){
        let key = "GET_NEAR_USERS_TIME"
        if checkTime{
            if let time = UserSetting.getUserNumberValue(key){
                if NSDate().totalHoursSince1970.doubleValue - time.doubleValue < getNearUserIntervalHours{
                    return
                }
            }
        }
        let req = GetNearUsersInfoRequest()
        req.location = location
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[VessageUser]>) in
            if result.isSuccess{
                if let nearUsers = result.returnObject{
                    UserSetting.setUserNumberValue(key, value: NSDate().totalHoursSince1970)
                    self.nearUsers = nearUsers
                }
            }else{
                self.nearUsers.removeAll()
            }
            callback?(self.nearUsers)
        }
    }
    
}

//MARK: User Note Name
extension UserService{
    func getUserNotedNameIfExists(userId:String) -> String? {
        return userNotedNames[userId] ?? getCachedUserProfile(userId)?.nickName
    }
    
    func getUserNotedName(userId:String) -> String {
        return getUserNotedNameIfExists(userId) ?? "UNLOADED_USER".localizedString()
    }
    
    func setUserNoteName(userId:String,noteName:String){
        userNotedNames[userId] = noteName
        UserSetting.setUserValue("UserNotedNames", value: userNotedNames)
        self.postNotificationName(UserService.userNoteNameUpdated, object: self, userInfo: [UserProfileUpdatedUserIdValue:userId,UserNoteNameUpdatedValue:noteName])
    }
}

//MARK: User Device Token
let registDeviceTokenIntervalDays = 13.0
extension UserService{
    func registUserDeviceToken(deviceToken:String!, checkTime:Bool = false){
        let key = "USER_REGIST_DEVICE_TOKEN_TIME"
        
        if String.isNullOrEmpty(deviceToken){
            return
        }
        if checkTime {
            if let time = UserSetting.getUserNumberValue(key){
                if NSDate().totalDaysSince1970.doubleValue - time.doubleValue < registDeviceTokenIntervalDays{
                    return
                }
            }
            
        }
        let req = RegistUserDeviceRequest()
        req.setDeviceType(RegistUserDeviceRequest.DEVICE_TYPE_IOS)
        req.setDeviceToken(deviceToken)
        #if DEBUG
            print("Registing Device Token:\(deviceToken)")
        #endif
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                #if DEBUG
                    print("Registed Device Token")
                #endif
                UserSetting.setUserNumberValue(key, value: NSDate().totalDaysSince1970)
            }else{
                #if DEBUG
                    print("Regist Device Token Failure")
                #endif
            }
        }
    }
    
    func removeUserDeviceTokenFromServer(deviceToken:String!){
        let req = RemoveUserDeviceRequest()
        req.setDeviceToken(deviceToken)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
        }
    }
}

//MARK: Search User
extension UserService{
    func searchUser(keyword:String,callback:(keyword:String,[VessageUser])->Void){
        if keyword == UserSetting.lastLoginAccountId{
            return
        }
        let users = PersistentManager.sharedInstance.getAllModel(VessageUser).filter { (user) -> Bool in
            if self.myProfile.userId == user.userId{
                return false
            }
            if let mobile = user.mobile{
                if mobile.hasBegin(keyword){
                    return true
                }
            }
            if let aId = user.accountId{
                if aId.hasBegin(keyword){
                    return true
                }
            }
            if let nickName = user.nickName{
                if nickName.containsString(keyword){
                    return true
                }
            }
            if let noteName = userNotedNames[user.userId]{
                return noteName.containsString(keyword)
            }
            return false
        }
        if users.count > 0{
            callback(keyword: keyword,users)
        }else if keyword.isMobileNumber(){
            getUserProfileByMobile(keyword, updatedCallback: { (user) -> Void in
                if let u = user{
                    callback(keyword: keyword,[u])
                }else{
                    callback(keyword: keyword,[])
                }
            })
        }
    }
}

//MARK: User Profile
extension UserService{
    func changeUserNickName(newNickName:String,callback:(Bool)->Void){
        let req = ChangeNickRequest()
        req.nick = newNickName
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
            if result.isSuccess{
                self.myProfile.nickName = newNickName
                self.myProfile.saveModel()
            }
            callback(result.isSuccess)
        }
    }
    
    
    func setMyAvatar(avatar:String,callback:(Bool)->Void){
        let req = ChangeAvatarRequest()
        req.avatar = avatar
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
            if result.isSuccess{
                self.myProfile.avatar = avatar
                self.myProfile.saveModel()
            }
            callback(result.isSuccess)
        }
    }
    
    func changeUserMotto(newMotto:String,callback:(Bool)->Void) {
        let req = ChangeMottoRequest()
        req.motto = newMotto
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
            if result.isSuccess{
                self.myProfile.motto = newMotto
                self.myProfile.saveModel()
            }
            callback(result.isSuccess)
        }
        
    }
}

//MARK: Sex Value
extension UserService{
    func setUserSexValue(newValue:Int,callback:(Bool)->Void){
        if newValue == self.myProfile.sex {
            callback(true)
        }else{
            let req = ChangeUserSexValueRequest()
            req.value = newValue
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
                if result.isSuccess{
                    self.myProfile.sex = newValue
                    self.myProfile.saveModel()
                }
                callback(result.isSuccess)
            }
        }
    }
}

//MARK: User Chat Images
extension UserService{
    
    func fetchUserChatImages(userId:String) {
        let req = GetUserChatImageRequest()
        req.userId = userId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<UserChatImages>) in
            if result.isSuccess{
                if let r = result.returnObject{
                    r.saveModel()
                    if r.userId == self.myProfile.userId{
                        self.myChatImages = r.chatImages
                        self.postNotificationNameWithMainAsync(UserService.myChatImagesUpdated, object: self, userInfo: [UserChatImagesUpdatedValue:r])
                    }
                    self.postNotificationNameWithMainAsync(UserService.userChatImagesUpdated, object: self, userInfo: [UserChatImagesUpdatedValue:r])
                }
            }
        }
    }
    
    func setChatBackground(imageId:String,imageType:String?,callback:(Bool)->Void){
        if String.isNullOrEmpty(imageType) {
            setMainChatBackground(imageId, callback: callback)
        }else{
            setTypedChatBackground(imageId, imageType: imageType!, callback: callback)
        }
    }
    
    private func setTypedChatBackground(imageId:String,imageType:String,callback:(Bool)->Void){
        let req = UpdateChatImageRequest()
        req.image = imageId
        req.imageType = imageType
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
            if result.isSuccess{
                if let userChatImages = PersistentManager.sharedInstance.getModel(UserChatImages.self, idValue: self.myProfile!.userId){
                    if let chatImages = userChatImages.chatImages{
                        var exists = false
                        chatImages.forIndexEach({ (i, element) in
                            if element.imageType == imageType{
                                chatImages[i].imageId = imageId
                                exists = true
                            }
                        })
                        if !exists{
                            userChatImages.chatImages.append(ChatImage(dictionary: ["imageId":imageId,"imageType": imageType]))
                        }
                    }else{
                        userChatImages.chatImages = [ChatImage(dictionary: ["imageId":imageId,"imageType": imageType])]
                    }
                    userChatImages.saveModel()
                    self.myChatImages = userChatImages.chatImages
                    self.postNotificationNameWithMainAsync(UserService.myChatImagesUpdated, object: self, userInfo: [UserChatImagesUpdatedValue:userChatImages])
                    self.postNotificationNameWithMainAsync(UserService.userChatImagesUpdated, object: self, userInfo: [UserChatImagesUpdatedValue:userChatImages])
                }
            }
            callback(result.isSuccess)
        }
    }
    
    private func setMainChatBackground(imageId:String,callback:(Bool)->Void){
        let req = ChangeMainChatImageRequest()
        req.image = imageId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
            if result.isSuccess{
                self.myProfile.mainChatImage = imageId
                self.myProfile.saveModel()
            }
            callback(result.isSuccess)
        }
    }
    
}

//MARK: User Mobile
class ValidateMobileResult:MsgResult{
    var newUserId:String!
}

extension UserService{
    func sendValidateMobilSMS(mobile:String,callback:(suc:Bool)->Void){
        
        let req = SendMobileVSMSRequest()
        req.mobile = mobile
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) -> Void in
            if result.isSuccess{
                callback(suc: true)
            }else{
                callback(suc: false)
            }
        }
        
    }
    
    func validateMobile(smsAppkey:String!,mobile:String!,zone:String!, code:String!,callback:(suc:Bool,newUserId:String?)->Void){
        
        let req = ValidateMobileVSMSRequest()
        req.smsAppkey = smsAppkey
        req.mobile = mobile
        req.zoneCode = zone
        req.code = code
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ValidateMobileResult>) -> Void in
            if result.isSuccess{
                
                if let newUserId = result.returnObject?.newUserId{ //this mobile was received the others message,bind the mobile account registed by server
                    #if DEBUG
                        print("---------------------------------------------")
                        print("Bind Account:\(self.myProfile.accountId)")
                        print("Origin UserId:\(self.myProfile.userId)")
                        print("Replace UserId:\(newUserId)")
                        print("---------------------------------------------")
                    #endif
                    
                    callback(suc: true, newUserId: newUserId)
                }else{
                    self.myProfile.mobile = mobile
                    self.myProfile.saveModel()
                    PersistentManager.sharedInstance.saveAll()
                    callback(suc: true, newUserId: nil)
                }
            }else{
                callback(suc: false,newUserId: nil)
            }
        }
    }
}