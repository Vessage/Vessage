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
    var activeUser:Bool = false
    var mobile:String!
}

//MARK: ConversationListCellBase
class ConversationListCellBase:UITableViewCell{
    weak var rootController:ConversationListController!
    
    func onCellClicked(){
        
    }
    
    deinit{
        rootController = nil
        #if DEBUG
            print("Deinited:ConversationListCellBase")
        #endif
    }
}

//MARK: ConversationListController
class ConversationListController: UITableViewController {

    let conversationService = ServiceContainer.getConversationService()
    let vessageService = ServiceContainer.getVessageService()
    let userService = ServiceContainer.getUserService()
    let groupService = ServiceContainer.getChatGroupService()
    private var refreshListTimer:NSTimer!
    
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
            self.navigationItem.leftBarButtonItem?.enabled = !isSearching
            self.navigationItem.rightBarButtonItem?.enabled = !isSearching
        }
    }
    @IBOutlet weak var searchBar: UISearchBar!{
        didSet{
            searchBar.showsCancelButton = false
            searchBar.delegate = self
        }
    }
    private var showing:Bool = false
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        let dict = [NSForegroundColorAttributeName:UIColor.themeColor]
        self.navigationController?.navigationBar.titleTextAttributes = dict
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.tableFooterView = UIView()
        initObservers()
        vessageService.newVessageFromServer()
        let titleView = NavigationBarTitle.instanceFromXib()
        self.navigationItem.titleView = titleView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.backBarButtonItem?.title = VessageConfig.appName
        PersistentManager.sharedInstance.saveAll()
        showing = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showing = false
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    private func initObservers(){
        conversationService.addObserver(self, selector: #selector(ConversationListController.onConversationListUpdated(_:)), name: ConversationService.conversationListUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationListController.onNewVessagesReceived(_:)), name: VessageService.onNewVessagesReceived, object: nil)
        
        ServiceContainer.instance.addObserver(self, selector: #selector(ConversationListController.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        
        refreshListTimer = NSTimer.scheduledTimerWithTimeInterval(100, target: self, selector: #selector(ConversationListController.onTimerRefreshList(_:)), userInfo: nil, repeats: true)
        
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationListController.onVessageSended(_:)), name: VessageQueue.onTaskFinished, object: nil)
    }
    
    private func releaseController(){
        VessageQueue.sharedInstance.removeObserver(self)
        ServiceContainer.instance.removeObserver(self)
        ServiceContainer.getConversationService().removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
        refreshListTimer.invalidate()
        refreshListTimer = nil
    }
    
    //MARK: notifications
    func onTimerRefreshList(_:AnyObject?) {
        self.tableView.reloadData()
    }
    
    func onServicesWillLogout(a:NSNotification) {
        releaseController()
    }
    
    func onVessageSended(a:NSNotification) {
        if let task = a.userInfo?[kSendVessageQueueTaskValue] as? SendVessageQueueTask{
            conversationService.setConversationNewestModified(task.receiverId)
        }
    }
    
    func onNewVessageNotify(a:NSNotification){
        vessageService.newVessageFromServer()
    }
    
    func onConversationListUpdated(a:NSNotification){
        self.tableView.reloadData()
    }
    
    func onNewVessagesReceived(a:NSNotification){
        if showing {
            SystemSoundHelper.vibrate()
        }
        if let vsgs = a.userInfo?[VessageServiceNotificationValues] as? [Vessage]{
            vsgs.forEach({ (vsg) in
                if !vsg.isGroup{
                    if String.isNullOrEmpty(self.userService.getUserNotedNameIfExists(vsg.sender)){
                        if let nick = vsg.getExtraInfoObject()?.nickName{
                            self.userService.setUserNoteName(vsg.sender, noteName: nick)
                        }
                    }
                }
            })
            conversationService.updateConversationListWithVessagesReturnNewConversations(vsgs)
        }
    }
    
    //MARK: actions
    @IBAction func showUserSetting(sender: AnyObject) {
        UserSettingViewController.showUserSettingViewController(self.navigationController!)
    }
    
    @IBAction func tellFriends(sender: AnyObject) {
        ShareHelper.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString())
    }
    
    private func removeConversation(conversationId:String,message:String?){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.conversationService.removeConversation(conversationId)
        }
        let cancel = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: nil)
        self.showAlert("ASK_REMOVE_CONVERSATION_TITLE".localizedString(), msg: message, actions: [okAction,cancel])
    }
    
    func openConversationWithMobile(mobile:String,noteName:String?) {
        if let user = self.userService.getCachedUserByMobile(mobile){
            ConversationViewController.showConversationViewController(self.navigationController!, userId: user.userId)
        }else{
            let hud = self.showAnimationHud()
            self.userService.registNewUserByMobile(mobile, noteName: noteName ?? mobile, updatedCallback: { (user) in
                hud.hide(true)
                if let u = user{
                    ConversationViewController.showConversationViewController(self.navigationController!, userId: u.userId)
                }else{
                    self.showAlert("OPEN_MOBILE_CONVERSATION_FAIL".localizedString(), msg: mobile)
                }
            })
        }
    }
    
    //MARK: handle click list cell
    func handleSearchResult(cell:ConversationListCell){
        isSearching = false
        if let result = cell.originModel as? SearchResultModel{
            MobClick.event("Vege_OpenSearchResultConversation")
            if let c = result.conversation{
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
            }else if let u = result.user{
                ConversationViewController.showConversationViewController(self.navigationController!, userId : u.userId)
            }else if let mobile = result.mobile{
                MobClick.event("Vege_OpenSearchResultMobileConversation")
                openConversationWithMobile(mobile, noteName: result.mobile ?? result.keyword)
            }
        }
    }
    
    func handleConversationListCellItem(cell:ConversationListCell){
        if let conversation = cell.originModel as? Conversation{
            MobClick.event("Vege_OpenConversation")
            ConversationViewController.showConversationViewController(self.navigationController!,conversation: conversation)
        }else{
            self.playCrossMark("NO_SUCH_CONVERSATION".localizedString())
        }
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
                return 2
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
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(ConversationListContactCell.reuseId, forIndexPath: indexPath) as! ConversationListContactCell
                if conversationService.conversations.count > 0{
                    cell.titleLabel.text = "CONTACTS".localizedString()
                }else{
                    cell.titleLabel.text = "OPEN_A_CONTACT_CONVERSATION".localizedString()
                }
                cell.rootController = self
                return cell
            }else{
                let cell = tableView.dequeueReusableCellWithIdentifier(ConversationListGroupChatCell.reuseId, forIndexPath: indexPath) as! ConversationListGroupChatCell
                cell.rootController = self
                return cell
            }
            
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
            return 60
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
                        self.removeConversation(conversation.conversationId,message: cell.headLineLabel.text)
                    })
                    return [action]
                }
            }
        }
        return nil
    }
}

//MARK: ConversationListController extension UISearchBarDelegate
extension ConversationListController:UISearchBarDelegate
{
    //MARK: search bar delegate
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchResult.removeAll()
        #if DEBUG
            let users = userService.activeUsers.getRandomSubArray(3)
            let hotUserRes = users.map({ (resultUser) -> SearchResultModel in
                let model = SearchResultModel()
                model.user = resultUser
                model.activeUser = true
                model.keyword = resultUser.accountId
                return model
            })
            searchResult.appendContentsOf(hotUserRes)
        #endif
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if String.isNullOrWhiteSpace(searchBar.text){
            isSearching = false
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        let testModeStrs = searchText.split(">")
        if testModeStrs.count == 2 {
            if DeveloperMainPanelController.isShowDeveloperPanel(self, id: testModeStrs[0], psw: testModeStrs[1]){
                isSearching = false
                return
            }
        }
        
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
            let existsUsers = conversations.map({ (c) -> VessageUser in
                let u = VessageUser()
                u.userId = c.chatterId
                u.mobile = c.chatterMobile
                return u
            })
            
            userService.searchUser(searchText, callback: { (keyword, resultUsers) in
                if !String.isNullOrEmpty(searchBar.text) && keyword != searchBar.text{
                    #if DEBUG
                        print("ignore search result")
                    #endif
                    return
                }
                
                let results = resultUsers.filter({ (resultUser) -> Bool in
                    
                    return !existsUsers.contains({ (eu) -> Bool in
                        return VessageUser.isTheSameUser(resultUser, userb: eu)
                    })
                }).map({ (resultUser) -> SearchResultModel in
                    let model = SearchResultModel()
                    model.user = resultUser
                    model.keyword = searchText
                    return model
                })
                
                dispatch_async(dispatch_get_main_queue(), { 
                    self.searchResult.appendContentsOf(results)
                    if self.searchResult.count == 0 && searchText.isMobileNumber(){
                        let model = SearchResultModel()
                        model.keyword = searchText
                        model.mobile = searchText
                        self.searchResult.append(model)
                    }
                })
            })
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        isSearching = false
    }
}

//MARK: Welcome
extension ConversationListController{
    private func tryShowUserGuide() -> Bool{
        if userService.isUserChatBackgroundIsSeted || UserSetting.isSettingEnable(USER_LATER_SET_CHAT_BCG_KEY){
            if !UserSetting.isSettingEnable(INVITED_FRIEND_GUIDE_KEY) {
                InviteFriendsViewController.presentInviteFriendsViewController(self)
                return true
            }else{
                return false
            }
        }else{
            SetupChatBcgImageController.showSetupViewController(self)
            return true
        }
    }
    
    private func tryShowWelcomeAlert() {
        let key = "WELLCOME_ALERT_SHOWN"
        if !UserSetting.isSettingEnable(key) {
            UserSetting.enableSetting(key)
            let startConversationAc = UIAlertAction(title: "NEW_CONVERSATION".localizedString(), style: .Default, handler: { (ac) in
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? ConversationListContactCell{
                    cell.onCellClicked()
                }
            })
            self.showAlert("WELCOME_ALERT_TITLE".localizedString(), msg: "WELCOME_ALERT_MSG".localizedString(),actions: [startConversationAc,ALERT_ACTION_I_SEE])
        }
    }
}
