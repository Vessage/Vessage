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
    
    var accountApiUrlPrefix:String!
    var accountRegistApiUrl:String!
    var accountLoginApiUrl:String!
    
    var appPrivacyPage:String!
    var bahamutAppEmail:String!
    var bahamutAppOuterExecutorUrlPrefix:String!
    
    var AliOssAccessKey:String!
    var AliOssSecretKey:String!
    
    var AppStoreId:String!
    
    var umengAppkey:String!
    var shareSDKAppkey:String!
    
    var facebookAppkey:String!
    var facebookAppScrect:String!
    
    var wechatAppkey:String!
    var wechatAppScrect:String!
    
    var qqAppkey:String!
    
    var weiboAppkey:String!
    var weiboAppScrect:String!
    
}

class VessageSetting{
    static var lang:String = "en"
    static var contry:String = "US"
    static var deviceToken:String = ""
    
    static var loginApi:String{
        get{
        if let api = NSUserDefaults.standardUserDefaults().valueForKey("loginApi") as? String{
        return api
        }
            return VessageConfig.bahamutConfig.accountLoginApiUrl
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey:"loginApi")
        }
    }
    
    static var registAccountApi:String{
        get{
        if let api = NSUserDefaults.standardUserDefaults().valueForKey("registAccountApi") as? String{
        return api
        }
        return VessageConfig.bahamutConfig.accountRegistApiUrl
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey:"registAccountApi")
        }
    }
    
    static var apiServerUrl:String!{
        get{
        return NSUserDefaults.standardUserDefaults().valueForKey("apiServerUrl") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "apiServerUrl")
        }
    }
    
    static var fileApiServer:String!{
        get{
        return NSUserDefaults.standardUserDefaults().valueForKey("fileApiServer") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "fileApiServer")
        }
    }
    
    static var chicagoServerHost:String!{
        get{
        return NSUserDefaults.standardUserDefaults().valueForKey("chicagoServerHost") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "chicagoServerHost")
        }
    }
    
    static var chicagoServerHostPort:UInt16{
        get{
        let port = NSUserDefaults.standardUserDefaults().integerForKey("chicagoServerHostPort")
        return UInt16(port)
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(Int(newValue), forKey: "chicagoServerHostPort")
        }
    }
}

class VessageConfig{
    static var appName:String { return bahamutConfig.appName }
    static var appKey:String { return bahamutConfig.appkey }
    static var bahamutConfig:BahamutConfigObject!
    static var appVersion:String{
        if let infoDic = NSBundle.mainBundle().infoDictionary
        {
            let version = infoDic["CFBundleShortVersionString"] as! String
            return version
        }
        return "1.0"
    }
}