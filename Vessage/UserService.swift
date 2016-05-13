//
//  UserService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

extension VessageUser{
    static func isTheSameUser(usera:VessageUser?,userb:VessageUser?) ->Bool{
        if let a = usera{
            if let b = userb{
                if !String.isNullOrWhiteSpace(a.userId) && !String.isNullOrWhiteSpace(b.userId) && a.userId == b.userId{
                    return true
                }
                if !String.isNullOrWhiteSpace(a.mobile) && !String.isNullOrWhiteSpace(b.mobile){
                    if a.mobile == b.mobile || a.mobile.md5 == b.mobile || a.mobile == b.mobile.md5{
                        return true
                    }
                }
            }
        }
        return false
    }
}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getUserService() -> UserService{
        return ServiceContainer.getService(UserService)
    }
}

let UserProfileUpdatedUserValue = "UserProfileUpdatedUserIdValue"

//MARK:UserService
class UserService:NSNotificationCenter, ServiceProtocol {
    static let userProfileUpdated = "userProfileUpdated"
    @objc static var ServiceName:String {return "User Service"}
    
    private var forceGetUserProfileOnce:Bool = false
    private let notUpdateUserInMinutes:Int = 20
    private var userNotedNames = [String:String]()
    private(set) var myProfile:VessageUser!
    private(set) var activeUsers = [VessageUser]()
    
    var isUserMobileValidated:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mobile)
    }
    
    var isUserChatBackgroundIsSeted:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mainChatImage)
    }
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        initServiceData(userId)
    }
    
    @objc func userLogout(userId: String) {
        setServiceNotReady()
        removeUserDeviceTokenFromServer()
        myProfile = nil
    }
    
    func setForeceGetUserProfileIgnoreTimeLimit(){
        forceGetUserProfileOnce = true
    }
    
    private func initServiceData(userId: String){
        myProfile = initMyProfile({ (user) -> Void in
            if user != nil{
                if self.myProfile == nil{
                    self.myProfile = user
                    self.registUserDeviceToken(VessageSetting.deviceToken)
                    self.getActiveUsers()
                    self.setServiceReady()
                }else{
                    self.myProfile = user
                }
            }else if self.myProfile == nil{
                ServiceContainer.instance.postInitServiceFailed("INIT_USER_DATA_ERROR")
            }
        })
        if myProfile != nil{
            self.registUserDeviceToken(VessageSetting.deviceToken)
            self.getActiveUsers()
            self.setServiceReady()
        }
        if let notedNames = UserSetting.getUserValue("UserNotedNames") as? [String:String]{
            self.userNotedNames = notedNames
        }
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
    
    func getUserProfileByMobile(mobile:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        let result:VessageUser? = PersistentManager.sharedInstance.getAllModelFromCache(VessageUser).filter{ !String.isNullOrWhiteSpace($0.mobile) && mobile == $0.mobile}.first
        let req = GetUserInfoByMobileRequest()
        req.mobile = mobile
        getUserProfileByReq(result?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return result
        
        
    }
    
    func getUserProfileByAccountId(accountId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ !String.isNullOrWhiteSpace($0.accountId) && accountId == $0.accountId}.first
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
    
    func getUserProfile(userId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = getCachedUserProfile(userId)
        let req = GetUserInfoRequest()
        req.userId = userId
        getUserProfileByReq(user?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    private func getUserProfileByReq(lastUpdatedTime:NSDate?,req:BahamutRFRequestBase,updatedCallback:(user:VessageUser?)->Void){
        if forceGetUserProfileOnce == false{
            if let lt = lastUpdatedTime{
                if NSDate().totalMinutesSince1970 - lt.totalMinutesSince1970 < notUpdateUserInMinutes{
                    return
                }
            }
        }
        forceGetUserProfileOnce = false
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<VessageUser>) -> Void in
            if result.isFailure{
                updatedCallback(user: nil)
            }
            if let user = result.returnObject{
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
    
    func getUserNotedName(userId:String) -> String {
        return userNotedNames[userId] ?? getCachedUserProfile(userId)?.nickName ?? "UNLOADED_USER".localizedString()
    }
    
    func setUserNoteName(userId:String,noteName:String){
        userNotedNames[userId] = noteName
        UserSetting.setUserValue("UserNotedNames", value: userNotedNames)
    }
    
    func getActiveUsers(checkTime:Bool = false){
        if checkTime{
            let time = UserSetting.getUserIntValue("GET_ACTIVE_USERS_TIME")
            if NSDate().totalHoursSince1970 - time < 6{
                return
            }
        }
        let req = GetActiveUsersInfoRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[VessageUser]>) in
            if let activeUsers = result.returnObject{
                UserSetting.setUserIntValue("GET_ACTIVE_USERS_TIME", value: NSDate().totalHoursSince1970)
                activeUsers.saveBahamutObjectModels()
                self.activeUsers = activeUsers
            }
        }
    }
}

//MARK: User Device Token
extension UserService{
    func registUserDeviceToken(deviceToken:String!, checkTime:Bool = false){
        if String.isNullOrEmpty(deviceToken){
            return
        }
        if checkTime {
            let time = UserSetting.getUserIntValue("USER_REGIST_DEVICE_TOKEN_TIME")
            if time >= NSDate().totalDaysSince1970{
                return
            }
        }
        let req = RegistUserDeviceRequest()
        req.setDeviceType(RegistUserDeviceRequest.DEVICE_TYPE_IOS)
        req.setDeviceToken(deviceToken)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                UserSetting.setUserIntValue("USER_REGIST_DEVICE_TOKEN_TIME", value: NSDate().totalDaysSince1970)
            }
        }
    }
    
    func removeUserDeviceTokenFromServer(){
        let req = RemoveUserDeviceRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                
            }
        }
    }
}

//MARK: Search User
extension UserService{
    func searchUser(keyword:String,callback:([VessageUser])->Void){
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
            return false
        }
        if users.count > 0{
            callback(users)
        }else if keyword.isMobileNumber(){
            getUserProfileByMobile(keyword, updatedCallback: { (user) -> Void in
                if let u = user{
                    callback([u])
                }else{
                    callback([])
                }
            })
        }else if keyword.isBahamutAccount(){
            getUserProfileByAccountId(keyword, updatedCallback: { (user) -> Void in
                if let u = user{
                    callback([u])
                }else{
                    callback([])
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
    
    func setChatBackground(imageId:String,callback:(Bool)->Void){
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
    
    func setMyAvatar(avatar:String,callback:(Bool)->Void){
        let req = ChangeAvatarRequest()
        req.avatar = avatar
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
            callback(result.isSuccess)
        }
    }
}

//MARK: User Mobile
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
    
    func validateMobile(mobile:String!,zone:String!, code:String!,callback:(suc:Bool)->Void){
        
        let req = ValidateMobileVSMSRequest()
        req.mobile = mobile
        req.zoneCode = zone
        req.code = code
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) -> Void in
            if result.isSuccess{
                self.myProfile.mobile = mobile
                self.myProfile.saveModel()
                NSNotificationCenter.defaultCenter().postNotificationName("OnValidateMobileCodeResult", object: nil, userInfo: nil)
                callback(suc: true)
            }else{
                let error = NSError(domain: "", code: result.statusCode ?? 999, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("OnValidateMobileCodeResult", object: error, userInfo: nil)
                callback(suc: false)
            }
        }
    }
}