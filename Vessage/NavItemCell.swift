//
//  NavItemCell.swift
//  Vessage
//
//  Created by Alex Chow on 2017/3/19.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

protocol NavItemCellDelegate{
    func navItemCellOnClickContactItem(_ sender:NavItemCell)
    func navItemCellOnClickGroupItem(_ sender:NavItemCell)
    func navItemCellOnClickSubscriptionItem(_ sender:NavItemCell)
}

class NavItemCell: ConversationListCellBase {
    static let reuseId = "NavItemCell"
    var delegate:NavItemCellDelegate?
    
    fileprivate var groupDelegate = ConversationListGroupChatCellDelegate()
    fileprivate var contactDelegate = ConversationListContactCellDelegate()
    
    
    @IBOutlet weak var contactItem: UIView!{
        didSet{
            contactItem.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NavItemCell.onClickItem(_:))))
        }
    }
    
    @IBOutlet weak var groupItem: UIView!{
        didSet{
            groupItem.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NavItemCell.onClickItem(_:))))
        }
    }
    
    @IBOutlet weak var subscriptionItem: UIView!{
        didSet{
            subscriptionItem.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NavItemCell.onClickItem(_:))))
        }
    }
    
    func onClickItem(_ a:UITapGestureRecognizer) {
        if a.view == contactItem {
            contactDelegate.conversationTitleCell(self, controller: rootController)
            delegate?.navItemCellOnClickContactItem(self)
        }else if a.view == groupItem{
            groupDelegate.conversationTitleCell(self, controller: rootController)
            delegate?.navItemCellOnClickGroupItem(self)
        }else if a.view == subscriptionItem{
            SubscriptionListController.showSubscriptioList(self.rootController.navigationController!)
            delegate?.navItemCellOnClickSubscriptionItem(self)
        }
    }
    
}
