//
//  AccountService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class RegistNewUserModel {
    var registUserServer:String!
    var accountId:String!
    var accessToken:String!
    var userName:String!
    var region:String!
}

class AccountService: ServiceProtocol
{
    @objc static var ServiceName:String{return "Account Service"}
    
    @objc func userLoginInit(userId:String)
    {
        BahamutRFKit.sharedInstance.resetUser(userId,token:UserSetting.token)
        BahamutRFKit.sharedInstance.reuseApiServer(userId, token:UserSetting.token,appApiServer:VessageSetting.apiServerUrl)
        BahamutRFKit.sharedInstance.reuseFileApiServer(userId, token:UserSetting.token,fileApiServer:VessageSetting.fileApiServer)
        BahamutRFKit.sharedInstance.startClients()
        
        ChicagoClient.sharedInstance.start()
        ChicagoClient.sharedInstance.connect(VessageSetting.chicagoServerHost, port: VessageSetting.chicagoServerHostPort)
        ChicagoClient.sharedInstance.startHeartBeat()
        ChicagoClient.sharedInstance.useValidationInfo(userId, appkey: BahamutRFKit.appkey, apptoken: UserSetting.token)
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        //MobClick.profileSignOff()
        ChicagoClient.sharedInstance.logout()
        UserSetting.token = nil
        UserSetting.isUserLogined = false
        VessageSetting.fileApiServer = nil
        VessageSetting.apiServerUrl = nil
        VessageSetting.chicagoServerHost = nil
        VessageSetting.chicagoServerHostPort = 0
        UserSetting.userId = nil
        BahamutRFKit.sharedInstance.cancelToken(){
            message in
            
        }
        BahamutRFKit.sharedInstance.closeClients()
    }
    
    private func setLogined(validateResult:ValidateResult)
    {
        UserSetting.token = validateResult.AppToken
        UserSetting.isUserLogined = true
        VessageSetting.apiServerUrl = validateResult.APIServer
        VessageSetting.fileApiServer = validateResult.FileAPIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        VessageSetting.chicagoServerHost = chicagoStrs[0]
        VessageSetting.chicagoServerHostPort = UInt16(chicagoStrs[1])!
        UserSetting.userId = validateResult.UserId
        ServiceContainer.instance.userLogin(validateResult.UserId)
    }
    
    func validateAccessToken(apiTokenServer:String, accountId:String, accessToken: String,callback:(loginSuccess:Bool,message:String)->Void,registCallback:((registApiServer:String!)->Void)! = nil)
    {
        
        UserSetting.lastLoginAccountId = accountId
        BahamutRFKit.sharedInstance.validateAccessToken("\(apiTokenServer)/Tokens", accountId: accountId, accessToken: accessToken) { (isNewUser, error,validateResult) -> Void in
            if isNewUser
            {
                registCallback(registApiServer:validateResult.RegistAPIServer)
            }else if error == nil{
                self.setLogined(validateResult)
                callback(loginSuccess: true, message: "")
                //MobClick.profileSignInWithPUID(validateResult.UserId)
            }else{
                callback(loginSuccess: false, message: "VALIDATE_ACCTOKEN_FAILED".localizedString())
            }
            
        }
    }
    
    func registNewUser(registModel:RegistNewUserModel,newUser:VessageUser,callback:(isSuc:Bool,msg:String,validateResult:ValidateResult!)->Void)
    {
        let req = RegistNewVessageUserRequest()
        req.nickName = newUser.nickName
        req.motto = newUser.motto
        req.accessToken = registModel.accessToken
        req.accountId = registModel.accountId
        req.apiServerUrl = registModel.registUserServer
        req.region = registModel.region
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<ValidateResult>) -> Void in
            if result.isFailure
            {
                callback(isSuc:false,msg: "REGIST_FAILED".localizedString(),validateResult: nil);
            }else if let validateResult = result.returnObject
            {
                if validateResult.isValidateResultDataComplete()
                {
                    BahamutRFKit.sharedInstance.useValidateData(validateResult)
                    self.setLogined(validateResult)
                    callback(isSuc: true, msg: "REGIST_SUC".localizedString(),validateResult:validateResult)
                }else
                {
                    callback(isSuc: false, msg:"DATA_ERROR".localizedString(),validateResult:nil)
                }
            }else
            {
                callback(isSuc:false,msg:"REGIST_FAILED".localizedString(),validateResult:nil);
            }
        }
    }
    
    func changePassword(oldPsw:String,newPsw:String,callback:(isSuc:Bool)->Void)
    {
        BahamutRFKit.sharedInstance.changeAccountPassword(VessageConfig.bahamutConfig.accountLoginApiUrl, appkey: VessageConfig.appKey, appToken: BahamutRFKit.sharedInstance.token, accountId: UserSetting.lastLoginAccountId, userId: UserSetting.userId, originPassword: oldPsw, newPassword: newPsw){ suc,msg in
            callback(isSuc:suc)
        }
    }
}