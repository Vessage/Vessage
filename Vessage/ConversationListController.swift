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
/*
    static let chatImageMgrSection = 0
    static let newConversationSection = 1
    static let selfConversationSection = 2
     */
    static let navItemSection = 0
    static let conversationSection = 1
    
    var ConversationSectionNum:Int{
        //change bcg + new chat + conversations
        return 2
    }
    
    let conversationService = ServiceContainer.getConversationService()
    let vessageService = ServiceContainer.getVessageService()
    let userService = ServiceContainer.getUserService()
    let groupService = ServiceContainer.getChatGroupService()
    var conversations = [Conversation]()
    
    
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
            self.navigationItem.leftBarButtonItem?.isEnabled = !isSearching
            self.navigationItem.rightBarButtonItem?.isEnabled = !isSearching
            MainTabBarController.instance?.tabBar.isHidden = isSearching
            self.searchBar.placeholder = ( isSearching ? "SEARCH_FRIENDS_HOLODER":"SEARCH_FRIENDS").localizedString()
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!{
        didSet{
            searchBar.showsCancelButton = false
            searchBar.delegate = self
        }
    }
    
    fileprivate var flashTipsView:FlashTipsLabel = {
       return FlashTipsLabel()
    }()
    
    //MARK:Debug Get Data
    #if DEBUG
    static var autoRefreshData:Bool = false{
        didSet{
            if autoRefreshData && getDataTimer == nil{
                getDataTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(ConversationListController.onDebugGetData(_:)), userInfo: nil, repeats: true)
            }else{
                getDataTimer?.invalidate()
                getDataTimer = nil
            }
        }
    }
    private static var getDataTimer:Timer!
    static func onDebugGetData(_:Timer) {
        DispatchQueue.main.async {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.backBarButtonItem?.title = VessageConfig.appName
        PersistentManager.sharedInstance.saveAll()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MainTabBarController.instance?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tryShowConversationsTimeUpTips()
        MainTabBarController.instance?.tabBar.isHidden = false
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationListController.onTimerRefreshList(_:)), name: AppService.intervalTimeTaskPerMinute, object: nil)
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationListController.onTimerRefreshList(_:)), name: AppService.onAppBecomeActive, object: nil)
        
        setNavigationBadges()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getAppService().removeObserver(self)
    }
    
    #if DEBUG
    deinit{
        print("Deinited:\(self.description)")
    }
    #endif
    
    fileprivate func initMJRefreshHeader() {
        let mjHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(ConversationListController.refreshNewUsers(_:)))
        mjHeader?.setTitle("REFRESH_NEAR_USER_PULLING".localizedString(), for: .pulling)
        mjHeader?.setTitle("REFRESH_NEAR_USER_REFRESHING".localizedString(), for: .refreshing)
        mjHeader?.setTitle("REFRESH_NEAR_USER_IDLE".localizedString(), for: .idle)
        mjHeader?.setTitle("REFRESH_NEAR_USER_WILL_REFRESH".localizedString(), for: .willRefresh)
        mjHeader?.arrowView.isHidden = true

        mjHeader?.lastUpdatedTimeLabel.isHidden = true
        self.tableView.mj_header = mjHeader
    }
    
    fileprivate var refreshedNewUserTime:Date!
    fileprivate let refreshNewUserIntervalMinutes = 10.0
    func refreshNewUsers(_ sender:AnyObject) {
        if refreshedNewUserTime == nil || abs(refreshedNewUserTime.totalMinutesSinceNow.doubleValue) > refreshNewUserIntervalMinutes {
            self.refreshedNewUserTime = Date()
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
    
    fileprivate func initObservers(){
        conversationService.addObserver(self, selector: #selector(ConversationListController.onConversationListUpdated(_:)), name: ConversationService.conversationListUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationListController.onNewVessagesReceived(_:)), name: VessageService.onNewVessagesReceived, object: nil)
        
        ServiceContainer.instance.addObserver(self, selector: #selector(ConversationListController.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        
    }
    
    fileprivate func releaseController(){
        ServiceContainer.getAppService().removeObserver(self)
        VessageQueue.sharedInstance.removeObserver(self)
        ServiceContainer.instance.removeObserver(self)
        ServiceContainer.getConversationService().removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
        
        #if DEBUG
            ConversationListController.autoRefreshData = false
        #endif
    }
    
    fileprivate func setNavigationBadges() {
        let appService = ServiceContainer.getAppService()
        appService.appQABadge ? navigationItem.leftBarButtonItem?.showMiniBadge() : navigationItem.leftBarButtonItem?.hideMiniBadge()
        appService.settingBadge ? navigationItem.rightBarButtonItem?.showMiniBadge() : navigationItem.rightBarButtonItem?.hideMiniBadge()
    }
    
    fileprivate func tryShowConversationsTimeUpTips() {
        if UIApplication.shared.applicationState == .active && self.navigationController?.topViewController == self && self.presentedViewController == nil{
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
    
    func onServicesWillLogout(_ a:Notification) {
        releaseController()
    }
    
    func onConversationListUpdated(_ a:Notification){
        self.tryShowConversationsTimeUpTips()
        self.tableView.reloadData()
    }
    
    func onNewVessagesReceived(_ a:Notification){
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
    @IBAction func showUserSetting(_ sender: AnyObject) {
        ServiceContainer.getAppService().settingBadge = false
        UserSettingViewController.showUserSettingViewController(self.navigationController!,basicMode: false)
    }
    
    @IBAction func onClickQA(_ sender: AnyObject) {
        if let nvc = self.navigationController{
            ServiceContainer.getAppService().appQABadge = false
            SimpleBrowser.openUrl(nvc, url: "http://bahamut.cn/VGQA.html", title: "Q&A")
        }
    }
    
    fileprivate func removeConversation(_ conversationId:String,message:String?){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .default) { (action) -> Void in
            self.conversationService.removeConversation(conversationId)
        }
        let cancel = UIAlertAction(title: "CANCEL".localizedString(), style: .cancel, handler: nil)
        self.showAlert("ASK_REMOVE_CONVERSATION_TITLE".localizedString(), msg: message, actions: [okAction,cancel])
    }
    
    func handleConversationListCellItem(_ cell:ConversationListCell){
        if let conversation = cell.originModel as? Conversation{
            MobClick.event("Vege_OpenConversation")
            ConversationViewController.showConversationViewController(self.navigationController!,conversation: conversation)
        }else{
            self.playCrossMark("NO_SUCH_CONVERSATION".localizedString())
        }
    }
    
    //MARK: table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.isSearching{
            return 1
        }else{
            return ConversationSectionNum
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearching{
            return searchResult.count
        }else{
            if section == 0 {
                return 1
            }else{
                return conversationService.conversations.count
            }
        }
    }
    
    fileprivate func searchingTableView(_ tableView: UITableView, indexPath: IndexPath) -> ConversationListCellBase{
        let lc = tableView.dequeueReusableCell(withIdentifier: ConversationListCell.reuseId, for: indexPath) as! ConversationListCell
        lc.subLineLabel.morphingEnabled = tableViewEndDecelerating
        let sr = searchResult[indexPath.row]
        lc.rootController = self
        lc.conversationListCellHandler = handleSearchResult
        lc.originModel = sr
        return lc
    }
    
    fileprivate func normalTableView(_ tableView: UITableView, indexPath: IndexPath) -> ConversationListCellBase{
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: NavItemCell.reuseId, for: indexPath) as! NavItemCell
            cell.rootController = self
            return cell
        }
        else{
            let lc = tableView.dequeueReusableCell(withIdentifier: ConversationListCell.reuseId, for: indexPath) as! ConversationListCell
            lc.subLineLabel.morphingEnabled = tableViewEndDecelerating
            let conversation = conversationService.conversations[indexPath.row]
            lc.rootController = self
            lc.conversationListCellHandler = handleConversationListCellItem
            lc.originModel = conversation
            if conversationService.conversations.count > 10 {
                lc.subLineLabel.morphingEnabled = false
            }
            return lc
        }
    }
    
    fileprivate var tableViewEndDecelerating = true
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        tableViewEndDecelerating = false
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        tableViewEndDecelerating = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!
        if isSearching{
            cell = searchingTableView(tableView, indexPath: indexPath)
        }else{
            cell = normalTableView(tableView, indexPath: indexPath)
        }
        cell.isSelected = false
        cell.setSeparatorFullWidth()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ConversationListCellBase{
            cell.isSelected = false
            cell.onCellClicked()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching {
            return 60
        }
        
        if indexPath.section == ConversationListController.navItemSection {
            return 100
        }
        return 60
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case ConversationListController.navItemSection:
            return 0
        default:
            return 11
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if isSearching == false && indexPath.section == ConversationListController.conversationSection{
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if isSearching == false && indexPath.section == ConversationListController.conversationSection{
            
            if let cell = tableView.cellForRow(at: indexPath) as? ConversationListCell{
                if let conversation = cell.originModel as? Conversation{
                    let acRemove = UITableViewRowAction(style: .default, title: "REMOVE".localizedString(), handler: { (ac, indexPath) -> Void in
                        self.removeConversation(conversation.conversationId,message: cell.headLineLabel.text)
                    })
                    
                    var acPin:UITableViewRowAction? = nil
                    if conversation.pinned {
                        acPin = UITableViewRowAction(style: .default, title: "UNPIN".localizedString(), handler: { (ac, indexPath) in
                            if self.conversationService.unpinConversation(conversation){
                                SystemSoundHelper.keyTock()
                                tableView.reloadRows(at: [indexPath], with: .right)
                            }
                        })
                    }else{
                        acPin = UITableViewRowAction(style: .default, title: "PIN".localizedString(), handler: { (ac, indexPath) in
                            
                            if self.conversationService.pinConversation(conversation){
                                SystemSoundHelper.keyTink()
                                tableView.reloadRows(at: [indexPath], with: .right)
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
}

//MARK: handle click list cell
private let defaultNearActiveConversationBeforeRemoveTs:Int64 = ConversationMaxTimeUpMS//1000 * 60 * 60
private var openConversationBeforeRemoveTs:Int64 = ConversationMaxTimeUpMS
private var openConversationActivityId:String? = nil

extension ConversationListController:UserProfileViewControllerDismissedDelegate{
    
    func userProfileViewControllerDismissed(_ sender: UserProfileViewController) {
        MainTabBarController.instance?.tabBar.isHidden = false
    }
    
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonClicked profile: VessageUser) {
        if let userId = profile.userId{
            let beforeRemoveTs = openConversationBeforeRemoveTs
            openConversationBeforeRemoveTs = ConversationMaxTimeUpMS
            let acId = openConversationActivityId
            openConversationActivityId = nil
            sender.dismiss(animated: true, completion: {
                MainTabBarController.instance?.tabBar.isHidden = false
                ConversationViewController.showConversationViewController(self.navigationController!, userId : userId,beforeRemoveTs: beforeRemoveTs,createByActivityId: acId)
            })
        }
    }
    
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonTitle profile: VessageUser) -> String {
        if profile.t == VessageUser.typeSubscription {
            return "SUBSCRIPT".localizedString()
        }
        return "CHAT".localizedString()
    }
    
    func handleSearchResult(_ cell:ConversationListCell){
        isSearching = false
        if let result = cell.originModel as? SearchResultModel{
            MobClick.event("Vege_OpenSearchResultConversation")
            if let c = result.conversation{
                ConversationViewController.showConversationViewController(self.navigationController!, conversation: c)
            }else if let u = result.user{
                
                var snsButtonEnabled = true
                var accountIdHidden = false
                
                if result.type == .userActive ||
                    result.type == .userActiveNear ||
                    result.type == .userNear{
                    openConversationActivityId = VGActivityNearActivityId
                    openConversationBeforeRemoveTs = defaultNearActiveConversationBeforeRemoveTs
                    snsButtonEnabled = false
                    accountIdHidden = true
                }else{
                    openConversationBeforeRemoveTs = ConversationMaxTimeUpMS
                    openConversationActivityId = nil
                }
                
                UserProfileViewController.showUserProfileViewController(self, userId: u.userId, delegate: self){ profileVC in
                    MainTabBarController.instance?.tabBar.isHidden = true
                    profileVC.accountIdHidden = accountIdHidden
                    profileVC.snsButtonEnabled = snsButtonEnabled
                }
            }else if let mobile = result.mobile{
                MobClick.event("Vege_OpenSearchResultMobileConversation")
                openConversationWithMobile(mobile, noteName: result.mobile ?? result.keyword)
            }
        }
    }
    
    func openConversationWithMobile(_ mobile:String,noteName:String?) {
        if let user = self.userService.getCachedUserByMobile(mobile){
            ConversationViewController.showConversationViewController(self.navigationController!, userId: user.userId)
        }else{
            let hud = self.showAnimationHud()
            self.userService.fetchUserProfileByMobile(mobile, lastUpdatedTime: nil, updatedCallback: { (user) in
                hud.hide(animated: true)
                if let u = user{
                    
                    openConversationBeforeRemoveTs = ConversationMaxTimeUpMS
                    openConversationActivityId = nil
                    UserProfileViewController.showUserProfileViewController(self, userProfile: u, delegate: self)
                    MainTabBarController.instance?.tabBar.isHidden = true
                    
                }else{
                    let title = "NO_USER_OF_MOBILE".localizedString()
                    let msg = String(format: "MOBILE_X_INVITE_JOIN_VG".localizedString(), mobile)
                    let invite = UIAlertAction(title: "INVITE".localizedString(), style: .default, handler: { (ac) in
                        ShareHelper.instance.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString(),copyLink: true)
                    })
                    
                    self.showAlert(title, msg: msg,actions: [ALERT_ACTION_CANCEL,invite])
                }
            })
        }
    }
}

//MARK: Flash Tips
extension ConversationListController{
    
    func flashTips(_ msg:String) {
        self.flashTipsView.flashTips(self.view, msg: msg, center: CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height - 160),textColor: UIColor.white)
    }
    
}
