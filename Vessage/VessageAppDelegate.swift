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
        #if DEBUG
            print("App:\(VessageConfig.appName)")
            print("Version:\(VessageConfig.appVersion)")
            print("Build:\(VessageConfig.buildVersion)")
        #endif
        configureVessageConfig()
        configContryAndLang()
        configureBahamutRFKit()
        configureBahamutCmd()
        configureAliOSSManager()
        configureSmsSDK()
        configureUMessage(launchOptions)
        configureUmeng()
        configureWX()
        return true
    }
    
    private func configureSmsSDK()
    {
        SMSSDK.registerApp(VessageConfig.bahamutConfig.smsSDKAppkey, withSecret: VessageConfig.bahamutConfig.smsSDKSecretKey)
        SMSSDK.enableAppContactFriends(false)
    }
    
    private func configureBahamutCmd()
    {
        BahamutCmd.signBahamutCmdSchema("vessage")
        #if DEBUG
            print("---------------------------------------------------------")
            print("Supported Bahamut Cmd:\n")
            print("showInviteFriendsAlert" + "\n" + BahamutCmd.generateBahamutCmdUrl("showInviteFriendsAlert") + "\n")
            print("showSetupChatImagesController" + "\n" + BahamutCmd.generateBahamutCmdUrl("showSetupChatImagesController") + "\n")
            print("showSetupChatBackgroundController" + "\n" + BahamutCmd.generateBahamutCmdUrl("showSetupChatBackgroundController") + "\n")
            
            print("playNextButtonAnimation" + "\n" + BahamutCmd.generateBahamutCmdUrl("playNextButtonAnimation") + "\n")
            print("playFaceTextButtonAnimation" + "\n" + BahamutCmd.generateBahamutCmdUrl("playFaceTextButtonAnimation") + "\n")
            print("playVideoChatButtonAnimation" + "\n" + BahamutCmd.generateBahamutCmdUrl("playVideoChatButtonAnimation") + "\n")
            
            print("maxVideoPlayer" + "\n" + BahamutCmd.generateBahamutCmdUrl("maxVideoPlayer") + "\n")
            print("minVideoPlayer" + "\n" + BahamutCmd.generateBahamutCmdUrl("minVideoPlayer") + "\n")
            
            print("showUserGuide" + "\n" + BahamutCmd.generateBahamutCmdUrl("showUserGuide") + "\n")
            
            print("---------------------------------------------------------")
        #endif
    }
    
    private func configureAliOSSManager()
    {
        AliOSSManager.sharedInstance.initManager(VessageConfig.bahamutConfig.aliOssAccessKey, aliOssSecretKey: VessageConfig.bahamutConfig.aliOssSecretKey)
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
        BahamutRFKit.setRFKitAppVersion(VessageConfig.appVersion)
    }
    
    private func configureVessageConfig()
    {
        let config = BahamutConfigObject(dictionary: BahamutConfigJson)
        VessageConfig.bahamutConfig = config
    }
    
    
    //MARK: Umeng
    private func configureUmeng()
    {
        #if RELEASE
            UMAnalyticsConfig.sharedInstance().appKey = VessageConfig.bahamutConfig.umengAppkey
            MobClick.setAppVersion(VessageConfig.appVersion)
            MobClick.setEncryptEnabled(true)
            MobClick.setLogEnabled(false)
            MobClick.startWithConfigure(UMAnalyticsConfig.sharedInstance())
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
        UMessage.setAutoAlert(true)
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
            if let customCmd = userInfo["custom"] as? String{
                if ServiceContainer.isAllServiceReady{
                    switch customCmd {
                    case "NewVessageNotify":ServiceContainer.getVessageService().newVessageFromServer()
                    case "ActivityUpdatedNotify":ServiceContainer.getActivityService().getActivitiesBoardData()
                    default:debugLog("Unknow Custom Notification:%@", customCmd)
                    }
                }else{
                    debugLog("Services Not Ready,Received Custom Cmd:%@", customCmd)
                }
                return
            }
        }
        UMessage.didReceiveRemoteNotification(userInfo)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    }
    
    //MARK: life circle
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        ServiceContainer.getAppService().appResignActive()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        PersistentManager.sharedInstance.saveAll()
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if ServiceContainer.isAllServiceReady{
            ServiceContainer.getVessageService().newVessageFromServer()
            ServiceContainer.getActivityService().getActivitiesBoardData()
            ServiceContainer.getUserService().getActiveUsers(true)
            ServiceContainer.getUserService().registUserDeviceToken(VessageSetting.deviceToken,checkTime: true)
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ServiceContainer.getAppService().appBecomeActive()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        PersistentManager.sharedInstance.saveAll()
    }

}

//MARK: Weixin
let OnWXShareResponse = "OnWXShareResponse"
let kWXShareResponseValue = "kWXShareResponseValue"
extension VessageAppDelegate:WXApiDelegate{
    private func configureWX() {
        WXApi.registerApp(VessageConfig.bahamutConfig.wechatAppkey)
    }
    
    func onReq(req: BaseReq!) {
        if req is GetMessageFromWXReq
        {
            // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
            let strTitle = "微信请求App提供内容"
            let strMsg = "微信请求App提供内容，App要调用sendResp:GetMessageFromWXResp返回给微信"
            
            #if DEBUG
                print(strTitle)
                print(strMsg)
            #endif
        }
        else if let temp = req as? ShowMessageFromWXReq
        {
            
            let msg = temp.message
            
            //显示微信传过来的内容
            let obj = msg.mediaObject
            
            let strTitle = "微信请求App显示内容"
            let strMsg = String(format: "标题：%@ \n内容：%@ \n附带信息：%@ \n缩略图:%u bytes\n\n", msg.title, msg.description, obj.extInfo, msg.thumbData.length)
            
            #if DEBUG
                print(strTitle)
                print(strMsg)
            #endif
        }
        else if let _ = req as? LaunchFromWXReq
        {
            //从微信启动App
            let strTitle = "从微信启动"
            let strMsg = "这是从微信启动的消息"
            
            #if DEBUG
                print(strTitle)
                print(strMsg)
            #endif
        }
    }
    
    func onResp(resp: BaseResp!) {
        if let res = resp as? SendMessageToWXResp{
            NSNotificationCenter.defaultCenter().postNotificationName(OnWXShareResponse, object: self, userInfo: [kWXShareResponseValue:res])
        }
    }

}