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

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getAccountService() -> AccountService{
        return ServiceContainer.getService(AccountService.self)
    }
}

private func transformHttpUrlToBahamutHttpsUrl(_ url:String) -> String {
    
    return url
    /*
    var host = url
    if host.lowercaseString.hasPrefix("http://") {
        var url = host.stringByReplacingOccurrencesOfString("http://", withString: "https#//", options: .CaseInsensitiveSearch, range: nil)
        url = url.stringByReplacingOccurrencesOfString(":", withString: "/", options: .CaseInsensitiveSearch, range: nil)
        url = url.stringByReplacingOccurrencesOfString("https#//", withString: "https://", options: .CaseInsensitiveSearch, range: nil)
        host = url
    }
    return host
 */
}

//MARK: AccountService
class AccountService: ServiceProtocol
{
    @objc static var ServiceName:String{return "Account Service"}
    @objc func appStartInit(_ appName: String) {
        self.setServiceReady()
    }
    @objc func userLoginInit(_ userId:String)
    {
        #if DEBUG
            print("userId=\(userId)")
            print("userToken="+UserSetting.token)
        #endif
        
        
        
        BahamutRFKit.sharedInstance.resetUser(userId,token:UserSetting.token)
        
        BahamutRFKit.sharedInstance.reuseApiServer(userId, token:UserSetting.token,appApiServer:transformHttpUrlToBahamutHttpsUrl(VessageSetting.apiServerUrl))
        BahamutRFKit.sharedInstance.reuseFileApiServer(userId, token:UserSetting.token,fileApiServer:transformHttpUrlToBahamutHttpsUrl(VessageSetting.fileApiServer))
        
        BahamutRFKit.sharedInstance.startClients()
        self.setServiceReady()
    }
    
    @objc func userLogout(_ userId: String) {
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
    
    func reBindUserId(_ newUserId:String) {
        let cachedValidateResult = ValidateResult()
        cachedValidateResult.apiServer = VessageSetting.apiServerUrl
        cachedValidateResult.appToken = UserSetting.token
        cachedValidateResult.fileAPIServer = VessageSetting.fileApiServer
        cachedValidateResult.chicagoServer = "\(VessageSetting.chicagoServerHost ?? ""):\(VessageSetting.chicagoServerHostPort)"
        cachedValidateResult.userId = newUserId
        ServiceContainer.instance.userLogout()
        reuseValidateResult(cachedValidateResult)
    }
    
    fileprivate func reuseValidateResult(_ validateResult:ValidateResult) {
        UserSetting.token = validateResult.appToken
        UserSetting.isUserLogined = true
        VessageSetting.apiServerUrl = validateResult.apiServer
        VessageSetting.fileApiServer = validateResult.fileAPIServer
        let chicagoStrs = validateResult.chicagoServer.split(":")
        VessageSetting.chicagoServerHost = chicagoStrs[0]
        VessageSetting.chicagoServerHostPort = UInt16(chicagoStrs[1])!
        UserSetting.userId = validateResult.userId
    }
    
    fileprivate func setLogined(_ validateResult:ValidateResult)
    {
        reuseValidateResult(validateResult)
        ServiceContainer.instance.userLogin(validateResult.userId)
    }
    
    func validateAccessToken(_ apiTokenServer:String, accountId:String, accessToken: String,callback:@escaping (_ loginSuccess:Bool,_ message:String)->Void,registCallback:((_ registValidateResult:ValidateResult?)->Void)! = nil)
    {
        
        UserSetting.lastLoginAccountId = accountId
        BahamutRFKit.sharedInstance.validateAccessToken("\(apiTokenServer)/Tokens", accountId: accountId, accessToken: accessToken) { (isNewUser, error,validateResult) -> Void in
            if isNewUser
            {
                registCallback(validateResult!)
            }else if error == nil{
                self.setLogined(validateResult!)
                callback(true, "")
            }else{
                callback(false, "VALIDATE_ACCTOKEN_FAILED".localizedString())
            }
            
        }
    }
    
    func registNewUser(_ registModel:RegistNewUserModel,newUser:VessageUser,callback:@escaping (_ isSuc:Bool,_ msg:String,_ validateResult:ValidateResult?)->Void)
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
            if result.isSuccess
            {
                if let validateResult = result.returnObject
                {
                    if validateResult.isValidateResultDataComplete()
                    {
                        BahamutRFKit.sharedInstance.useValidateData(validateResult)
                        self.setLogined(validateResult)
                        callback(true, "REGIST_SUC".localizedString(),validateResult)
                    }else
                    {
                        callback(false, "DATA_ERROR".localizedString(),nil)
                    }
                }else
                {
                    callback(false,"REGIST_FAILED".localizedString(),nil);
                }
            }else
            {
                callback(false,"REGIST_FAILED".localizedString(),nil);
            }
        }
    }
    
    func changePassword(_ oldPsw:String,newPsw:String,callback:@escaping (_ isSuc:Bool, _ msg:String?)->Void)
    {
        BahamutRFKit.sharedInstance.changeAccountPassword(VessageConfig.bahamutConfig.accountApiUrlPrefix, appkey: VessageConfig.appKey, appToken: BahamutRFKit.sharedInstance.token, accountId: UserSetting.lastLoginAccountId, userId: UserSetting.userId, originPassword: oldPsw, newPassword: newPsw){ suc,msg in
            callback(suc,msg)
        }
    }
}
