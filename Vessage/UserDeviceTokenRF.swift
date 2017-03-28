//
//  UserDeviceToken.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
open class RegistUserDeviceRequest : BahamutRFRequestBase {
    
    open static let DEVICE_TYPE_IOS = "iOS"
    
    override init(){
        super.init()
        self.method = .post
        self.api = "/VessageUsers/UserDevice"
    }
    
    open func setDeviceToken(_ deviceToken:String){
        self.paramenters["deviceToken"] = deviceToken
    }
    
    open func setDeviceType(_ deviceType:String){
        self.paramenters["deviceType"] = deviceType
    }
}

open class RemoveUserDeviceRequest : BahamutRFRequestBase {
    
    override init() {
        super.init()
        self.method = .delete
        self.api = "/VessageUsers/UserDevice"
    }
    
    open func setDeviceToken(_ deviceToken:String){
        self.paramenters["deviceToken"] = deviceToken
    }
}
