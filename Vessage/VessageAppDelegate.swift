//
//  AppDelegate.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

@UIApplicationMain
class VessageAppDelegate: UIResponder, UIApplicationDelegate {

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
    
    //MARK: Umeng
    private func configureUmeng()
    {
        #if RELEASE
            MobClick.setAppVersion(VessageConfig.appVersion)
            MobClick.setEncryptEnabled(true)
            MobClick.setLogEnabled(false)
            MobClick.startWithAppkey(VessageConfig.bahamutConfig.umengAppkey, reportPolicy: BATCH, channelId: nil)
        #endif
    }
    
    //MARK: APNS and UMessage
    
    private func configureUMessage(launchOptions: [NSObject: AnyObject]?)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            UMessage.startWithAppkey(VessageConfig.bahamutConfig.umengAppkey, launchOptions: launchOptions)
            UMessage.setAutoAlert(false)
            //register remoteNotification types
            let action1 = UIMutableUserNotificationAction()
            action1.identifier = "action1_identifier"
            action1.title="Accept";
            action1.activationMode = UIUserNotificationActivationMode.Foreground //当点击的时候启动程序
            
            let action2 = UIMutableUserNotificationAction()  //第二按钮
            action2.identifier = "action2_identifier"
            action2.title="Reject"
            action2.activationMode = UIUserNotificationActivationMode.Background //当点击的时候不启动程序，在后台处理
            action2.authenticationRequired = true //需要解锁才能处理，如果action.activationMode = UIUserNotificationActivationModeForeground;则这个属性被忽略；
            action2.destructive = true;
            
            let categorys = UIMutableUserNotificationCategory()
            categorys.identifier = "category1" //这组动作的唯一标示
            categorys.setActions([action1,action2], forContext: .Default)
            
            let userSettings = UIUserNotificationSettings(forTypes: [.Sound,.Badge,.Alert], categories: [categorys])
            UMessage.registerRemoteNotificationAndUserNotificationSettings(userSettings)
            
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        UMessage.registerDeviceToken(deviceToken)
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

