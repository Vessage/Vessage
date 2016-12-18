//
//  ExtraServicesConfig.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class ActivityInfo{
    init(){}
    init(activityId:String,_ displayTitle:String,_ namedImageIcon:String,_ storyBoardName:String,_ controllerIdentifier:String,_ isPushController:Bool){
        self.activityId = activityId
        self.cellTitle = displayTitle
        self.cellIconName = namedImageIcon
        self.storyBoardName = storyBoardName
        self.controllerIdentifier = controllerIdentifier
        self.isPushController = isPushController
    }
    
    private(set) var activityId:String!
    private(set) var cellTitle:String!
    private(set) var cellIconName:String!
    private(set) var storyBoardName:String!
    private(set) var controllerIdentifier:String!
    private(set) var isPushController:Bool = false
}

let ActivityInfoList = [
    [
        ActivityInfo(activityId: "1003", "SNS".SNSString, "sns_icon", "SNS", "SNSMainViewController", true),
        ActivityInfo(activityId: "1002", "NFC".niceFaceClubString, "NiceFaceClubIcon", "NiceFaceClub", "NFCMainViewController", true)
    ],
    [
        //ActivityInfo(activityId: "1001", "一起帮帮忙", "littlePaperIcon", "HelpTogether", "HelpTogetherMainController", true),
        //ActivityInfo(activityId: "1000", "小纸条", "littlePaperIcon", "LittlePaperMessage", "LittlePaperMainController", false),
        ActivityInfo(activityId: "1004", "MNS".mnsLocalizedString, "mns_icon", "MNS", "MNSMainNavigationController", false)
    ],
    [
        ActivityInfo(activityId: "1005", "TIM_AC_TITLE".TIMString, "tim_icon", "TextImageMaker", "TIMStartNavViewController", false)
    ]
]
