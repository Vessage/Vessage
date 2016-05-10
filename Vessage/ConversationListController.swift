//
//  ConversationListController.swift
//  SeeYou
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: SearchResultModel
class SearchResultModel{
    var keyword:String!
    var conversation:Conversation!
    var user:VessageUser!
    var mobile:String!
}

//MARK: ConversationListCellBase
class ConversationListCellBase:UITableViewCell{
    var rootController:ConversationListController!
    
    func onCellClicked(){
        
    }
}

//MARK: ConversationListController
class ConversationListController: UITableViewController,UISearchBarDelegate {

    let conversationService = ServiceContainer.getConversationService()
    let vessageService = ServiceContainer.getVessageService()
    let userService = ServiceContainer.getUserService()
    
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
                searchBar.text = nil
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
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.tableFooterView = UIView()
        initObservers()
        vessageService.newVessageFromServer()
    }
    
    private func initObservers(){
        conversationService.addObserver(self, selector: #selector(ConversationListController.onConversationListUpdated(_:)), name: ConversationService.conversationListUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationListController.onNewVessagesReceived(_:)), name: VessageService.onNewVessagesReceived, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationListController.onVessageSended(_:)), name: VessageService.onNewVessageSended, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationListController.onVessageSendFail(_:)), name: VessageService.onNewVessageSendFail, object: nil)
        
        //MARK: Chicago
        //ChicagoClient.sharedInstance.addBahamutAppNotificationObserver(self, notificationType: "NewVessageNotify", selector: "onNewVessageNotify:", object: nil)
    }
    
    private func removeObservers(){
        //MARK: Chicago
        //ChicagoClient.sharedInstance.removeBahamutAppNotificationObserver(self, notificationType: "NewVessageNotify", object: nil)
        
        ServiceContainer.getConversationService().removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
    }
    
    deinit{
        removeObservers()
    }
    
    //MARK: notifications
    func onVessageSendFail(a:NSNotification){
        if let task = a.userInfo?[SendedVessageTaskValue] as? VessageFileUploadTask{
            if let receiverId = task.receiverId{
                conversationService.setConversationNewestModified(receiverId)
            }
        }
    }
    
    func onVessageSended(a:NSNotification){
        if let task = a.userInfo?[SendedVessageTaskValue] as? VessageFileUploadTask{
            if let receiverId = task.receiverId{
                conversationService.setConversationNewestModified(receiverId)
            }else if let mobile = task.receiverMobile{
                conversationService.setConversationNewestModifiedByMobile(mobile)
            }
        }
    }
    
    func onNewVessageNotify(a:NSNotification){
        vessageService.newVessageFromServer()
    }
    
    func onConversationListUpdated(a:NSNotification){
        self.tableView.reloadData()
    }
    
    func onNewVessagesReceived(a:NSNotification){
        if let vsgs = a.userInfo?[VessageServiceNotificationValues] as? [Vessage]{
            
            let newConversations = conversationService.updateConversationListWithVessagesReturnNewConversations(vsgs)
            newConversations.forEach({ (c) in
                if let chatter = c.chatterId{
                    userService.fetchUserProfile(chatter)
                }
            })
        }
    }
    
    //MARK: actions
    @IBAction func showUserSetting(sender: AnyObject) {
        UserSettingViewController.showUserSettingViewController(self.navigationController!)
    }
    
    private func removeConversation(conversation:Conversation){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.conversationService.removeConversation(conversation.conversationId)
        }
        let cancel = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: nil)
        self.showAlert("ASK_REMOVE_CONVERSATION_TITLE".localizedString(), msg: conversation.noteName, actions: [okAction,cancel])
    }
    
    //MARK: handle click list cell
    func handleSearchResult(cell:ConversationListCell){
        isSearching = false
        if let result = cell.originModel as? SearchResultModel{
            MobClick.event("OpenSearchResultConversation")
            if let c = result.conversation{
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
            }else if let u = result.user{
                let conversation = conversationService.openConversationByUserId(u.userId,noteName: u.nickName ?? u.accountId ?? result.keyword)
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
            }else if let mobile = result.mobile{
                MobClick.event("OpenSearchResultMobileConversation")
                let conversation = conversationService.openConversationByMobile(mobile,noteName: result.mobile ?? result.keyword)
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
            }
        }
    }
    
    func handleConversationListCellItem(cell:ConversationListCell){
        if let conversation = cell.originModel as? Conversation{
            MobClick.event("OpenConversation")
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
        if String.isNullOrWhiteSpace(searchBar.text){
            isSearching = false
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchResult.removeAll()
        if String.isNullOrWhiteSpace(searchText) == false{
            let conversations = conversationService.searchConversation(searchText)
            let res = conversations.map({ (c) -> SearchResultModel in
                let model = SearchResultModel()
                model.keyword = searchText
                model.conversation = c
                return model
            })
            searchResult.appendContentsOf(res)
            userService.searchUser(searchText, callback: { (resultUsers) -> Void in
                if let currentText = searchBar.text{
                    if currentText != searchText{
                        print("ignore search result")
                        return
                    }
                }
                let results = resultUsers.filter({ (resultUser) -> Bool in
                    return conversations.count == 0 || !conversations.contains({ (c) -> Bool in
                        if let chatterId = c.chatterId{
                            return chatterId == resultUser.userId
                        }
                        return false
                    })
                }).map({ (resultUser) -> SearchResultModel in
                    let model = SearchResultModel()
                    model.user = resultUser
                    model.keyword = searchText
                    return model
                })
                self.searchResult.appendContentsOf(results)
                if self.searchResult.count == 0 && searchText.isMobileNumber(){
                    let model = SearchResultModel()
                    model.keyword = searchText
                    model.mobile = searchText
                    self.searchResult.append(model)
                }
            })
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
    
    private func searchingTableView(tableView: UITableView, indexPath: NSIndexPath) -> ConversationListCellBase{
        let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
        let sr = searchResult[indexPath.row]
        lc.rootController = self
        lc.conversationListCellHandler = handleSearchResult
        lc.originModel = sr
        return lc
    }
    
    private func normalTableView(tableView: UITableView, indexPath: NSIndexPath) -> ConversationListCellBase{
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCellWithIdentifier(ConversationListContactCell.reuseId, forIndexPath: indexPath) as! ConversationListContactCell
            if conversationService.conversations.count > 0{
                cell.titleLabel.text = "CONTACTS".localizedString()
            }else{
                cell.titleLabel.text = "OPEN_A_CONTACT_CONVERSATION".localizedString()
            }
            cell.rootController = self
            return cell
        }else{
            let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
            let conversation = conversationService.conversations[indexPath.row]
            lc.rootController = self
            lc.conversationListCellHandler = handleConversationListCellItem
            lc.originModel = conversation
            return lc
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isSearching{
            return searchingTableView(tableView, indexPath: indexPath)
        }else{
            return normalTableView(tableView, indexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationListCellBase{
            cell.onCellClicked()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if isSearching{
            return 56
        }else if indexPath.section == 0{
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
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if isSearching == false && indexPath.section == 1{
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if isSearching == false && indexPath.section == 1{
            let actionTitle = "REMOVE".localizedString()
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationListCell{
                if let conversation = cell.originModel as? Conversation{
                    let action = UITableViewRowAction(style: .Default, title: actionTitle, handler: { (ac, indexPath) -> Void in
                        self.removeConversation(conversation)
                    })
                    return [action]
                }
            }
        }
        return nil
    }
    
    //MARK: showConversationListController
    static func showConversationListController(viewController:UIViewController)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationListController") as! ConversationListController
        let nvc = UINavigationController(rootViewController: controller)
        viewController.presentViewController(nvc, animated: false) { () -> Void in
            
        }
    }
}
