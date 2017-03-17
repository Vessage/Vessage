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
    init(activityId:String,_ displayTitle:String,_ namedImageIcon:String,_ storyBoardName:String,_ controllerIdentifier:String,_ isPushController:Bool,_ autoClearBadge:Bool){
        self.activityId = activityId
        self.cellTitle = displayTitle
        self.cellIconName = namedImageIcon
        self.storyBoardName = storyBoardName
        self.controllerIdentifier = controllerIdentifier
        self.isPushController = isPushController
        self.autoClearBadge = autoClearBadge
    }
    
    private(set) var activityId:String!
    private(set) var cellTitle:String!
    private(set) var cellIconName:String!
    private(set) var storyBoardName:String!
    private(set) var controllerIdentifier:String!
    private(set) var isPushController:Bool = false
    private(set) var autoClearBadge = false
}

let SetActivityMiniBadgeAtAppVersion:[String] = []
let IncActivityBadgeAtAppVersion:[String] = []

let VGActivityNearActivityId = "100"
let VGActivityGroupChatActivityId = "101"

let VGCoreActivityInfoList = [
    ActivityInfo(activityId: VGActivityNearActivityId, "NEAR_ACTIVE_USER_AC_TITLE".localizedString(), "", "", "", false,false),
    ActivityInfo(activityId: VGActivityGroupChatActivityId, "GROUP_CHAT_TITLE".localizedString(), "", "", "", false,false),
]

let ActivityInfoList = [
    [
        ActivityInfo(activityId: "1003", "SNS_TITLE".SNSString, "sns_icon", "SNS", "SNSMainViewController", true,false),
    ],
    [
        //ActivityInfo(activityId: VGActivityNearActivityId, "Near Active People", "nfc_icon", "NiceFaceClub", "NFCMainViewController", true,false),
        
        //ActivityInfo(activityId: "1002", "NFC".niceFaceClubString, "nfc_icon", "NiceFaceClub", "NFCMainViewController", true,false),
        //ActivityInfo(activityId: "1001", "一起帮帮忙", "littlePaperIcon", "HelpTogether", "HelpTogetherMainController", true,false),
        //ActivityInfo(activityId: "1000", "小纸条", "littlePaperIcon", "LittlePaperMessage", "LittlePaperMainController", false,false),
        ActivityInfo(activityId: "1004", "MNS".mnsLocalizedString, "mns_icon", "MNS", "MNSMainNavigationController", false,false),
        ActivityInfo(activityId: "1006", "MYQ_AC_TITLE".MYQLocalizedString, "myq_icon", "MYQ", "MYQMainNavigationController", false,false),
        //ActivityInfo(activityId: "1007", "PAP_AC_TITLE".PaperAirplaneString, "pap_icon", "PaperAirplane", "PaperAirplaneStartNavController", false,false)
        
    ],
    [
        ActivityInfo(activityId: "1005", "TIM_AC_TITLE".TIMString, "tim_icon", "TextImageMaker", "TIMStartNavViewController", false,true)
    ]
]
