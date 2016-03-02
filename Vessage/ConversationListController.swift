//
//  ConversationListController.swift
//  SeeYou
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ConversationListController: UITableViewController {

    @IBAction func showUserSetting(sender: AnyObject) {
    }
    
    static func showConversationListController(nvc:UINavigationController)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationListController") as! ConversationListController
        nvc.pushViewController(controller, animated: true)
    }
}
