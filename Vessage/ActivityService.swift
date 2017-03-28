//
//  ActivityService.swift
//  Vessage
//
//  Created by AlexChow on 16/5/13.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let UpdatedActivityIdValue = "UpdatedActivityIdValue"
let UpdatedActivityBadgeValue = "UpdatedActivityBadgeValue"
let UpdatedActivityMiniBadgeValue = "UpdatedActivityMiniBadgeValue"
let UpdatedActivitiesBadgeValue = "UpdatedActivitiesBadgeValue"

private let AppVersionActivityBadgeKey = "AppVersionActivityBadgeKey"

class ActivityService: NotificationCenter, ServiceProtocol
{
    static let onEnabledActivitiesBadgeUpdated = "onEnabledActivitiesBadgeUpdated".asNotificationName()
    static let onEnabledActivityBadgeUpdated = "onEnabledActivityBadgeUpdated".asNotificationName()
    
    @objc static var ServiceName:String{return "Activity Service"}
    
    fileprivate var acMiniBadge:[String:Bool]!
    fileprivate var acBadge:[String:Int]!
    fileprivate var registedActivity = [String:ActivityInfo]()
    
    @objc func userLoginInit(_ userId:String)
    {
        acMiniBadge = (UserSetting.getUserValue("ActivityMiniBadge") as? [String:Bool]) ?? [String:Bool]()
        acBadge = (UserSetting.getUserValue("ActivityBadge") as? [String:Int]) ?? [String:Int]()
        userFirstLaunchVersion()
        for acArr in ActivityInfoList {
            for ac in acArr {
                registedActivity[ac.activityId] = ac
            }
        }
        
        for info in VGCoreActivityInfoList {
            registedActivity[info.activityId] = info
        }
        
        setServiceReady()
    }
    
    @objc func userLogout(_ userId: String) {
        setServiceNotReady()
    }
    
    fileprivate func storeMiniBadge(){
        UserSetting.setUserValue("ActivityMiniBadge", value: acMiniBadge)
    }
    
    func storeBadge(){
        UserSetting.setUserValue("ActivityBadge", value: acBadge)
    }
    
    fileprivate func userFirstLaunchVersion() {
        let buildVersion = UserSetting.getUserIntValue(AppVersionActivityBadgeKey)
        let currentVersion = VessageConfig.buildVersion
        
        if buildVersion < currentVersion {
            let setted = SetActivityMiniBadgeAtAppVersion.count + IncActivityBadgeAtAppVersion.count > 0
            for id in SetActivityMiniBadgeAtAppVersion {
                acMiniBadge.updateValue(true, forKey: id)
            }
            if SetActivityMiniBadgeAtAppVersion.count > 0 {
                storeMiniBadge()
            }
            
            for id in IncActivityBadgeAtAppVersion {
                acBadge.updateValue((acBadge[id] ?? 0) + 1, forKey: id)
            }
            if IncActivityBadgeAtAppVersion.count > 0 {
                storeBadge()
            }
            
            UserSetting.setUserIntValue(AppVersionActivityBadgeKey, value: currentVersion)
            if setted {
                let totalBadge = UserSetting.getUserIntValue("ActivityListBadge") + 1
                UserSetting.setUserIntValue("ActivityListBadge", value: totalBadge)
            }
        }
    }
    
    func getEnabledActivities() -> [[ActivityInfo]]{
        return ActivityInfoList
    }
    
    func getActivitiesBoardData() {
        let req = GetActivitiesBoardDataRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[ActivityBoardData]>) in
            if let acs = result.returnObject{
                var storeBadge = false
                var storeMini = false
                
                var totalBadge = 0
                for ac in acs{
                    if self.isActivityEnabled(ac.id){
                        totalBadge += ac.badge
                        if ac.badge > 0{
                            storeBadge = true
                        }
                        let badge = self.getActivityBadge(ac.id) + ac.badge
                        self.setActivityBadge(ac.id, badgeValue: badge,autoStore: false)
                        if ac.miniBadge{
                            storeMini = true
                            totalBadge += 1
                            self.setActivityMiniBadgeShow(ac.id,autoStore: false)
                        }
                    }
                }
                self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivitiesBadgeUpdated, object: self, userInfo: [UpdatedActivitiesBadgeValue:totalBadge])
                if storeBadge{
                    self.storeBadge()
                }
                if storeMini{
                    self.storeMiniBadge()
                }
            }
        }
    }
    
    func isActivityEnabled(_ id:String) -> Bool {
        return true
    }
    
    func clearActivityMiniBadge(_ id:String,autoStore:Bool = true) {
        acMiniBadge.removeValue(forKey: id)
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityMiniBadgeValue:false])
        if autoStore {
            storeMiniBadge()
        }
    }
    
    func clearActivityBadge(_ id:String,autoStore:Bool = true) {
        setActivityBadge(id, badgeValue: 0)
        if autoStore {
            storeBadge()
        }
    }
    
    func clearActivityAllBadge(_ id:String) {
        clearActivityBadge(id)
        clearActivityMiniBadge(id)
    }
    
    func setActivityMiniBadgeShow(_ id:String,autoStore:Bool = true){
        acMiniBadge.updateValue(true, forKey: id)
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityMiniBadgeValue:true])
        if autoStore {
            storeMiniBadge()
        }
    }
    
    func setActivityBadge(_ id:String,badgeValue:Int,autoStore:Bool = true) {
        if badgeValue <= 0 {
            acBadge.removeValue(forKey: id)
        }else{
            acBadge.updateValue(badgeValue, forKey: id)
        }
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityBadgeValue:badgeValue])
        if autoStore {
            storeBadge()
        }
    }
    
    func getActivityName(_ id:String) -> String {
        return registedActivity[id]?.cellTitle ?? "UNKNOW_ACTIVITY".localizedString()
    }
    
    func getActivityBadge(_ id:String) -> Int {
        return acBadge?[id] ?? 0
    }
    
    func isActivityShowMiniBadge(_ id:String) -> Bool {
        return acMiniBadge?[id] ?? false
    }

}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getActivityService() -> ActivityService{
        return ServiceContainer.getService(ActivityService.self)
    }
}
