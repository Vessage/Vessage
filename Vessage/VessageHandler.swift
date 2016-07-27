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
    func onPresentingVessageSeted(oldVessage: Vessage?,newVessage:Vessage)
    func releaseHandler()
}

class VessageHandlerBase: NSObject,VessageHandler {
    weak private(set) var container:UIView!
    private(set) var playVessageManager:PlayVessageManager!
    private(set) var presentingVesseage:Vessage!
    
    init(manager:PlayVessageManager,container:UIView) {
        super.init()
        self.playVessageManager = manager
        self.container = container
    }
    
    func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage) {
        self.presentingVesseage = newVessage
    }
    
    func releaseHandler() {
        self.container = nil
        presentingVesseage = nil
        playVessageManager = nil
    }
}