//
//  VessageEventHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/30.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
protocol VessageEventHandler{
    func onEvent(eventId:String,parameters:[String:AnyObject])
    func releaseHandler()
}

protocol HandlePanGesture {
    func onPan(v:CGPoint) -> Bool
}

protocol HandleSwipeGesture {
    func onSwipe(direction:UISwipeGestureRecognizerDirection) -> Bool
}
