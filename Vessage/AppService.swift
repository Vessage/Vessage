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
    static let intervalTimeTaskPerMinute = "intervalTimeTaskPerMinute"
    
    static let onAppResignActive = "onAppResignActive"
    static let onAppBecomeActive = "onAppBecomeActive"
    
    static let onAppEnterBackground = "onAppEnterBackground"
    static let onAppWillEnterForeground = "onAppWillEnterForeground"
    
    @objc static var ServiceName:String{return "App Service"}
    private var intervalTaskTimer:NSTimer?
    
    @objc func appStartInit(appName: String) {
    }
    @objc func userLoginInit(userId:String)
    {
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        self.setServiceNotReady()
    }
    
    var appDelegate:VessageAppDelegate?{
        return UIApplication.sharedApplication().delegate as? VessageAppDelegate
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
    
    func appEnterBackground(){
        self.postNotificationName(AppService.onAppEnterBackground, object: self)
    }
    
    func appWillEnterForeground() {
        self.postNotificationName(AppService.onAppWillEnterForeground, object: self)
    }
    
    func appResignActive() {
        intervalTaskTimer?.invalidate()
        intervalTaskTimer = nil
        self.postNotificationName(AppService.onAppResignActive, object: self)
    }
    
    func appBecomeActive() {
        intervalTaskTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(AppService.onIntervalTimerTask(_:)), userInfo: nil, repeats: true)
        self.postNotificationName(AppService.onAppBecomeActive, object: self)
    }
    
    func onIntervalTimerTask(_:AnyObject?) {
        self.postNotificationName(AppService.intervalTimeTaskPerMinute, object: self)
    }
}
