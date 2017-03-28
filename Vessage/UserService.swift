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
        return ServiceContainer.getService(UserService.self)
    }
}

let UserProfileUpdatedUserIdValue = "UserProfileUpdatedUserIdValue"
let UserNoteNameUpdatedValue = "UserNoteNameUpdatedValue"
let UserProfileUpdatedUserValue = "UserProfileUpdatedUserValue"
let UserChatImagesUpdatedValue = "UserChatImagesUpdatedValue"
let USER_LATER_SET_CHAT_BCG_KEY = "SET_CHAT_BCG_LATER"

//MARK:UserService
class UserService:NotificationCenter, ServiceProtocol {
    static let userProfileUpdated = "userProfileUpdated".asNotificationName()
    static let userNoteNameUpdated = "userNoteNameUpdated".asNotificationName()
    static let userChatImagesUpdated = "userChatImagesUpdated".asNotificationName()
    static let myChatImagesUpdated = "myChatImagesUpdated".asNotificationName()
    
    @objc static var ServiceName:String {return "User Service"}
    
    fileprivate var forceGetUserProfileOnce:Bool = false
    fileprivate let notUpdateUserInMinutes:Double = 18
    fileprivate let getActiveUserIntervalHours = 6.0
    fileprivate let getNearUserIntervalHours = 1.0
    fileprivate var userNotedNames = [String:String]()
    fileprivate(set) var myProfile:VessageUser!{
        didSet{
            if let _ = myProfile{
                if !isUserMobileValidated && UserSetting.isSettingEnable("USE_TMP_MOBILE") {
                    myProfile.mobile = defaultTempMobile
                }
            }
        }
    }
    
    fileprivate(set) var activeUsers = [VessageUser]()
    fileprivate(set) var nearUsers = [VessageUser]()
    
    var isUserChatBackgroundIsSeted:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mainChatImage)
    }
    
    @objc func userLoginInit(_ userId: String) {
        DispatchQueue.main.async { 
            self.initServiceData(userId)
        }
    }
    
    @objc func userLogout(_ userId: String) {
        setServiceNotReady()
        activeUsers.removeAll()
        nearUsers.removeAll()
    }
    
    func setForeceGetUserProfileIgnoreTimeLimit(){
        forceGetUserProfileOnce = true
    }
    
    fileprivate func initServiceData(_ userId: String){
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
    
    fileprivate func prepareServiceAndSetReady(){
        self.registUserDeviceToken(VessageSetting.deviceToken)
        self.getActiveUsers()
        //self.initChatImages()
        self.setServiceReady()
    }
    
    @discardableResult
    fileprivate func initMyProfile(_ updatedCallback:@escaping (_ user:VessageUser?)->Void) -> VessageUser?{
        let req = GetUserInfoRequest()
        let user = PersistentManager.sharedInstance.getModel(VessageUser.self, idValue: UserSetting.userId)
        setForeceGetUserProfileIgnoreTimeLimit()
        getUserProfileByReq(user?.lastUpdatedTime, req: req){ user in
            updatedCallback(user)
        }
        return user
    }
    
    @discardableResult
    func getCachedUserByMobile(_ mobile:String) -> VessageUser? {
        let mobileHash = mobile.md5
        return PersistentManager.sharedInstance.getAllModel(VessageUser.self).filter{ !String.isNullOrWhiteSpace($0.mobile) && (mobile == $0.mobile || mobileHash == $0.mobile)}.first
    }
    
    @discardableResult
    func getUserProfileByMobile(_ mobile:String,updatedCallback:@escaping (_ user:VessageUser?)->Void) -> VessageUser?{
        let result:VessageUser? = getCachedUserByMobile(mobile)
        fetchUserProfileByMobile(mobile, lastUpdatedTime: result?.lastUpdatedTime as Date?,updatedCallback: updatedCallback)
        return result
    }
    
    func fetchUserProfileByMobile(_ mobile:String,lastUpdatedTime:Date?,updatedCallback:@escaping (_ user:VessageUser?)->Void){
        let req = GetUserInfoByMobileRequest()
        req.mobile = mobile
        getUserProfileByReq(lastUpdatedTime, req: req){ user in
            updatedCallback(user)
        }
    }
    
    @discardableResult
    func clearTempUsers(_ chattingUserIds:[String]) -> [VessageUser] {
        var userIds = chattingUserIds.map{$0}
        userIds.append(myProfile.userId)
        let tmpUsers = PersistentManager.sharedInstance.getAllModel(VessageUser.self).filter{ $0.userId == nil || !userIds.contains($0.userId)}
        PersistentManager.sharedInstance.removeModels(tmpUsers)
        return tmpUsers
    }
    
    func getCachedUserByAccountId(_ accountId:String) -> VessageUser? {
        return PersistentManager.sharedInstance.getAllModel(VessageUser.self).filter{ !String.isNullOrWhiteSpace($0.accountId) && accountId == $0.accountId}.first
    }
    
    func fetchUserByAccountId(_ accountId:String,updatedCallback:@escaping (_ user:VessageUser?)->Void){
        let req = GetUserInfoByAccountIdRequest()
        req.accountId = accountId
        getUserProfileByReq(nil, req: req){ user in
            updatedCallback(user)
        }
    }
    
    @discardableResult
    func getUserProfileByAccountId(_ accountId:String,updatedCallback:@escaping (_ user:VessageUser?)->Void) -> VessageUser?{
        
        let user = getCachedUserByAccountId(accountId)
        let req = GetUserInfoByAccountIdRequest()
        req.accountId = accountId
        getUserProfileByReq(user?.lastUpdatedTime as Date?, req: req){ user in
            updatedCallback(user)
        }
        return user
    }
    
    func getCachedUserProfile(_ userId:String) -> VessageUser?{
        return PersistentManager.sharedInstance.getModel(VessageUser.self, idValue: userId)
    }
    
    func deleteCachedUsers(_ userIds:[String]) {
        PersistentManager.sharedInstance.removeModels(VessageUser(), idArray: userIds)
    }
    
    func fetchUserProfile(_ userId:String){
        setForeceGetUserProfileIgnoreTimeLimit()
        let req = GetUserInfoRequest()
        req.userId = userId
        getUserProfileByReq(nil, req: req){ user in}
    }
    
    func getUserProfile(_ userId:String) -> VessageUser? {
        return getUserProfile(userId) { (user) in
            
        }
    }
    
    @discardableResult
    func getUserProfile(_ userId:String,updatedCallback:@escaping (_ user:VessageUser?)->Void) -> VessageUser?{
        
        let user = getCachedUserProfile(userId)
        let req = GetUserInfoRequest()
        req.userId = userId
        getUserProfileByReq(user?.lastUpdatedTime as Date?, req: req){ user in
            updatedCallback(user)
        }
        return user
    }
    
    func fetchLatestUserProfile(_ cachedUser:VessageUser){
        let req = GetUserInfoRequest()
        req.userId = cachedUser.userId
        getUserProfileByReq(cachedUser.lastUpdatedTime as Date?, req: req){ user in
        }
    }
    
    fileprivate func getUserProfileByReq(_ lastUpdatedTime:Date?,req:BahamutRFRequestBase,updatedCallback:@escaping (_ user:VessageUser?)->Void){
        if forceGetUserProfileOnce == false{
            if let lt = lastUpdatedTime{
                if Date().totalMinutesSince1970.doubleValue - lt.totalMinutesSince1970.doubleValue < notUpdateUserInMinutes{
                    return
                }
            }
        }
        forceGetUserProfileOnce = false
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<VessageUser>) -> Void in
            if result.isFailure{
                updatedCallback(nil)
            }else if let user = result.returnObject{
                user.lastUpdatedTime = NSDate() as Date!
                user.saveModel()
                PersistentManager.sharedInstance.saveAll()
                updatedCallback(user)
                self.postNotificationNameWithMainAsync(UserService.userProfileUpdated, object: self, userInfo: [UserProfileUpdatedUserValue:user])
            }else{
                updatedCallback(nil)
            }
        }
    }
    
    func fetchUserProfilesByUserIds(_ userIds:[String],callback:(([VessageUser]?)->Void)?) {
        if userIds.count == 0 {
            callback?([])
        }else{
            let req = GetUsersProfileRequest()
            req.userIds = userIds
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[VessageUser]>) -> Void in
                if result.isSuccess{
                    if let users = result.returnObject{
                        users.saveBahamutObjectModels()
                        users.forEach({ (u) in
                            self.postNotificationNameWithMainAsync(UserService.userProfileUpdated, object: self, userInfo: [UserProfileUpdatedUserValue:u])
                        })
                        callback?(users)
                    }
                }else{
                    callback?(nil)
                }
            }
            
        }
    }
    
    func matchUserProfilesByMobiles(_ mobiles:[String],callback:(([MobileMatchedUser]?)->Void)?) {
        if mobiles.count == 0 {
            callback?([])
        }else{
            let req = MatchUsersWithMobileRequest()
            req.mobiles = mobiles
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[MobileMatchedUser]>) -> Void in
                if result.isSuccess{
                    if let users = result.returnObject{
                        callback?(users)
                    }
                }else{
                    callback?(nil)
                }
            }
            
        }
    }
}

//MARK: Fetch Special Users
extension UserService{
    
    func getActiveUsers(_ checkTime:Bool = false,callback:(([VessageUser])->Void)? = nil){
        let key = "GET_ACTIVE_USERS_TIME"
        if checkTime{
            if let time = UserSetting.getUserNumberValue(key){
                if Date().totalHoursSince1970.doubleValue - time.doubleValue < getActiveUserIntervalHours{
                    return
                }
            }
        }
        let req = GetActiveUsersInfoRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[VessageUser]>) in
            if result.isSuccess{
                if let activeUsers = result.returnObject{
                    UserSetting.setUserNumberValue(key, value: Date().totalHoursSince1970)
                    self.activeUsers = activeUsers
                }
            }else{
                self.activeUsers.removeAll()
            }
            callback?(self.activeUsers)
        }
    }
    
    func getNearUsers(_ location:String,checkTime:Bool = true,callback:(([VessageUser])->Void)? = nil){
        let key = "GET_NEAR_USERS_TIME"
        if checkTime{
            if let time = UserSetting.getUserNumberValue(key){
                if Date().totalHoursSince1970.doubleValue - time.doubleValue < getNearUserIntervalHours{
                    return
                }
            }
        }
        let req = GetNearUsersInfoRequest()
        req.location = location
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[VessageUser]>) in
            if result.isSuccess{
                if let nearUsers = result.returnObject{
                    UserSetting.setUserNumberValue(key, value: Date().totalHoursSince1970)
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
    func getUserNotedNameIfExists(_ userId:String) -> String? {
        if userId == UserSetting.userId {
            return "ME".localizedString()
        }
        return userNotedNames[userId] ?? getCachedUserProfile(userId)?.nickName
    }
    
    func getUserNotedName(_ userId:String) -> String {
        return getUserNotedNameIfExists(userId) ?? "UNLOADED_USER".localizedString()
    }
    
    func setUserNoteName(_ userId:String,noteName:String){
        userNotedNames[userId] = noteName
        UserSetting.setUserValue("UserNotedNames", value: userNotedNames)
        self.post(name: (UserService.userNoteNameUpdated), object: self, userInfo: [UserProfileUpdatedUserIdValue:userId,UserNoteNameUpdatedValue:noteName])
    }
}

//MARK: User Device Token
let registDeviceTokenIntervalDays = 13.0
extension UserService{
    func registUserDeviceToken(_ deviceToken:String!, checkTime:Bool = false){
        let key = "USER_REGIST_DEVICE_TOKEN_TIME"
        
        if String.isNullOrEmpty(deviceToken){
            return
        }
        if checkTime {
            if let time = UserSetting.getUserNumberValue(key){
                if Date().totalDaysSince1970.doubleValue - time.doubleValue < registDeviceTokenIntervalDays{
                    return
                }
            }
            
        }
        let req = RegistUserDeviceRequest()
        req.setDeviceType(RegistUserDeviceRequest.DEVICE_TYPE_IOS)
        req.setDeviceToken(deviceToken)
        #if DEBUG
            print("Registing Device Token:\(deviceToken!)")
        #endif
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                #if DEBUG
                    print("Registed Device Token")
                #endif
                UserSetting.setUserNumberValue(key, value: Date().totalDaysSince1970)
            }else{
                #if DEBUG
                    print("Regist Device Token Failure")
                #endif
            }
        }
    }
    
    func removeUserDeviceTokenFromServer(_ deviceToken:String!){
        let req = RemoveUserDeviceRequest()
        req.setDeviceToken(deviceToken)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
        }
    }
}

//MARK: Search User
extension UserService{
    func searchUser(_ keyword:String,callback:(_ keyword:String,[VessageUser])->Void){
        if keyword == UserSetting.lastLoginAccountId{
            return
        }
        let users = PersistentManager.sharedInstance.getAllModel(VessageUser.self).filter { (user) -> Bool in
            if self.myProfile.userId == user.userId{
                return false
            }
            if let mobile = user.mobile{
                if mobile.hasBegin(keyword){
                    return true
                }
            }
            if let aId = user.accountId{
                if aId == keyword{
                    return true
                }
            }
            if let nickName = user.nickName{
                if nickName.contains(keyword){
                    return true
                }
            }
            if let noteName = userNotedNames[user.userId]{
                return noteName.contains(keyword)
            }
            return false
        }
        if users.count > 0{
            callback(keyword,users)
        }else if keyword.isMobileNumber(){
            if let u = getCachedUserByMobile(keyword){
                callback(keyword,[u])
            }else{
                callback(keyword,[])
            }
        }
    }
}

//MARK: User Profile
extension UserService{
    func changeUserNickName(_ newNickName:String,callback:@escaping (Bool)->Void){
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
    
    
    func setMyAvatar(_ avatar:String,callback:@escaping (Bool)->Void){
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
    
    func changeUserMotto(_ newMotto:String,callback:@escaping (Bool)->Void) {
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
    func setUserSexValue(_ newValue:Int,callback:@escaping (Bool)->Void){
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

//MARK: User Mobile
class ValidateMobileResult:MsgResult{
    var newUserId:String!
}

let defaultTempMobile = "13600000000"

extension UserService{
    
    var isUserMobileValidated:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mobile)
    }
    
    var isTempMobileUser:Bool{
        return isUserMobileValidated && self.myProfile.mobile == defaultTempMobile
    }
    
    func useTempMobile() {
        self.myProfile.mobile = defaultTempMobile
        self.myProfile.saveModel()
        UserSetting.enableSetting("USE_TMP_MOBILE")
    }
    
    func sendValidateMobilSMS(_ mobile:String,callback:@escaping (_ suc:Bool)->Void){
        UserSetting.disableSetting("USE_TMP_MOBILE")
        let req = SendMobileVSMSRequest()
        req.mobile = mobile
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) -> Void in
            if result.isSuccess{
                callback(true)
            }else{
                callback(false)
            }
        }
        
    }
    
    func validateMobile(_ smsAppkey:String!,mobile:String!,zone:String!, code:String!,bindExistsAccount:Bool,callback:@escaping (_ suc:Bool,_ newUserId:String?)->Void){
        UserSetting.disableSetting("USE_TMP_MOBILE")
        let req = ValidateMobileVSMSRequest()
        req.smsAppkey = smsAppkey
        req.mobile = mobile
        req.zoneCode = zone
        req.code = code
        req.bindExistsAccount = bindExistsAccount
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ValidateMobileResult>) -> Void in
            if result.isSuccess{
                
                if let newUserId = result.returnObject?.newUserId{ //this mobile was received the others message,bind the mobile account registed by server
                    #if DEBUG
                        print("---------------------------------------------")
                        print("Bind Account:\(self.myProfile.accountId!)")
                        print("Origin UserId:\(self.myProfile.userId!)")
                        print("Replace UserId:\(newUserId)")
                        print("---------------------------------------------")
                    #endif
                    
                    callback(true, newUserId)
                }else{
                    self.myProfile.mobile = mobile
                    self.myProfile.saveModel()
                    PersistentManager.sharedInstance.saveAll()
                    callback(true, nil)
                }
            }else{
                callback(false,nil)
            }
        }
    }
}

//MARK: Deprecated

/*
extension UserService{
    private func registNewUserByMobile(mobile:String,noteName:String,updatedCallback:(user:VessageUser?)->Void) {
        let req = RegistMobileUserRequest()
        req.mobile = mobile
        //req.inviteMessage = "INVITE_MOBILE_FRIEND_MSG".localizedString()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<VessageUser>) -> Void in
            if result.isFailure{
                updatedCallback(user: nil)
            }else if let user = result.returnObject{
                #if DEBUG
                    print("AccountId=\(user.accountId!),UserId=\(user.userId!)")
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
}

//MARK: User Chat Images

extension UserService{
    
    private func initChatImages() {
        if let images = PersistentManager.sharedInstance.getModel(UserChatImages.self, idValue: self.myProfile.userId)?.chatImages{
            self.myChatImages = images
        }
        self.fetchUserChatImages(self.myProfile.userId)
    }
 
    var hasChatImages:Bool{
        return self.myChatImages.count > 0 || self.isUserChatBackgroundIsSeted
    }
    
    func getMyChatImages(withVideoChatImage:Bool = true) -> [ChatImage] {
        if !withVideoChatImage {
            return self.myChatImages
        }
        var chatImgs = [ChatImage]()
        chatImgs.appendContentsOf(self.myChatImages)
        if isUserChatBackgroundIsSeted {
            let ci = ChatImage()
            ci.imageId = myProfile.mainChatImage
            ci.imageType = "V_CHAT_IMG".localizedString()
            chatImgs.append(ci)
        }
        return chatImgs;
    }
    
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
*/
