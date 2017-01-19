//
//  ConversationTitleCell.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/19.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

protocol ConversationTitleCellDelegate{
    func conversationTitleCell(sender:ConversationTitleCell,controller:ConversationListController!)
}

class ConversationTitleCell:ConversationListCellBase{
    
    static let reuseId = "ConversationTitleCell"
    
    deinit {
        delegate = nil
    }
    
    var delegate:ConversationTitleCellDelegate?
    
    @IBOutlet weak var nextMark: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func onCellClicked() {
        delegate?.conversationTitleCell(self, controller: self.rootController)
    }
}
