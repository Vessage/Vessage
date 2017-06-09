//
//  AppDelegate.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import Alamofire
import EVReflection

@UIApplicationMain
class VessageAppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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
    
    fileprivate func configureSmsSDK()
    {
        SMSSDK.registerApp(VessageConfig.bahamutConfig.smsSDKAppkey, withSecret: VessageConfig.bahamutConfig.smsSDKSecretKey)
        SMSSDK.enableAppContactFriends(false)
    }
    
    fileprivate func configureBahamutCmd()
    {
        BahamutCmd.signBahamutCmdSchema("vessage")
    }
    
    fileprivate func configureAliOSSManager()
    {
        AliOSSManager.sharedInstance.initManager(VessageConfig.bahamutConfig.aliOssAccessKey, aliOssSecretKey: VessageConfig.bahamutConfig.aliOssSecretKey)
        AliOSSManager.sharedInstance.openSSL = true
    }
    
    fileprivate func configContryAndLang()
    {
        let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode)
        VessageSetting.contry = (countryCode! as AnyObject).description
        if((countryCode! as AnyObject).description == "CN")
        {
            VessageSetting.lang = "ch"
        }else{
            VessageSetting.lang = "en"
        }
    }
    
    fileprivate func configureBahamutRFKit()
    {
        BahamutRFKit.appkey = VessageConfig.appKey
        BahamutRFKit.appVersion = VessageConfig.appVersion
        BahamutRFKit.appVersionCode = VessageConfig.buildVersion
        BahamutRFKit.platform = "ios"
    }
    
    fileprivate func configureVessageConfig()
    {
        let config = BahamutConfigObject.fromDictionary(dict: BahamutConfigJson as NSDictionary, BahamutConfigObject())
        //let config = BahamutConfigObject(dictionary: BahamutConfigJson)
        VessageConfig.bahamutConfig = config
    }
    
    
    //MARK: Umeng
    fileprivate func configureUmeng()
    {
        #if RELEASE
            UMAnalyticsConfig.sharedInstance().appKey = VessageConfig.bahamutConfig.umengAppkey
            MobClick.setAppVersion(VessageConfig.appVersion)
            MobClick.setEncryptEnabled(true)
            MobClick.setLogEnabled(false)
            MobClick.start(withConfigure: UMAnalyticsConfig.sharedInstance())
        #endif
    }
    
    //MARK: APNS and UMessage
    
    fileprivate func configureUMessage(_ launchOptions: [AnyHashable: Any]?)
    {
        if let options = launchOptions{
            UMessage.start(withAppkey: VessageConfig.bahamutConfig.umengAppkey, launchOptions: options,httpsEnable: true)
        }else{
            UMessage.start(withAppkey: VessageConfig.bahamutConfig.umengAppkey, launchOptions: [AnyHashable: Any](),httpsEnable: true)
        }
        UMessage.registerForRemoteNotifications()
        UMessage.setAutoAlert(true)
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [UNAuthorizationOptions.alert,UNAuthorizationOptions.badge,UNAuthorizationOptions.sound,UNAuthorizationOptions.carPlay]) { (granted, err) in
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    //MARK: App Delegate
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        VessageSetting.deviceToken = NSData(data: deviceToken).description
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        if ServiceContainer.isAllServiceReady{
            ServiceContainer.getUserService().registUserDeviceToken(VessageSetting.deviceToken)
        }
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let trigger = response.notification.request.trigger {
            if trigger.isKind(of: UNPushNotificationTrigger.self){
                //应用处于后台时的远程推送接受
                //必须加这句代码
                UMessage.didReceiveRemoteNotification(userInfo)
            }else{
                //应用处于后台时的本地推送接受
                completionHandler()
            }
        }
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let trigger = notification.request.trigger {
            if trigger.isKind(of: UNPushNotificationTrigger.self){
                //应用处于前台时的远程推送接受
                //必须加这句代码
                handleActiveNotificatino(userInfo)
            }else{
                //应用处于前台时的本地推送接受
                completionHandler([.alert,.badge,.sound])
            }
        }
        
    }
    
    fileprivate func handleActiveNotificatino(_ userInfo: [AnyHashable: Any]){
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
        }
    }
    
    
    //handle iOS9- Notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
        switch UIApplication.shared.applicationState {
        case .active:
            handleActiveNotificatino(userInfo)
        default:
            UMessage.didReceiveRemoteNotification(userInfo)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    //MARK: life circle
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        ServiceContainer.getAppService().appResignActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        ServiceContainer.getAppService().appEnterBackground()
        PersistentManager.sharedInstance.saveAll()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        ServiceContainer.getAppService().appWillEnterForeground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ServiceContainer.getAppService().appBecomeActive()
        if ServiceContainer.isAllServiceReady{
            ServiceContainer.getVessageService().newVessageFromServer()
            ServiceContainer.getActivityService().getActivitiesBoardData()
            ServiceContainer.getUserService().getActiveUsers(true)
            ServiceContainer.getUserService().registUserDeviceToken(VessageSetting.deviceToken,checkTime: true)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        PersistentManager.sharedInstance.saveAll()
    }

}

//MARK: Weixin
let OnWXShareResponse = "OnWXShareResponse"
let kWXShareResponseValue = "kWXShareResponseValue"
extension VessageAppDelegate:WXApiDelegate{
    fileprivate func configureWX() {
        WXApi.registerApp(VessageConfig.bahamutConfig.wechatAppkey)
    }
    
    func onReq(_ req: BaseReq!) {
        if req is GetMessageFromWXReq
        {
            #if DEBUG
                // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
                let strTitle = "微信请求App提供内容"
                let strMsg = "微信请求App提供内容，App要调用sendResp:GetMessageFromWXResp返回给微信"
                print(strTitle)
                print(strMsg)
            #endif
        }
        else if let temp = req as? ShowMessageFromWXReq
        {
            
            let msg = temp.message
            
            let strTitle = "微信请求App显示内容"
            let strMsg = String(format: "标题：%@ \n内容：%@", msg!.title, msg!.description)
            
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
    
    func onResp(_ resp: BaseResp!) {
        if let res = resp as? SendMessageToWXResp{
            NotificationCenter.default.post(name: Notification.Name(rawValue: OnWXShareResponse), object: self, userInfo: [kWXShareResponseValue:res])
        }
    }

}
