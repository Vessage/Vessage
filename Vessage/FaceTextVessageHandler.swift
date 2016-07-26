//
//  FaceTextVessageHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class FaceTextVessageHandler: VessageHandlerBase {
    private var faceTextView:FaceTextImageView!
    
    override init(manager:PlayVessageManager,container:UIView) {
        super.init(manager: manager,container: container)
        self.faceTextView = FaceTextImageView()
        self.faceTextView.initContainer(container)
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        container.subviews.forEach{$0.removeFromSuperview()}
        container.addSubview(self.faceTextView)
        container.sendSubviewToBack(self.faceTextView)
        self.faceTextView.setTextImage(newVessage.fileId, message: newVessage.body)
    }
    
    override func releaseHandler() {
        super.releaseHandler()
        self.faceTextView = nil
    }
}