//
//  AppRF.swift
//  Vessage
//
//  Created by AlexChow on 16/7/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class AppRequestBase: BahamutRFRequestBase {
    
    var platform:String!{
        didSet{
            self.paramenters["platform"] = platform
        }
    }
    
    var buildVersion:Int!{
        didSet{
            self.paramenters["buildVersion"] = "\(buildVersion)"
        }
    }
}

class AppFirstLaunchRequest: AppRequestBase {
    override init() {
        super.init()
        self.method = .POST
        self.api = "/App/FirstLaunch"
    }
}