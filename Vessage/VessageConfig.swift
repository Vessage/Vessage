//
//  VessageConfig.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

let AppleStoreReviewAccountIds = ["147275","147276"];

class BahamutConfigObject:EVObject
{
    var appkey:String!
    var appName:String!
    var godModeCode:String!
    
    var accountApiUrlPrefix:String!
    var accountRegistApiUrl:String!
    var accountLoginApiUrl:String!
    
    var appPrivacyPage:String!
    var bahamutAppEmail:String!
    var bahamutAppOuterExecutorUrlPrefix:String!
    
    var aliOssAccessKey:String!
    var aliOssSecretKey:String!
    
    var appStoreId:String!
    
    var umengAppkey:String!
    var shareSDKAppkey:String!
    
    var facebookAppkey:String!
    var facebookAppScrect:String!
    
    var wechatAppkey:String!
    var wechatAppScrect:String!
    
    var qqAppkey:String!
    
    var weiboAppkey:String!
    var weiboAppScrect:String!
    
    var smsSDKAppkey:String!
    var smsSDKSecretKey:String!
    
    var faceDetectSubscriptionKey:[String]!
}

class VessageSetting{
    static var lang:String = "en"
    static var contry:String = "US"
    static var deviceToken:String = ""
    
    static var loginApi:String{
        get{
        if let api = UserDefaults.standard.value(forKey: "loginApi") as? String{
        return api
        }
            return VessageConfig.bahamutConfig.accountLoginApiUrl
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey:"loginApi")
        }
    }
    
    static var registAccountApi:String{
        get{
        if let api = UserDefaults.standard.value(forKey: "registAccountApi") as? String{
        return api
        }
        return VessageConfig.bahamutConfig.accountRegistApiUrl
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey:"registAccountApi")
        }
    }
    
    static var apiServerUrl:String!{
        get{
        return UserDefaults.standard.value(forKey: "apiServerUrl") as? String
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "apiServerUrl")
        }
    }
    
    static var fileApiServer:String!{
        get{
        return UserDefaults.standard.value(forKey: "fileApiServer") as? String
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "fileApiServer")
        }
    }
    
    static var chicagoServerHost:String!{
        get{
        return UserDefaults.standard.value(forKey: "chicagoServerHost") as? String
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "chicagoServerHost")
        }
    }
    
    static var chicagoServerHostPort:UInt16{
        get{
        let port = UserDefaults.standard.integer(forKey: "chicagoServerHostPort")
        return UInt16(port)
        }
        set{
            UserDefaults.standard.setValue(Int(newValue), forKey: "chicagoServerHostPort")
        }
    }
}

class VessageConfig{
    static var appName:String { return "APP_NAME".localizedString() }
    static var appKey:String { return bahamutConfig.appkey }
    static var bahamutConfig:BahamutConfigObject!
    static var appVersion:String{
        if let infoDic = Bundle.main.infoDictionary
        {
            let version = infoDic["CFBundleShortVersionString"] as! String
            return version
        }
        return "1.0"
    }
    
    static var buildVersion:Int{
        if let infoDic = Bundle.main.infoDictionary
        {
            let version = infoDic["CFBundleVersion"] as! String
            return Int(version) ?? 1
        }
        return 1
    }
}
