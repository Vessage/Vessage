//
//  UserSetting.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/5.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation

class UserSetting
{
    #if DEBUG
        static var godMode = false
    #else
        static var godMode = false
    #endif
    static var isAppstoreReviewing:Bool{
        get{
            return NSUserDefaults.standardUserDefaults().boolForKey("isAppstoreReviewId")
        }
        set{
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "isAppstoreReviewId")
        }
    }
    
    static var lastLoginAccountId:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("lastLoginAccountId") as? String
        }
        set{
            if AppleStoreReviewAccountIds.contains(newValue)
            {
                isAppstoreReviewing = true
            }
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "lastLoginAccountId")
        }
    }
    
    static var isUserLogined:Bool{
        get{
        return NSUserDefaults.standardUserDefaults().boolForKey("isUserLogined")
        }
        set{
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "isUserLogined")
        }
    }
    
    private static var _userId:String!
    static var userId:String!{
        get{
        if _userId == nil{
        _userId = NSUserDefaults.standardUserDefaults().valueForKey("userId") as? String
        }
        return _userId
        }
        set{
            _userId = newValue
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "userId")
        }
    }
    
    static var token:String!{
        get{
        return NSUserDefaults.standardUserDefaults().valueForKey("token") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "token")
        }
    }
    
    static func getSettingKey(setting:String) -> String{
        return "\(UserSetting.lastLoginAccountId):\(setting)"
    }
    
    static func isSettingEnable(setting:String) -> Bool{
        return NSUserDefaults.standardUserDefaults().boolForKey(getSettingKey(setting))
    }
    
    static func setSetting(setting:String,enable:Bool)
    {
        NSUserDefaults.standardUserDefaults().setBool(enable, forKey: getSettingKey(setting))
    }
    
    static func enableSetting(setting:String)
    {
        setSetting(setting, enable: true)
    }
    
    static func disableSetting(setting:String)
    {
        setSetting(setting, enable: false)
    }
    
    static func setUserIntValue(setting:String,value:Int){
        let key = getSettingKey(setting)
        NSUserDefaults.standardUserDefaults().setInteger(value, forKey: key)
    }
    
    static func getUserIntValue(setting:String) -> Int{
        let key = getSettingKey(setting)
        return NSUserDefaults.standardUserDefaults().integerForKey(key)
    }
    
    static func getUserNumberValue(setting:String) -> NSNumber?{
        return getUserValue(setting) as? NSNumber
    }
    
    static func setUserNumberValue(setting:String,value:NSNumber){
        setUserValue(setting, value: value)
    }
    
    static func setUserValue(setting:String,value:AnyObject){
        let key = getSettingKey(setting)
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
    }
    
    static func getUserValue(setting:String) -> AnyObject?{
        let key = getSettingKey(setting)
        return NSUserDefaults.standardUserDefaults().objectForKey(key)
    }
}
