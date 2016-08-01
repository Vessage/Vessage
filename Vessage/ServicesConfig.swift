//
//  VessageServices.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
let ServicesConfig:ServiceListDict =
[
    (AccountService.ServiceName,AccountService()),
    (FileService.ServiceName,FileService(mondBundle: NSBundle.mainBundle(),coreDataUpdater: nil)),
    (UserService.ServiceName,UserService()),
    (VessageService.ServiceName,VessageService()),
    (ConversationService.ServiceName,ConversationService()),
    (ActivityService.ServiceName,ActivityService()),
    (LocationService.ServiceName,LocationService()),
    (ChatGroupService.ServiceName,ChatGroupService()),
    (AppService.ServiceName,AppService())
]