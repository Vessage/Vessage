//
//  VessageService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: VessageService
class VessageService:NSNotificationCenter, ServiceProtocol {
    @objc static var ServiceName:String {return "Vessage Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        
    }
}