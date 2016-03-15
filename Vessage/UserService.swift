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

    private(set) var myProfile:VessageUser!
    
    var isUserMobileValidated:Bool{
        return !String.isNullOrWhiteSpace(myProfile?.mobile ?? "")
    }
    
    private func initMyProfile(updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        let req = GetUserInfoRequest()
        let user = PersistentManager.sharedInstance.getModel(VessageUser.self, idValue: UserSetting.userId)
        getUserProfileByReq(req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func getUserProfileByMobile(mobile:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ mobile == $0.mobile}.first
        
        let req = GetUserInfoByMobileRequest()
        req.mobile = mobile
        getUserProfileByReq(req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func getUserProfileByAccountId(accountId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ accountId == $0.accountId}.first
        
        let req = GetUserInfoByAccountIdRequest()
        req.accountId = accountId
        getUserProfileByReq(req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    func getUserProfile(userId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ userId == $0.userId}.first
        let req = GetUserInfoRequest()
        req.userId = userId
        getUserProfileByReq(req){ user in
            updatedCallback(user: user)
        }
        return user
    }
    
    private func getUserProfileByReq(req:BahamutRFRequestBase,updatedCallback:(user:VessageUser?)->Void){
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<VessageUser>) -> Void in
            if result.isFailure{
                updatedCallback(user: nil)
            }
            if let user = result.returnObject{
                user.saveModel()
                PersistentManager.sharedInstance.saveAll()
                updatedCallback(user: user)
                self.postNotificationName(UserService.userProfileUpdated, object: self, userInfo: [UserProfileUpdatedUserValue:user])
            }else{
                updatedCallback(user: nil)
            }
        }
    }
    
    func searchUser(keyword:String,callback:([VessageUser])->Void){
        if keyword == UserSetting.lastLoginAccountId{
            return
        }
        let users = PersistentManager.sharedInstance.getAllModel(VessageUser).filter { (user) -> Bool in
            if keyword == user.mobile || keyword == user.accountId{
                return true
            }else if let nickName = user.nickName{
                return nickName.containsString(keyword)
            }
            return false
        }
        if users.count > 0{
            callback(users)
        }else if keyword.isChinaMobileNo(){
            getUserProfileByMobile(keyword, updatedCallback: { (user) -> Void in
                if let u = user{
                    callback([u])
                }
            })
        }else if keyword.isBahamutAccount(){
            getUserProfileByAccountId(keyword, updatedCallback: { (user) -> Void in
                if let u = user{
                    callback([u])
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