//
//  ActivityService.swift
//  Vessage
//
//  Created by AlexChow on 16/5/13.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class ActivityService: ServiceProtocol
{
    @objc static var ServiceName:String{return "Activity Service"}
    
    @objc func userLoginInit(userId:String)
    {
        getActivitiesBoardData()
        setServiceReady()
    }
    
    func userLogout(userId: String) {
        setServiceNotReady()
    }
    
    func getActivitiesBoardData() {
        
    }
    
    func getActivityBadge(id:String) -> Int {
        return 0
    }
    
    func isActivityShowMiniBadge(id:String) -> Bool {
        return false
    }

}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getActivityService() -> ActivityService{
        return ServiceContainer.getService(ActivityService)
    }
}