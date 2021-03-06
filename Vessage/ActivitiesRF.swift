//
//  ActivitiesRF.swift
//  Vessage
//
//  Created by AlexChow on 16/5/13.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ActivityBoardData: BahamutObject {
    var id:String!
    var badge:Int = 0
    var miniBadge = false
}

class GetActivitiesBoardDataRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/Activities/BoardData"
    }
}
