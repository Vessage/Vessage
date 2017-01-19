//
//  ChatImageManageCell.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class ChatImageManageCellDelegate:ConversationTitleCellDelegate{
    
    static let instance:ChatImageManageCellDelegate = {
       return ChatImageManageCellDelegate()
    }()
    
    func conversationTitleCell(sender: ConversationTitleCell, controller: ConversationListController!) {
        if let c = controller{
            ChatImageMgrViewController.showChatImageMgrVeiwController(c)
        }
    }
}
