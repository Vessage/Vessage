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
private let SetActivityMiniBadgeAtAppVersion = ["1005","1006"]
private let IncActivityBadgeAtAppVersion = ["1005","1006"]

class ActivityService: NSNotificationCenter, ServiceProtocol
{
    static let onEnabledActivitiesBadgeUpdated = "onEnabledActivitiesBadgeUpdated"
    static let onEnabledActivityBadgeUpdated = "onEnabledActivityBadgeUpdated"
    
    @objc static var ServiceName:String{return "Activity Service"}
    
    private var acMiniBadge:[String:Bool]!
    private var acBadge:[String:Int]!
    
    @objc func userLoginInit(userId:String)
    {
        acMiniBadge = (UserSetting.getUserValue("ActivityMiniBadge") as? [String:Bool]) ?? [String:Bool]()
        acBadge = (UserSetting.getUserValue("ActivityBadge") as? [String:Int]) ?? [String:Int]()
        userFirstLaunchVersion()
        setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        setServiceNotReady()
    }
    
    private func storeMiniBadge(){
        UserSetting.setUserValue("ActivityMiniBadge", value: acMiniBadge)
    }
    
    func storeBadge(){
        UserSetting.setUserValue("ActivityBadge", value: acBadge)
    }
    
    private func userFirstLaunchVersion() {
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
    
    func isActivityEnabled(id:String) -> Bool {
        return true
    }
    
    func clearActivityMiniBadge(id:String,autoStore:Bool = true) {
        acMiniBadge.removeValueForKey(id)
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityMiniBadgeValue:false])
        if autoStore {
            storeMiniBadge()
        }
    }
    
    func clearActivityBadge(id:String,autoStore:Bool = true) {
        setActivityBadge(id, badgeValue: 0)
        if autoStore {
            storeBadge()
        }
    }
    
    func clearActivityAllBadge(id:String) {
        clearActivityBadge(id)
        clearActivityMiniBadge(id)
    }
    
    func setActivityMiniBadgeShow(id:String,autoStore:Bool = true){
        acMiniBadge.updateValue(true, forKey: id)
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityMiniBadgeValue:true])
        if autoStore {
            storeMiniBadge()
        }
    }
    
    func setActivityBadge(id:String,badgeValue:Int,autoStore:Bool = true) {
        if badgeValue <= 0 {
            acBadge.removeValueForKey(id)
        }else{
            acBadge.updateValue(badgeValue, forKey: id)
        }
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityBadgeValue:badgeValue])
        if autoStore {
            storeBadge()
        }
    }
    
    func getActivityBadge(id:String) -> Int {
        return acBadge?[id] ?? 0
    }
    
    func isActivityShowMiniBadge(id:String) -> Bool {
        return acMiniBadge?[id] ?? false
    }

}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getActivityService() -> ActivityService{
        return ServiceContainer.getService(ActivityService)
    }
}
