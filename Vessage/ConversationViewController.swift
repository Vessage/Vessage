//
//  ViewController.swift
//  SeeYou
//
//  Created by AlexChow on 16/2/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ConversationViewModel {
    var id:String!
    var chatterMainImage:String!
    var userId:String!
    var unread:Int = 0
}

//MARK: ConversationViewController
class ConversationViewController: UIViewController {
    
    @IBOutlet weak var vessagebadgeButton: UIButton!{
        didSet{
            vessagebadgeButton.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var avatarButton: UIButton!
    @IBOutlet weak var vessageView: UIView!
    var conversation:ConversationViewModel!
    
    private var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    
    private var conversationNotReadCount:Int = 0{
        didSet{
            vessagebadgeButton.badgeValue = "\(conversationNotReadCount)"
        }
    }
    
    //MARK: actions
    @IBAction func showConversationList(sender: AnyObject) {
        ConversationListController.showConversationListController(self.navigationController!)
    }
    
    @IBAction func showRecordMessage(sender: AnyObject) {
        RecordMessageController.showRecordMessageController(self,conversation: conversation)
    }
    
    @IBAction func showUserProfile(sender: AnyObject) {
    }
    
    @IBAction func showNextMessage(sender: AnyObject) {
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        conversationNotReadCount = conversation.unread
    }

    static func showConversationViewController(nvc:UINavigationController,conversation:Conversation)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationViewController") as! ConversationViewController
        let vm = ConversationViewModel()
        vm.id = conversation.conversationId
        vm.unread = 0
        vm.userId = conversation.chatterId
        controller.conversation = vm
        nvc.pushViewController(controller, animated: true)
    }

}

