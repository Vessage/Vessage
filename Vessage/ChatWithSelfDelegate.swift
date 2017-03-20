//
//  ChatWithSelfDelegate.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/19.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
class ChatWithSelfDelegate: ConversationClickCellDelegate {
    static let instance:ChatWithSelfDelegate = {
        return ChatWithSelfDelegate()
    }()
    
    func conversationTitleCell(sender: ConversationListCellBase, controller: ConversationListController!) {
        let c = Conversation()
        c.chatterId = ServiceContainer.getUserService().myProfile.userId
        c.conversationId = IdUtil.generateUniqueId()
        c.isGroup = false
        c.lstTs = DateHelper.UnixTimeSpanTotalMilliseconds
        c.pinned = false
        c.type = Conversation.typeSelfChat
        ConversationViewController.showConversationViewController(controller.navigationController!, conversation: c)
    }
}
