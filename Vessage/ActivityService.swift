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
class ActivityService: NSNotificationCenter, ServiceProtocol
{
    static let onEnabledActivitiesBadgeUpdated = "onEnabledActivitiesBadgeUpdated"
    static let onEnabledActivityBadgeUpdated = "onEnabledActivityBadgeUpdated"
    
    @objc static var ServiceName:String{return "Activity Service"}
    
    @objc func userLoginInit(userId:String)
    {
        setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        setServiceNotReady()
    }
    
    func getEnabledActivities() -> [ActivityInfo]{
        return ActivityInfoList
    }
    
    func getActivitiesBoardData() {
        let req = GetActivitiesBoardDataRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[ActivityBoardData]>) in
            if let acs = result.returnObject{
                var totalBadge = 0
                for ac in acs{
                    if self.isActivityEnabled(ac.id){
                        totalBadge += ac.badge
                        let badge = self.getActivityBadge(ac.id) + ac.badge
                        self.setActivityBadge(ac.id, badgeValue: badge)
                        if ac.miniBadge{
                            self.setActivityMiniBadgeShow(ac.id)
                        }
                    }
                }
                self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivitiesBadgeUpdated, object: self, userInfo: [UpdatedActivitiesBadgeValue:totalBadge])
            }
        }
    }
    
    func isActivityEnabled(id:String) -> Bool {
        return true
    }
    
    func clearActivityMiniBadge(id:String) {
        UserSetting.disableSetting("ActivityMiniBadge\(id)")
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityMiniBadgeValue:false])
    }
    
    func clearActivityBadge(id:String) {
        setActivityBadge(id, badgeValue: 0)
    }
    
    func clearActivityAllBadge(id:String) {
        clearActivityBadge(id)
        clearActivityMiniBadge(id)
    }
    
    func setActivityMiniBadgeShow(id:String){
        UserSetting.enableSetting("ActivityMiniBadge\(id)")
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityMiniBadgeValue:true])
    }
    
    func setActivityBadge(id:String,badgeValue:Int) {
        UserSetting.setUserIntValue("ActivityBadge:\(id)",value: badgeValue)
        self.postNotificationNameWithMainAsync(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityIdValue:id,UpdatedActivityBadgeValue:badgeValue])
    }
    
    func getActivityBadge(id:String) -> Int {
        return UserSetting.getUserIntValue("ActivityBadge:\(id)")
    }
    
    func isActivityShowMiniBadge(id:String) -> Bool {
        return UserSetting.isSettingEnable("ActivityMiniBadge\(id)")
    }

}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getActivityService() -> ActivityService{
        return ServiceContainer.getService(ActivityService)
    }
}
