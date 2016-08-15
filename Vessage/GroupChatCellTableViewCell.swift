//
//  ConversationListGroupChatCellTableViewCell.swift
//  Vessage
//
//  Created by AlexChow on 16/7/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

let maxGroupChatUserCount = 6

class ConversationListGroupChatCell: ConversationListCellBase,SelectVessageUserViewControllerDelegate {
    static let reuseId = "ConversationListGroupChatCell"
    
    override func onCellClicked() {
        let controller = SelectVessageUserViewController.showSelectVessageUserViewController(self.rootController.navigationController!)
        controller.delegate = self
        controller.allowsMultipleSelection = true
        controller.showNearUsers = false
        controller.showActiveUsers = false
        controller.title = "SELECT_GROUP_CHAT_PEOPLE".localizedString()
    }
    
    func canSelect(sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) -> Bool {
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
    
    func onFinishSelect(sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) {
        let groupName = String(format: "GROUP_CHAT_WITH_X_X_PEOPLE".localizedString(), selectedUsers.first!.nickName,"\(selectedUsers.count + 1)")
        let hud = self.rootController.showAnimationHud()
        ServiceContainer.getChatGroupService().createChatGroup(groupName,userIds: selectedUsers.map{$0.userId}){ chatGroup in
            hud.hide(true)
            if let cg = chatGroup{
                let conversation = ServiceContainer.getConversationService().openConversationByGroup(cg)
                ConversationViewController.showConversationViewController(self.rootController.navigationController!, conversation: conversation)
            }else{
                self.rootController.playToast("CREATE_GROUP_FAILED".localizedString())
            }
        }
    }
}
