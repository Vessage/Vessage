//
//  ConversationListController.swift
//  SeeYou
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import MJRefresh

//MARK: ConversationListController
class ConversationListController: UITableViewController {

    static let chatImageMgrSection = 0
    static let newConversationSection = 1
    static let conversationSection = 2
    
    let conversationService = ServiceContainer.getConversationService()
    let vessageService = ServiceContainer.getVessageService()
    let userService = ServiceContainer.getUserService()
    let groupService = ServiceContainer.getChatGroupService()
    
    //MARK: search property
    var searchResult = [SearchResultModel](){
        didSet{
            if isSearching{
                tableView.reloadData()
            }
        }
    }
    
    var isSearching:Bool = false{
        didSet{
            if tableView != nil{
                tableView.reloadData()
            }
            if searchBar != nil{
                searchBar.text = nil
                searchBar.setShowsCancelButton(isSearching, animated: true)
                if isSearching == false{
                    searchBar.endEditing(false)
                }
            }
            self.navigationItem.leftBarButtonItem?.enabled = !isSearching
            self.navigationItem.rightBarButtonItem?.enabled = !isSearching
            self.searchBar.placeholder = ( isSearching ? "SEARCH_FRIENDS_HOLODER":"SEARCH_FRIENDS").localizedString()
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!{
        didSet{
            searchBar.showsCancelButton = false
            searchBar.delegate = self
        }
    }
    
    private var flashTipsView:FlashTipsLabel = {
       return FlashTipsLabel()
    }()
    
    //MARK:Debug Get Data
    #if DEBUG
    static var autoRefreshData:Bool = false{
        didSet{
            if autoRefreshData && getDataTimer == nil{
                getDataTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(ConversationListController.onDebugGetData(_:)), userInfo: nil, repeats: true)
            }else{
                getDataTimer?.invalidate()
                getDataTimer = nil
            }
        }
    }
    private static var getDataTimer:NSTimer!
    static func onDebugGetData(_:NSTimer) {
        dispatch_async(dispatch_get_main_queue()) {
            ServiceContainer.getVessageService().newVessageFromServer()
        }
    }
    #endif
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict = [NSForegroundColorAttributeName:UIColor.themeColor]
        self.navigationController?.navigationBar.titleTextAttributes = dict
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.tableFooterView = UIView()
        initObservers()
        let titleView = NavigationBarTitle.instanceFromXib()
        self.navigationItem.titleView = titleView
        initMJRefreshHeader()
        
        #if DEBUG
            ConversationListController.autoRefreshData = true
        #endif
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.backBarButtonItem?.title = VessageConfig.appName
        PersistentManager.sharedInstance.saveAll()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tryShowConversationsTimeUpTips()
        
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationListController.onTimerRefreshList(_:)), name: AppService.intervalTimeTaskPerMinute, object: nil)
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationListController.onTimerRefreshList(_:)), name: AppService.onAppBecomeActive, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getAppService().removeObserver(self)
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    private func initMJRefreshHeader() {
        let mjHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(ConversationListController.refreshNewUsers(_:)))
        mjHeader.setTitle("REFRESH_NEAR_USER_PULLING".localizedString(), forState: .Pulling)
        mjHeader.setTitle("REFRESH_NEAR_USER_REFRESHING".localizedString(), forState: .Refreshing)
        mjHeader.setTitle("REFRESH_NEAR_USER_IDLE".localizedString(), forState: .Idle)
        mjHeader.setTitle("REFRESH_NEAR_USER_WILL_REFRESH".localizedString(), forState: .WillRefresh)
        mjHeader.arrowView.hidden = true
/*
        let mjHeader = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(ConversationListController.refreshNewUsers(_:)))
        mjHeader.stateLabel.hidden = true
        mjHeader.setImages(hudSpinImageArray, forState: .Refreshing)
        mjHeader.setImages(hudSpinImageArray, forState: .Pulling)
        mjHeader.setImages(hudSpinImageArray, forState: .WillRefresh)
        mjHeader.setImages(nil, forState: .Idle)
 */
        mjHeader.lastUpdatedTimeLabel.hidden = true
        self.tableView.mj_header = mjHeader
    }
    
    private var refreshedNewUserTime:NSDate!
    private let refreshNewUserIntervalMinutes = 10.0
    func refreshNewUsers(sender:AnyObject) {
        if refreshedNewUserTime == nil || abs(refreshedNewUserTime.totalMinutesSinceNow.doubleValue) > refreshNewUserIntervalMinutes {
            self.refreshedNewUserTime = NSDate()
            let locationService = ServiceContainer.getLocationService()
            if let hereLocation = locationService.hereLocationString{
                ServiceContainer.getUserService().getNearUsers(hereLocation,checkTime: false)
            }
            ServiceContainer.getUserService().getActiveUsers(){ users in
                self.tableView.mj_header?.endRefreshing()
            }
        }else{
            self.tableView.mj_header?.endRefreshing()
        }
    }
    
    private func initObservers(){
        conversationService.addObserver(self, selector: #selector(ConversationListController.onConversationListUpdated(_:)), name: ConversationService.conversationListUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationListController.onNewVessagesReceived(_:)), name: VessageService.onNewVessagesReceived, object: nil)
        
        ServiceContainer.instance.addObserver(self, selector: #selector(ConversationListController.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        
    }
    
    private func releaseController(){
        ServiceContainer.getAppService().removeObserver(self)
        VessageQueue.sharedInstance.removeObserver(self)
        ServiceContainer.instance.removeObserver(self)
        ServiceContainer.getConversationService().removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
        
        #if DEBUG
            ConversationListController.autoRefreshData = false
        #endif
    }
    
    private func tryShowConversationsTimeUpTips() {
        if UIApplication.sharedApplication().applicationState == .Active && self.navigationController?.topViewController == self && self.presentedViewController == nil{
            if conversationService.timeupedConversations.count > 0 {
                
                let msg = String(format: "X_TIMEUPED_CONVERSATION_REMOVED".localizedString(), "\(conversationService.timeupedConversations.count)")
                
                let userIds = (conversationService.timeupedConversations.filter{$0.type == Conversation.typeSingleChat && $0.chatterId != nil}).map({ (c) -> String in
                    return c.chatterId
                })
                userService.deleteCachedUsers(userIds)
                
                conversationService.removeTimeupedConversations()
                
                flashTips(msg)
                
            }
        }
    }
    
    //MARK: notifications
    func onTimerRefreshList(_:AnyObject?) {
        if tableViewEndDecelerating {
            self.conversationService.clearTimeUpConversations()
        }
    }
    
    func onServicesWillLogout(a:NSNotification) {
        releaseController()
    }
    
    func onConversationListUpdated(a:NSNotification){
        self.tryShowConversationsTimeUpTips()
        self.tableView.reloadData()
    }
    
    func onNewVessagesReceived(a:NSNotification){
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
        UserSettingViewController.showUserSettingViewController(self.navigationController!,basicMode: false)
    }
    
    @IBAction func onClickQA(sender: AnyObject) {
        if let nvc = self.navigationController{
            SimpleBrowser.openUrl(nvc, url: "http://bahamut.cn/VGQA.html", title: "Q&A")
        }
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
                hud.hideAnimated(true)
                if let u = user{
                    let delegate = UserProfileViewControllerDelegateOpenConversation()
                    UserProfileViewController.showUserProfileViewController(self, userProfile: u, delegate: delegate)
                }else{
                    self.showAlert("OPEN_MOBILE_CONVERSATION_FAIL".localizedString(), msg: mobile)
                }
            })
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
            //change bcg + new chat + conversations
            return 3
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearching{
            return searchResult.count
        }else{
            switch section {
            case ConversationListController.chatImageMgrSection:
                return 0
            case ConversationListController.newConversationSection:
                return 2
            default:
                return conversationService.conversations.count
            }
        }
    }
    
    private func searchingTableView(tableView: UITableView, indexPath: NSIndexPath) -> ConversationListCellBase{
        let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
        lc.subLineLabel.morphingEnabled = tableViewEndDecelerating
        let sr = searchResult[indexPath.row]
        lc.rootController = self
        lc.conversationListCellHandler = handleSearchResult
        lc.originModel = sr
        return lc
    }
    
    private func normalTableView(tableView: UITableView, indexPath: NSIndexPath) -> ConversationListCellBase{
        if indexPath.section == ConversationListController.chatImageMgrSection{
            let cell = tableView.dequeueReusableCellWithIdentifier(ChatImageManageCell.reuseId, forIndexPath: indexPath) as! ConversationListCellBase
            cell.rootController = self
            return cell
        }else if indexPath.section == ConversationListController.newConversationSection{
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier(ConversationListContactCell.reuseId, forIndexPath: indexPath) as! ConversationListContactCell
                cell.titleLabel.text = "SEL_CONTACTS_ITEM".localizedString()
                cell.rootController = self
                return cell
            }else{
                let cell = tableView.dequeueReusableCellWithIdentifier(ConversationListGroupChatCell.reuseId, forIndexPath: indexPath) as! ConversationListCellBase
                cell.rootController = self
                return cell
            }
        }else{
            let lc = tableView.dequeueReusableCellWithIdentifier(ConversationListCell.reuseId, forIndexPath: indexPath) as! ConversationListCell
            lc.subLineLabel.morphingEnabled = tableViewEndDecelerating
            let conversation = conversationService.conversations[indexPath.row]
            lc.rootController = self
            lc.conversationListCellHandler = handleConversationListCellItem
            lc.originModel = conversation
            return lc
        }
    }
    
    private var tableViewEndDecelerating = true
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        tableViewEndDecelerating = false
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        tableViewEndDecelerating = true
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell!
        if isSearching{
            cell = searchingTableView(tableView, indexPath: indexPath)
        }else{
            cell = normalTableView(tableView, indexPath: indexPath)
        }
        cell.selected = false
        cell.setSeparatorFullWidth()
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationListCellBase{
            cell.selected = false
            cell.onCellClicked()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == ConversationListController.chatImageMgrSection{
            return 0
        }else{
            return 23
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if isSearching == false && indexPath.section == ConversationListController.conversationSection{
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if isSearching == false && indexPath.section == ConversationListController.conversationSection{
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationListCell{
                if let conversation = cell.originModel as? Conversation{
                    let acRemove = UITableViewRowAction(style: .Default, title: "REMOVE".localizedString(), handler: { (ac, indexPath) -> Void in
                        self.removeConversation(conversation.conversationId,message: cell.headLineLabel.text)
                    })
                    
                    var acPin:UITableViewRowAction? = nil
                    if conversation.pinned {
                        acPin = UITableViewRowAction(style: .Default, title: "UNPIN".localizedString(), handler: { (ac, indexPath) in
                            if self.conversationService.unpinConversation(conversation){
                                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                            }
                        })
                    }else{
                        acPin = UITableViewRowAction(style: .Default, title: "PIN".localizedString(), handler: { (ac, indexPath) in
                            
                            if self.conversationService.pinConversation(conversation){
                                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                            }else{
                                self.playToast(String(format: "MAX_PIN_X_LIMITED".localizedString(), "\(ConversationService.conversationMaxPinNumber)"))
                            }
                        })
                    }
                    
                    return [acRemove,acPin!]
                }
            }
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}

//MARK: handle click list cell
private let defaultNearActiveConversationBeforeRemoveTs:Int64 = 1000 * 60 * 60
private var openConversationBeforeRemoveTs:Int64 = ConversationMaxTimeUpMS

extension ConversationListController:UserProfileViewControllerDismissedDelegate{
    
    func userProfileViewControllerDismissed(sender: UserProfileViewController) {
        MainTabBarController.instance?.tabBar.hidden = false
    }
    
    func userProfileViewController(sender: UserProfileViewController, rightButtonClicked profile: VessageUser) {
        if let userId = profile.userId{
            let beforeRemoveTs = openConversationBeforeRemoveTs
            openConversationBeforeRemoveTs = ConversationMaxTimeUpMS
            
            sender.dismissViewControllerAnimated(true, completion: {
                MainTabBarController.instance?.tabBar.hidden = false
                ConversationViewController.showConversationViewController(self.navigationController!, userId : userId,beforeRemoveTs: beforeRemoveTs)
            })
        }
    }
    
    func userProfileViewController(sender: UserProfileViewController, rightButtonTitle profile: VessageUser) -> String {
        return "CHAT".localizedString()
    }
    
    func handleSearchResult(cell:ConversationListCell){
        isSearching = false
        if let result = cell.originModel as? SearchResultModel{
            MobClick.event("Vege_OpenSearchResultConversation")
            if let c = result.conversation{
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
            }else if let u = result.user{
                
                if result.type == .userActive ||
                    result.type == .userActiveNear ||
                    result.type == .userNear{
                    openConversationBeforeRemoveTs = defaultNearActiveConversationBeforeRemoveTs
                }
                
                UserProfileViewController.showUserProfileViewController(self, userId: u.userId, delegate: self){ profileVC in
                    MainTabBarController.instance?.tabBar.hidden = true
                    profileVC.accountIdHidden = true
                }
            }else if let mobile = result.mobile{
                MobClick.event("Vege_OpenSearchResultMobileConversation")
                openConversationWithMobile(mobile, noteName: result.mobile ?? result.keyword)
            }
        }
    }
}

//MARK: Flash Tips
extension ConversationListController{
    
    func flashTips(msg:String) {
        self.flashTipsView.flashTips(self.view, msg: msg, center: CGPointMake(self.view.frame.width / 2, self.view.frame.height - 160))
    }
    
}
