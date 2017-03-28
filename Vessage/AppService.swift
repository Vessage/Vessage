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
        return ServiceContainer.getService(AppService.self)
    }
}

let NotifiedFirstLuanchBuildKey = "NotifiedFirstLuanchBuildKey"

//MARK: AppService
class AppService: NotificationCenter,ServiceProtocol
{
    static let intervalTimeTaskPerMinute = "intervalTimeTaskPerMinute".asNotificationName()
    
    static let onAppResignActive = "onAppResignActive".asNotificationName()
    static let onAppBecomeActive = "onAppBecomeActive".asNotificationName()
    
    static let onAppEnterBackground = "onAppEnterBackground".asNotificationName()
    static let onAppWillEnterForeground = "onAppWillEnterForeground".asNotificationName()
    
    @objc static var ServiceName:String{return "App Service"}
    
    var appQABadge:Bool = false
    var inviteBadge:Bool = false
    var settingBadge:Bool = false
    
    fileprivate var intervalTaskTimer:Timer?
    
    @objc func appStartInit(_ appName: String) {
    }
    @objc func userLoginInit(_ userId:String)
    {
        self.setServiceReady()
    }
    
    @objc func userLogout(_ userId: String) {
        self.setServiceNotReady()
    }
    
    var appDelegate:VessageAppDelegate?{
        return UIApplication.shared.delegate as? VessageAppDelegate
    }
    
    
    func trySendFirstLaunchToServer() {
        let buildVersion = UserSetting.getUserIntValue(NotifiedFirstLuanchBuildKey)
        if buildVersion < VessageConfig.buildVersion {
            appQABadge = true
            inviteBadge = true
            settingBadge = true
            
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
        self.post(name: (AppService.onAppEnterBackground), object: self)
    }
    
    func appWillEnterForeground() {
        self.post(name: (AppService.onAppWillEnterForeground), object: self)
    }
    
    func appResignActive() {
        intervalTaskTimer?.invalidate()
        intervalTaskTimer = nil
        self.post(name: (AppService.onAppResignActive), object: self)
    }
    
    func appBecomeActive() {
        intervalTaskTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(AppService.onIntervalTimerTask(_:)), userInfo: nil, repeats: true)
        self.post(name: (AppService.onAppBecomeActive), object: self)
    }
    
    func onIntervalTimerTask(_:AnyObject?) {
        self.post(name: (AppService.intervalTimeTaskPerMinute), object: self)
    }
}
