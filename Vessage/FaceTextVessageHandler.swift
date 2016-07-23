//
//  FaceTextVessageHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class FaceTextVessageHandler: VessageHandlerBase {
    
    override init(manager:PlayVessageManager,container:UIView) {
        super.init(manager: manager,container: container)
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        
    }
    
    override func releaseHandler() {
        super.releaseHandler()
    }
}