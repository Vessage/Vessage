//
//  UnknowVessageHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class UnknowVessageHandler: VessageHandlerBase {
    private var tipsLabel:UILabel
    override init(manager: PlayVessageManager, container: UIView) {
        self.tipsLabel = UILabel()
        tipsLabel.text = "UNKNOW_VESSAGE_TYPE".localizedString()
        tipsLabel.numberOfLines = 0
        tipsLabel.textAlignment = .Center
        tipsLabel.lineBreakMode = .ByWordWrapping
        tipsLabel.textColor = UIColor.lightTextColor()
        super.init(manager: manager, container: container)
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage!) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        container.layoutIfNeeded()
        container.removeAllSubviews()
        container.addSubview(tipsLabel)
        tipsLabel.frame = container.bounds
        refreshConversationLabel()
    }
    
    private func refreshConversationLabel(){
        let friendTimeString = presentingVesseage.sendTime?.dateTimeOfAccurateString.toFriendlyString() ?? "UNKNOW_TIME".localizedString()
        playVessageManager.rightBottomLabelText = friendTimeString
        playVessageManager.leftTopLabelText = nil
    }
}

class NoVessageHandler: VessageHandlerBase {
    private var tipsLabel:UILabel
    override init(manager: PlayVessageManager, container: UIView) {
        self.tipsLabel = UILabel()
        tipsLabel.text = "NO_VESSAGE_TIPS".localizedString()
        tipsLabel.numberOfLines = 0
        tipsLabel.textAlignment = .Center
        tipsLabel.lineBreakMode = .ByWordWrapping
        tipsLabel.textColor = UIColor.lightGrayColor()
        super.init(manager: manager, container: container)
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage!) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        container.layoutIfNeeded()
        container.backgroundColor = UIColor.clearColor()
        container.removeAllSubviews()
        container.addSubview(tipsLabel)
        tipsLabel.frame = container.bounds
        refreshConversationLabel()
    }
    
    private func refreshConversationLabel(){
        playVessageManager.rightBottomLabelText = nil
        playVessageManager.leftTopLabelText = nil
    }
}
