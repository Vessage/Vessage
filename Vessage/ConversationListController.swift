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
typealias ConversationListCellHandler = (cell:ConversationListCell)->Void
class ConversationListCell:ConversationListCellBase{
    static let reuseId = "ConversationListCell"
    var originModel:AnyObject?
    var avatar:String!{
        didSet{
            if let imgView = self.avatarView{
                ServiceContainer.getService(FileService).setAvatar(imgView, iconFileId: avatar)
            }
        }
    }
    var headLine:String!{
        didSet{
            self.headLineLabel?.text = headLine
        }
    }
    var subLine:String!{
        didSet{
            self.subLineLabel?.text = subLine
        }
    }
    
    var badge:Int = 0{
        didSet{
            if badge == 0{
                badgeButton.badgeValue = ""
            }else{
                badgeButton.badgeValue = "\(badge)"
            }
        }
    }
    
    var conversationListCellHandler:ConversationListCellHandler!
    override func onCellClicked(a: UITapGestureRecognizer) {
        if let handler = conversationListCellHandler{
            handler(cell: self)
        }
    }
    @IBOutlet weak var badgeButton: UIButton!{
        didSet{
            badgeButton.backgroundColor = UIColor.clearColor()
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
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
        peoplePicker.dismissViewControllerAnimated(true) { () -> Void in
            
            if let phones = ABRecordCopyValue(person, kABPersonPhoneProperty)?.takeRetainedValue(){
                if ABMultiValueGetCount(phones) > 0{
                    var actions = [UIAlertAction]()
                    var phoneNos = [String]()
                    for i in 0 ..< ABMultiValueGetCount(phones){
                        
                        let phoneLabel = ABMultiValueCopyLabelAtIndex(phones, i).takeRetainedValue()
                            as CFStringRef;
                        let localizedPhoneLabel = ABAddressBookCopyLocalizedLabel(phoneLabel)
                            .takeRetainedValue() as String
                        
                        let value = ABMultiValueCopyValueAtIndex(phones, i)
                        let phone = value.takeRetainedValue() as! String
                        phoneNos.append(phone)
                        let action = UIAlertAction(title: "\(localizedPhoneLabel):\(phone)", style: .Default, handler: { (action) -> Void in
                            if let i = actions.indexOf(action){
                                let hud = self.rootController.showActivityHud()
                                self.rootController.conversationService.openConversationByMobile(phoneNos[i], callback: { (updatedConversation) -> Void in
                                    hud.hideAsync(true)
                                    if let c = updatedConversation{
                                        ConversationViewController.showConversationViewController(self.rootController.navigationController!, conversation: c)
                                    }
                                })
                            }
                        })
                        actions.append(action)
                    }
                    if actions.count > 0{
                        let fname = ABRecordCopyValue(person, kABPersonFirstNameProperty)?.takeRetainedValue() ?? ""
                        let lname = ABRecordCopyValue(person, kABPersonLastNameProperty)?.takeRetainedValue() ?? ""
                        let title = "\(lname!) \(fname!)"
                        let msg = "CHOOSE_PHONE_NO".localizedString()
                        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
                        actions.forEach{alertController.addAction($0)}
                        alertController.addAction(UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: nil))
                        self.rootController.showAlert(alertController)
                        return
                    }
                }
            }
            self.rootController.playToast("PEOPLE_NO_MOBILE".localizedString())
        }
    }
}

class SearchResultModel{
    var conversationId:String!
    var user:VessageUser!
    var mobile:String!
}

//MARK: ConversationListController
class ConversationListController: UITableViewController,UISearchBarDelegate {

    let conversationService = ServiceContainer.getService(ConversationService)
    let vessageService = ServiceContainer.getService(VessageService)
    let userService = ServiceContainer.getService(UserService)
    
    //MARK: search property
    private var searchResult = [SearchResultModel](){
        didSet{
            if isSearching{
                tableView.reloadData()
            }
        }
    }
    private var isSearching:Bool = false{
        didSet{
            if tableView != nil{
                tableView.reloadData()
            }
            if searchBar != nil{
                searchBar.showsCancelButton = isSearching
                if isSearching == false{
                    searchBar.endEditing(false)
                }
            }
        }
    }
    @IBOutlet weak var searchBar: UISearchBar!{
        didSet{
            searchBar.showsCancelButton = false
            searchBar.delegate = self
        }
    }
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.conversationService.addObserver(self, selector: "onConversationListUpdated:", name: ConversationService.conversationListUpdated, object: nil)
        userService.addObserver(self, selector: "onUserProfileUpdated:", name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: "onNewVessageReveiced:", name: VessageService.onNewVessageReceived, object: nil)
        self.conversationService.getConversationListFromServer()
    }
    
    //MARK: notifications
    func onConversationListUpdated(a:NSNotification){
        self.tableView.reloadData()
    }

    func onUserProfileUpdated(a:NSNotification){
        
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if let index = (conversationService.conversations.indexOf{ $0.chatterId == user.userId || $0.chatterMobile == user.mobile }){
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 1)) as? ConversationListCell{
                    if let cv = cell.originModel as? Conversation{
                        cv.chatterMobile = user.mobile
                        cell.avatar = user.avatar
                        
                    }
                }
            }
        }
    }
    
    func onNewVessageReveiced(a:NSNotification){
        if let msg = a.userInfo?[NewVessageReceivedValue] as? Vessage{
            if let index = (conversationService.conversations.indexOf{ $0.conversationId == msg.conversationId }){
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 1)) as? ConversationListCell{
                    if let cv = cell.originModel as? Conversation{
                        if cv.conversationId == msg.conversationId{
                            cell.badge = (cell.badge ?? 0) + 1
                        }
                        
                    }
                }
            }
            
        }
    }
    
    //MARK: actions
    @IBAction func showUserSetting(sender: AnyObject) {
        //TODO: open user setting view
    }
    
    func handleSearchResult(cell:ConversationListCell){
        isSearching = false
        let hud = self.showActivityHud()
        if let result = cell.originModel as? SearchResultModel{
            if let cid = result.conversationId{
                if let c = (conversationService.conversations.filter{cid == $0.conversationId}).first{
                    hud.hideAsync(true)
                    ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
                }
            }else if let u = result.user{
                conversationService.openConversationByUserId(u.userId, callback: { (updatedConversation) -> Void in
                    hud.hideAsync(true)
                    if let c = updatedConversation{
                        ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
                    }
                })
            }else if let mobile = result.mobile{
                conversationService.openConversationByMobile(mobile, callback: { (updatedConversation) -> Void in
                    hud.hideAsync(true)
                    if let c = updatedConversation{
                        ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
                    }
                })
            }
        }
    }
    
    func handleConversationListCellItem(cell:ConversationListCell){
        if let conversation = cell.originModel as? Conversation{
            ConversationViewController.showConversationViewController(self.navigationController!,conversation: conversation)
        }else{
            self.playCrossMark("NO_SUCH_CONVERSATION".localizedString())
        }
    }
    
    //MARK: search bar delegate
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.text = nil
        isSearching = false
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        userService.searchUser(searchText) { (user) -> Void in
            
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        isSearching = false
    }
    
    //MARK: table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.isSearching{
            return 1
        }else{
            return 2
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching{
            return searchResult.count
        }else{
            if section == 0{
                return 1
            }else{
                return conversationService.conversations.count
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:ConversationListCellBase! = nil
        if isSearching{
            let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
            lc.conversationListCellHandler = handleSearchResult
            lc.originModel = searchResult[indexPath.row]
            cell = lc
        }else{
            if indexPath.section == 0{
                cell = tableView.dequeueReusableCellWithIdentifier(ConversationListContactCell.reuseId, forIndexPath: indexPath) as! ConversationListContactCell
            }else{
                let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
                let conversation = conversationService.conversations[indexPath.row]
                lc.originModel = conversation
                lc.headLine = conversation.chatterNoteName ?? conversation.chatterMobile
                lc.subLine = conversation.lastMessageTime
                lc.badge = vessageService.getConversationNotReadVessage(conversation.conversationId).count
                lc.conversationListCellHandler = handleConversationListCellItem
                cell = lc
            }
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
