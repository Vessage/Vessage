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
    ActivityInfo(activityId: "1000", "小纸条", "littlePaperIcon", "LittlePaperMessage", "LittlePaperMainController", false),
    //ActivityInfo(activityId: "1001", "一起帮帮忙", "littlePaperIcon", "HelpTogether", "HelpTogetherMainController", true),
    ActivityInfo(activityId: "1002", "高颜值俱乐部", "NiceFaceClubIcon", "NiceFaceClub", "SetupNiceFaceViewController", false),
]