//
//  ExtraServicesConfig.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class ExtraServiceInfo{
    init(){}
    init(_ displayTitle:String,_ namedImageIcon:String,_ storyBoardName:String,_ controllerIdentifier:String,_ isPushController:Bool){
        self.cellTitle = displayTitle
        self.cellIconName = namedImageIcon
        self.storyBoardName = storyBoardName
        self.controllerIdentifier = controllerIdentifier
        self.isPushController = isPushController
    }
    
    var cellTitle:String!
    var cellIconName:String!
    var storyBoardName:String!
    var controllerIdentifier:String!
    var isPushController:Bool = false
}

let ExtraServiceInfoList = [
    ExtraServiceInfo( "小纸条", "littlePaperIcon", "LittlePaperMessage", "LittlePaperMainController", false),
    //ExtraServiceInfo( "帮个忙", "littlePaperIcon", "LittlePaperMessage", "LittlePaperMainController", false)
]
        