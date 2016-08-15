//
//  ChatImageManageCell.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class ChatImageManageCell:ConversationListCellBase{
    static let reuseId = "ChatImageManageCell"
    
    override func onCellClicked() {
        ChatImageMgrViewController.showChatImageMgrVeiwController(self.rootController)
    }
}