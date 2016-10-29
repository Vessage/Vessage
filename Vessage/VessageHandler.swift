//
//  VessageHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: VessageHandler
protocol VessageHandler{
    func onPresentingVessageSeted(oldVessage: Vessage?,newVessage:Vessage!)
    func onLeftVessageNumberUpdated(oldNumber:Int,newNumber:Int)
    func releaseHandler()
}

class VessageHandlerBase: NSObject,VessageHandler,HandleSwipeGesture {
    weak private(set) var container:UIView!
    private(set) var playVessageManager:PlayVessageManager!
    private(set) var presentingVesseage:Vessage!
    
    init(manager:PlayVessageManager,container:UIView) {
        super.init()
        self.playVessageManager = manager
        self.container = container
    }
    
    func onLeftVessageNumberUpdated(oldNumber: Int, newNumber: Int) {
        
    }
    
    func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage!) {
        self.container.backgroundColor = UIColor.lightGrayColor()
        self.presentingVesseage = newVessage
    }
    
    func onSwipe(direction: UISwipeGestureRecognizerDirection) -> Bool {
        if direction == .Left {
            playVessageManager?.showNextVessage()
            return true
        }else if direction == .Right{
            playVessageManager?.showPreviousVessage()
            return true
        }else{
            return false
        }
    }
    
    func releaseHandler() {
        self.container = nil
        presentingVesseage = nil
        playVessageManager = nil
    }
}
