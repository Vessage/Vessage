//
//  ConversationListController.swift
//  SeeYou
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class SearchResultModel{
    var keyword:String!
    var conversation:Conversation!
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
    }
    
    //MARK: notifications
    func onConversationListUpdated(a:NSNotification){
        self.tableView.reloadData()
    }

    func onUserProfileUpdated(a:NSNotification){
        
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if let index = (conversationService.conversations.indexOf{ user.userId == $0.chatterId  || user.mobile == $0.chatterMobile}){
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
            if let index = (conversationService.conversations.indexOf{ $0.chatterId == msg.sender }){
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 1)) as? ConversationListCell{
                    if let cv = cell.originModel as? Conversation{
                        if cv.chatterId == msg.sender{
                            cv.lastMessageTime = msg.sendTime
                            cv.saveModel()
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
        if let result = cell.originModel as? SearchResultModel{
            if let cid = result.conversation?.conversationId{
                if let c = (conversationService.conversations.filter{cid == $0.conversationId}).first{
                    ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
                }
            }else if let u = result.user{
                let conversation = conversationService.openConversationByUserId(u.userId,noteName: u.nickName ?? result.keyword)
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
            }else if let mobile = result.mobile{
                let conversation = conversationService.openConversationByMobile(mobile,noteName: result.mobile ?? result.keyword)
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
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
        if String.isNullOrWhiteSpace(searchBar.text){
            isSearching = false
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if String.isNullOrWhiteSpace(searchText) == false{
            searchResult.removeAll()
            let conversations = conversationService.searchConversation(searchText)
            let res = conversations.map({ (c) -> SearchResultModel in
                let model = SearchResultModel()
                model.keyword = searchText
                model.conversation = c
                model.mobile = c.chatterMobile
                return model
            })
            searchResult.appendContentsOf(res)
            userService.searchUser(searchText, callback: { (resultUsers) -> Void in
                let results = resultUsers.map({ (resultUser) -> SearchResultModel in
                    let model = SearchResultModel()
                    model.user = resultUser
                    model.keyword = searchText
                    return model
                })
                self.searchResult.insertContentsOf(results, at: 0)
                
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
        lc.conversationListCellHandler = handleSearchResult
        lc.originModel = sr
        if let con = sr.conversation{
            lc.headLine = con.noteName
            lc.subLine = con.lastMessageTime.dateTimeOfAccurateString.toFriendlyString()
        }else if let u = sr.user{
            lc.headLine = u.nickName ?? u.accountId
            lc.subLine = u.accountId
        }
        lc.rootController = self
        return lc
    }
    
    private func normalTableView(tableView: UITableView, indexPath: NSIndexPath) -> ConversationListCellBase{
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCellWithIdentifier(ConversationListContactCell.reuseId, forIndexPath: indexPath) as! ConversationListContactCell
            cell.rootController = self
            return cell
        }else{
            let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
            let conversation = conversationService.conversations[indexPath.row]
            lc.originModel = conversation
            lc.headLine = conversation.noteName ?? conversation.chatterMobile
            lc.subLine = conversation.lastMessageTime.dateTimeOfAccurateString?.toFriendlyString() ?? ""
            if conversation.chatterId != nil{
                let chatter = userService.getUserProfile(conversation.chatterId, updatedCallback: { (user) -> Void in
                    
                })
                if let user = chatter{
                    lc.badge = vessageService.getNotReadVessage(user).count
                }
            }
            lc.conversationListCellHandler = handleConversationListCellItem
            lc.rootController = self
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
    
    static func showConversationListController(viewController:UIViewController)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationListController") as! ConversationListController
        let nvc = UINavigationController(rootViewController: controller)
        viewController.presentViewController(nvc, animated: false) { () -> Void in
            
        }
    }
}
