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
                //TODO: delete test
                let user = VessageUser()
                user.userId = "testuserid"
                user.mobile = "15800038888"
                user.accountId = "102938"
                self.myProfile = user
                self.setServiceReady()
                let testMark = "tn" + ""
                if testMark == "tn"{
                    return
                }
                
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
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            return true
        }
        
        return !String.isNullOrWhiteSpace(myProfile?.mobile ?? "")
    }
    
    private func initMyProfile(updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        let req = GetUserInfoRequest()
        let user = PersistentManager.sharedInstance.getModel(VessageUser.self, idValue: UserSetting.userId)
        getUserProfileByReq(req, updatedCallback: updatedCallback)
        return user
    }
    
    func getUserProfileByMobile(mobile:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        //TODO: delete test
        
        let testMark = "tn" + ""
        if testMark == "tn"{
            let user = VessageUser()
            user.userId = "testuserid"
            user.mobile = "15800038888"
            return user
        }
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ mobile == $0.mobile}.first
        
        let req = GetUserInfoByMobileRequest()
        req.mobile = mobile
        getUserProfileByReq(req, updatedCallback: updatedCallback)
        return user
    }
    
    func getUserProfileByAccountId(accountId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            let user = VessageUser()
            user.userId = "testuserid"
            user.mobile = "15800038888"
            user.accountId = accountId
            return user
        }
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ accountId == $0.accountId}.first
        
        let req = GetUserInfoByAccountIdRequest()
        req.accountId = accountId
        getUserProfileByReq(req, updatedCallback: updatedCallback)
        return user
    }
    
    func getUserProfile(userId:String,updatedCallback:(user:VessageUser?)->Void) -> VessageUser?{
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            let user = VessageUser()
            user.userId = "testuserid"
            user.mobile = "15800038888"
            user.accountId = "102938"
            return user
        }
        
        let user = PersistentManager.sharedInstance.getAllModel(VessageUser).filter{ userId == $0.userId}.first
        let req = GetUserInfoRequest()
        req.userId = userId
        getUserProfileByReq(req, updatedCallback: updatedCallback)
        return user
    }
    
    private func getUserProfileByReq(req:BahamutRFRequestBase,updatedCallback:(user:VessageUser?)->Void){
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<VessageUser>) -> Void in
            if let user = result.returnObject{
                user.saveModel()
                updatedCallback(user: user)
                self.postNotificationName(UserService.userProfileUpdated, object: self, userInfo: [UserProfileUpdatedUserValue:user])
            }else{
                updatedCallback(user: nil)
            }
        }
    }
    
    func searchUser(keyword:String,callback:(VessageUser?)->Void) -> VessageUser?{
        return nil
    }
    
    func sendValidateMobilSMS(mobile:String,callback:(suc:Bool)->Void){
        
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            callback(suc: true)
        }
        
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
        
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            callback(suc: true)
        }
        
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