//
//  ConversationListController.swift
//  SeeYou
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import AddressBook
import AddressBookUI

//MARK: ConversationListCellBase
class ConversationListCellBase:UITableViewCell{
    var rootController:ConversationListController!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onCellClicked:"))
    }
    
    func onCellClicked(a:UITapGestureRecognizer){
        
    }
}

//MARK: ConversationListCell
class ConversationListCell:ConversationListCellBase{
    static let reuseId = "ConversationListCell"
    
    override func onCellClicked(a: UITapGestureRecognizer) {
        ConversationViewController.showConversationViewController(self.rootController.navigationController!)
    }
}

//MARK: ConversationListContactCell
class ConversationListContactCell:ConversationListCellBase,ABPeoplePickerNavigationControllerDelegate{
    static let reuseId = "ConversationListContactCell"
    
    override func onCellClicked(a: UITapGestureRecognizer) {
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        self.rootController.presentViewController(controller, animated: true) { () -> Void in
            
        }
    }
    
    //MARK: ABPeoplePickerNavigationControllerDelegate
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord, property: ABPropertyID, identifier: ABMultiValueIdentifier) {
        
    }
}

//MARK: ConversationListController
class ConversationListController: UITableViewController {

    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
    }
    
    @IBAction func showUserSetting(sender: AnyObject) {
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }else{
            return 2
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:ConversationListCellBase! = nil
        if indexPath.section == 0{
            cell = tableView.dequeueReusableCellWithIdentifier(ConversationListContactCell.reuseId, forIndexPath: indexPath) as! ConversationListContactCell
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
        }
        cell.rootController = self
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0{
            return UITableViewAutomaticDimension
        }else{
            return 56
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            return 0
        }else{
            return 23
        }
    }
    
    static func showConversationListController(viewController:UIViewController)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationListController") as! ConversationListController
        let nvc = UINavigationController(rootViewController: controller)
        viewController.presentViewController(nvc, animated: false) { () -> Void in
            
        }
    }
}
