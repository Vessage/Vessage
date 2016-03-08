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
class ConversatinoListCellModel{
    var orginValue:AnyObject?
    var avatar:String!
    var headLine:String!
    var subLine:String!
}
typealias ConversationListCellHandler = (cell:ConversationListCell)->Void
class ConversationListCell:ConversationListCellBase{
    static let reuseId = "ConversationListCell"
    var model:ConversatinoListCellModel!{
        didSet{
            self.headLineLabel.text = model.headLine
            self.subLineLabel.text = model.subLine
        }
    }
    var conversationListCellhandler:ConversationListCellHandler!
    override func onCellClicked(a: UITapGestureRecognizer) {
        if let handler = conversationListCellhandler{
            handler(cell: self)
        }
    }
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var headLineLabel: UILabel!
    @IBOutlet weak var subLineLabel: UILabel!
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

    let conversationService = ServiceContainer.getService(ConversationService)
    
    @IBOutlet weak var searchBar: UISearchBar!
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
    }
    
    //MARK: actions
    @IBAction func showUserSetting(sender: AnyObject) {
    }
    
    func handleSearchResult(cell:ConversationListCell){
        
    }
    
    func handleConversationListCellItem(cell:ConversationListCell){
        if let conversation = cell.model.orginValue as? Conversation{
            ConversationViewController.showConversationViewController(self.navigationController!,conversation: conversation)
        }else{
            self.playCrossMark("NO_SUCH_CONVERSATION".localizedString())
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }else{
            return conversationService.conversations.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:ConversationListCellBase! = nil
        if indexPath.section == 0{
            cell = tableView.dequeueReusableCellWithIdentifier(ConversationListContactCell.reuseId, forIndexPath: indexPath) as! ConversationListContactCell
        }else{
            let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
            lc.model.orginValue = conversationService.conversations[indexPath.row]
            lc.conversationListCellhandler = handleConversationListCellItem
            cell = lc
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
