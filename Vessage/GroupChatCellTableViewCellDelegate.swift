//
//  ConversationListGroupChatCellTableViewCell.swift
//  Vessage
//
//  Created by AlexChow on 16/7/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

let maxGroupChatUserCount = 6

class ConversationListGroupChatCellDelegate: NSObject,ConversationClickCellDelegate,SelectVessageUserViewControllerDelegate {
    fileprivate var rootController:ConversationListController!
    
    func conversationTitleCell(_ sender: ConversationListCellBase, controller: ConversationListController!) {
        self.rootController = controller
        let svuvc = SelectVessageUserViewController.showSelectVessageUserViewController(controller.navigationController!)
        svuvc.delegate = self
        svuvc.allowsMultipleSelection = true
        svuvc.showNearUsers = false
        svuvc.showActiveUsers = false
        svuvc.title = "SELECT_GROUP_CHAT_PEOPLE".localizedString()
    }
    
    func canSelect(_ sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) -> Bool {
        if selectedUsers.count > maxGroupChatUserCount {
            sender.playToast("GROUP_CHAT_PEOPLE_NUM_LIMIT".localizedString())
            return false
        }else if selectedUsers.count > 1{
            return true
        }else{
            sender.playToast("GROUP_CHAT_AT_LEASE_2_PEOPLE".localizedString())
            return false
        }
    }
    
    func onFinishSelect(_ sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) {
        let groupName = String(format: "GROUP_CHAT_WITH_X_X_PEOPLE".localizedString(), selectedUsers.first!.nickName,"\(selectedUsers.count + 1)")
        let hud = self.rootController.showAnimationHud()
        ServiceContainer.getChatGroupService().createChatGroup(groupName,userIds: selectedUsers.map{$0.userId}){ chatGroup in
            hud.hide(animated: true)
            if let cg = chatGroup{
                let conversation = ServiceContainer.getConversationService().openConversationByGroup(cg)
                ConversationViewController.showConversationViewController(self.rootController.navigationController!, conversation: conversation)
            }else{
                self.rootController.playToast("CREATE_GROUP_FAILED".localizedString())
            }
        }
    }
}
