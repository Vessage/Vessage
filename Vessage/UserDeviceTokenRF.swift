//
//  UserDeviceToken.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
public class RegistUserDeviceRequest : BahamutRFRequestBase {
    
    public static let DEVICE_TYPE_IOS = "iOS"
    
    override init(){
        super.init()
        self.method = .POST
        self.api = "/VessageUsers/UserDevice"
    }
    
    public func setDeviceToken(deviceToken:String){
        self.paramenters["deviceToken"] = deviceToken
    }
    
    public func setDeviceType(deviceType:String){
        self.paramenters["deviceType"] = deviceType
    }
}

public class RemoveUserDeviceRequest : BahamutRFRequestBase {
    
    override init() {
        super.init()
        self.method = .DELETE
        self.api = "/VessageUsers/UserDevice"
    }
}