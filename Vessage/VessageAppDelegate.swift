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
        //SMSSDK.registerApp("f3fc6baa9ac4", withSecret: "7f3dedcb36d92deebcb373af921d635a")
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
            ServiceContainer.getService(VessageService).newVessageFromServer()
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

