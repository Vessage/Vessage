//
//  AppService.swift
//  Vessage
//
//  Created by AlexChow on 16/7/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getAppService() -> AppService{
        return ServiceContainer.getService(AppService)
    }
}

let NotifiedFirstLuanchBuildKey = "NotifiedFirstLuanchBuildKey"

//MARK: AppService
class AppService: NSNotificationCenter,ServiceProtocol
{
    @objc static var ServiceName:String{return "App Service"}
    @objc func appStartInit(appName: String) {
    }
    @objc func userLoginInit(userId:String)
    {
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        self.setServiceNotReady()
    }
    
    func trySendFirstLaunchToServer() {
        let buildVersion = UserSetting.getUserIntValue(NotifiedFirstLuanchBuildKey)
        if buildVersion < VessageConfig.buildVersion {
            let req = AppFirstLaunchRequest()
            req.buildVersion = VessageConfig.buildVersion
            req.oldBuildVersion = buildVersion
            req.platform = "ios"
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
                if result.isSuccess{
                    UserSetting.setUserIntValue(NotifiedFirstLuanchBuildKey, value: VessageConfig.buildVersion)
                }
            }
        }
    }
    
    func getOnlineLatestVersion() {
        
    }
}