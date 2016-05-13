//
//  ActivityService.swift
//  Vessage
//
//  Created by AlexChow on 16/5/13.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let UpdatedActivityBadgeInfoValue = "UpdatedActivityBadgeInfoValue"
let UpdatedActivitiesBadgeValue = "UpdatedActivitiesBadgeValue"
class ActivityService: NSNotificationCenter, ServiceProtocol
{
    static let onEnabledActivitiesBadgeUpdated = "onEnabledActivitiesBadgeUpdated"
    static let onEnabledActivityBadgeUpdated = "onEnabledActivityBadgeUpdated"
    
    @objc static var ServiceName:String{return "Activity Service"}
    
    @objc func userLoginInit(userId:String)
    {
        getActivitiesBoardData()
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
                        self.postNotificationName(ActivityService.onEnabledActivityBadgeUpdated, object: self, userInfo: [UpdatedActivityBadgeInfoValue:ac])
                    }
                }
                self.postNotificationName(ActivityService.onEnabledActivitiesBadgeUpdated, object: self, userInfo: [UpdatedActivitiesBadgeValue:totalBadge])
            }
        }
    }
    
    func isActivityEnabled(id:String) -> Bool {
        return true
    }
    
    func getActivityBadge(id:String) -> Int {
        return 10
    }
    
    func isActivityShowMiniBadge(id:String) -> Bool {
        return true
    }

}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getActivityService() -> ActivityService{
        return ServiceContainer.getService(ActivityService)
    }
}