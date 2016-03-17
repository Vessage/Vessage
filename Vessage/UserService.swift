//
//  UserService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let UserProfileUpdatedUserValue = "UserProfileUpdatedUserIdValue"

//MARK:UserService
class UserService:NSNotificationCenter, ServiceProtocol {
    static let userProfileUpdated = "userProfileUpdated"
    @objc static var ServiceName:String {return "User Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        myProfile = initMyProfile({ (user) -> Void in
            if user != nil{
                if self.myProfile == nil{
                    self.myProfile = user
                    self.setServiceReady()
                }else{
                    self.myProfile = user
                }
            }else if self.myProfile == nil{
                ServiceContainer.instance.postInitServiceFailed("INIT_USER_DATA_ERROR")
            }
        })
        if myProfile != nil{
            self.setServiceReady()
        }
    }
    
    @objc func userLogout(userId: String) {
        myProfile = nil
    }
    
    private var forceGetUserProfileOnce:Bool = false
    private let notUpdateUserInMinutes:Int = 20
    private(set) var myProfile:VessageUser!
    
    var isUserMobileValidated:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mobile ?? "")
    }
    
    func setForeceGetUserProfileIgnoreTimeLimit(){
        forceGetUserProfileOnce = true
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
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ mobile == $0.mobile}.first
        
        let req = GetUserInfoByMobileRequest()
        req.mobile = mobile
        getUserProfileByReq(user?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func getUserProfileByAccountId(accountId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ accountId == $0.accountId}.first
        let req = GetUserInfoByAccountIdRequest()
        req.accountId = accountId
        getUserProfileByReq(user?.lastUpdatedTime, req: req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func getCachedUserProfile(userId:String) -> VessageUser?{
        return PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ userId == $0.userId}.first
    }
    
    func fetchUserProfile(userId:String){
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
            callback(result.isSuccess)
        }
    }
    
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
        }else if keyword.isChinaMobileNo(){
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
    
    func validateMobile(mobile:String, smsKey:String,callback:(suc:Bool)->Void){
        
        let req = ValidateMobileVSMSRequest()
        req.mobile = mobile
        req.vsms = smsKey
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) -> Void in
            if result.isSuccess{
                callback(suc: true)
            }else{
                callback(suc: false)
            }
        }
        
    }
}