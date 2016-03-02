//
//  ViewController.swift
//  SeeYou
//
//  Created by AlexChow on 16/2/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ConversationModel {
    var id:String!
    var userId:String!
    var unread:Int = 0
}

//MARK: ConversationViewController
class ConversationViewController: UIViewController {

    var conversation:ConversationModel!
    
    private var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    
    //MARK: actions
    @IBAction func showConversationList(sender: AnyObject) {
        ConversationListController.showConversationListController(self.navigationController!)
    }
    
    @IBAction func showRecordMessage(sender: AnyObject) {
        RecordMessageController.showRecordMessageController(self.navigationController!)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

