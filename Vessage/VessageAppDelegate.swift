//
//  AppDelegate.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

@UIApplicationMain
class VessageAppDelegate: UIResponder, UIApplicationDelegate,WXApiDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        configureVessageConfig()
        configContryAndLang()
        configureBahamutRFKit()
        configureBahamutCmd()
        configureAliOSSManager()
        configureSmsSDK()
        configureUMessage(launchOptions)
        configureUmeng()
        configureWX()
        initService()
        return true
    }
    
    private func initService()
    {
        ServiceContainer.instance.initContainer(VessageConfig.appName, services: ServicesConfig)
    }
    
    private func configureSmsSDK()
    {
        SMSSDK.registerApp(VessageConfig.bahamutConfig.smsSDKAppkey, withSecret: VessageConfig.bahamutConfig.smsSDKSecretKey)
        SMSSDK.enableAppContactFriends(false)
    }
    
    private func configureBahamutCmd()
    {
        BahamutCmd.signBahamutCmdSchema("vessage")
    }
    
    private func configureAliOSSManager()
    {
        AliOSSManager.sharedInstance.initManager(VessageConfig.bahamutConfig.AliOssAccessKey, aliOssSecretKey: VessageConfig.bahamutConfig.AliOssSecretKey)
    }
    
    private func configContryAndLang()
    {
        let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode)
        VessageSetting.contry = countryCode!.description
        if(countryCode!.description == "CN")
        {
            VessageSetting.lang = "ch"
        }else{
            VessageSetting.lang = "en"
        }
    }
    
    private func configureBahamutRFKit()
    {
        BahamutRFKit.appkey = VessageConfig.appKey
        BahamutRFKit.setAppVersion(VessageConfig.appVersion)
    }
    
    private func configureVessageConfig()
    {
        loadBahamutConfig("BahamutConfig")
    }
    
    private func loadBahamutConfig(configName:String)
    {
        if let bahamutConfigPath = NSBundle.mainBundle().pathForResource(configName, ofType: "json")
        {
            if let json = PersistentFileHelper.readTextFile(bahamutConfigPath)
            {
                let config = BahamutConfigObject(json: json)
                VessageConfig.bahamutConfig = config
            }else
            {
                fatalError("Load Config File Error!")
            }
        }else
        {
            fatalError("No Config File!")
        }
    }
    
    //MARK: Weixin
    private func configureWX() {
        WXApi.registerApp(VessageConfig.bahamutConfig.wechatAppkey)
    }
    
    func onReq(req: BaseReq!) {
        
    }
    
    func onResp(resp: BaseResp!) {
        
    }
    
    //MARK: Umeng
    private func configureUmeng()
    {
        #if RELEASE
            UMAnalyticsConfig.sharedInstance().appKey = VessageConfig.bahamutConfig.umengAppkey
            MobClick.setAppVersion(VessageConfig.appVersion)
            MobClick.setEncryptEnabled(true)
            MobClick.setLogEnabled(false)
        #endif
    }
    
    //MARK: APNS and UMessage
    
    private func configureUMessage(launchOptions: [NSObject: AnyObject]?)
    {
        if let options = launchOptions{
            UMessage.startWithAppkey(VessageConfig.bahamutConfig.umengAppkey, launchOptions: options)
        }else{
            UMessage.startWithAppkey(VessageConfig.bahamutConfig.umengAppkey, launchOptions: [NSObject: AnyObject]())
        }
        UMessage.registerForRemoteNotifications()
        UMessage.setAutoAlert(false)
    }
    
    //MARK: App Delegate
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return WXApi.handleOpenURL(url, delegate: self)
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return WXApi.handleOpenURL(url, delegate: self)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        VessageSetting.deviceToken = deviceToken.description
            .stringByReplacingOccurrencesOfString("<", withString: "")
            .stringByReplacingOccurrencesOfString(">", withString: "")
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        
        if ServiceContainer.isAllServiceReady{
            ServiceContainer.getUserService().registUserDeviceToken(VessageSetting.deviceToken)
        }
        
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        if UIApplication.sharedApplication().applicationState == UIApplicationState.Active{
            if ServiceContainer.isAllServiceReady{
                if let customCmd = userInfo["custom"] as? String{
                    switch customCmd {
                    case "NewVessageNotify":ServiceContainer.getVessageService().newVessageFromServer()
                    case "ActivityUpdatedNotify":ServiceContainer.getActivityService().getActivitiesBoardData()
                    default:NSLog("Unknow Custom Notification:%@", customCmd)
                    }
                }
            }
        }else{
            UMessage.didReceiveRemoteNotification(userInfo)
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("%@", error.description)
    }


    //MARK: life circle
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        PersistentManager.sharedInstance.saveAll()
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if ServiceContainer.isAllServiceReady{
            ServiceContainer.getVessageService().newVessageFromServer()
            ServiceContainer.getActivityService().getActivitiesBoardData()
            ServiceContainer.getUserService().getActiveUsers(true)
            ServiceContainer.getUserService().registUserDeviceToken(VessageSetting.deviceToken,checkTime: true)
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        PersistentManager.sharedInstance.saveAll()
    }

}

