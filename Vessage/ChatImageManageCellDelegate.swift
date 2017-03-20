//
//  ChatImageManageCell.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ChatImageManageCellDelegate:ConversationClickCellDelegate{
    
    static let instance:ChatImageManageCellDelegate = {
       return ChatImageManageCellDelegate()
    }()
    
    func conversationTitleCell(sender: ConversationListCellBase, controller: ConversationListController!) {
        /*
        if let c = controller{
            ChatImageMgrViewController.showChatImageMgrVeiwController(c)
        }
 */
    }
}
