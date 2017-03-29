//
//  ViewController.swift
//  SeeYou
//
//  Created by AlexChow on 16/2/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: ConversationViewController
class ConversationViewController: UIViewController {
    
    //MARK: Properties
    fileprivate var needSetChatImageIfNotExists = true
    
    fileprivate var isNotRegistFriend = false
    
    var isGroupChat:Bool{
        return conversation.isGroupChat
    }
    
    fileprivate(set) var outterNewVessageCount:Int = 0{
        didSet{
            let backBtn = UIBarButtonItem()
            var title = "\(VessageConfig.appName)"
            if outterNewVessageCount > 99 {
                title = "\(title)(99+)"
            }else if outterNewVessageCount > 0 {
                title = "\(title)(\(outterNewVessageCount))"
            }
            backBtn.title = title
            self.navigationController?.navigationBar.backItem?.backBarButtonItem = backBtn
        }
    }
    
    fileprivate(set) var conversation:Conversation!{
        didSet{
            if let c = conversation {
                isActivityConversation = !String.isNullOrEmpty(c.acId)
            }
        }
    }
    
    fileprivate var isActivityConversation = false
    
    fileprivate var defaultOtherChatterId:String?{
        return (self.chatGroup?.chatters?.filter{$0 != UserSetting.userId})?.first
    }
    
    fileprivate(set) var chatGroup:ChatGroup!{
        didSet{
            if let _ = chatGroup {
                outChatGroup = !chatGroup.chatters.contains(UserSetting.userId)
                if !outChatGroup {
                    refreshUserDict()
                }
            }else{
                outChatGroup = false
            }
        }
    }
    
    fileprivate(set) var outChatGroup = true
    
    var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    let conversationService = ServiceContainer.getConversationService()
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getFileService()
    let vessageService = ServiceContainer.getVessageService()
    let chatGroupService = ServiceContainer.getChatGroupService()
    
    var vessages = [Vessage]()
    var userDict = [String:VessageUser]()
    
    var timeMachineListController:TimeMachineVessageListController?
    
    @IBOutlet weak var messageList: UITableView!
    
    @IBOutlet weak var sendImageButton: UIButton!
    @IBOutlet weak var sendFaceTextButton: UIButton!
    @IBOutlet weak var timemachineButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var vessageViewContainer: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    //MARK: flash tips properties
    fileprivate var flashTipsView:FlashTipsLabel = {
        return FlashTipsLabel()
    }()
    
    fileprivate var baseVessageBodyDict:[String:AnyObject]{
        let dict = [String:AnyObject]()
        return dict
    }
    
    func getSendVessageBodyString(_ values:[String:Any?],withBaseDict:Bool = true) -> String? {
        var bodyDict = withBaseDict ? baseVessageBodyDict : [String:Any]()
        values.forEach { (key,value) in
            if let v = value{
                bodyDict[key] = v
            }
        }
        let json = try! JSONSerialization.data(withJSONObject: bodyDict, options: JSONSerialization.WritingOptions(rawValue: 0))
        return String(data: json, encoding: String.Encoding.utf8)
    }
    
    var textChatInputView:TextChatInputView!
    var textChatInputResponderTextFiled:UITextField!
    
    fileprivate var initMessage:[String:Any]!
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
}

extension ConversationViewController{
    func onKeyBoardShown(_ a:Notification) {
        let rect = self.view.convert(self.textChatInputView.sendButton.frame, from: self.textChatInputView)
        
        let constant = self.view.frame.height - rect.origin.y - self.textChatInputView.frame.height + 10
        self.vessageViewContainer.constraints.filter{$0.identifier == "messageListBottom"}.first?.constant = constant
        self.messageList.updateConstraintsIfNeeded()
    }
    
    func onKeyboardHidden(_ a:Notification) {
        self.hideKeyBoard()
        self.vessageViewContainer.constraints.filter{$0.identifier == "messageListBottom"}.first?.constant = 0
    }
}

//MARK: Life Circle
extension ConversationViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.backgroundImage.image = getRandomConversationBackground()
        initChatImageButton()
        initSendImage()
        initTimeMachine()
        initMessageList()
        
        addObservers()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: isGroupChat ? "user_group":"userInfo"), style: .plain, target: self, action: #selector(ConversationViewController.clickRightBarItem(_:)))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.themeColor
        outterNewVessageCount = 0
        resetTitle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BahamutCmdManager.sharedInstance.registHandler(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BahamutCmdManager.sharedInstance.removeHandler(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.onKeyboardHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(ConversationViewController.onKeyBoardShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationViewController.onAppResignActive(_:)), name: AppService.onAppResignActive, object: nil)
        handleInitMessage()
        messageListLoadMessages()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    fileprivate func handleInitMessage(){
        if let t = initMessage?["input_text"] as? String{
            if tryShowTextChatInputView(){
                textChatInputView.inputTextField.insertText(t)
            }
        }
        initMessage = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !(self.navigationController?.viewControllers.contains(self) ?? false) {
            releaseController()
        }
        NotificationCenter.default.removeObserver(self)
        ServiceContainer.getAppService().removeObserver(self)
    }
    
    fileprivate func releaseController(){
        self.removeObservers()
        self.conversation = nil
        self.chatGroup = nil
        self.timeMachineListController = nil
        removeReadedVessages()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

//MARK: Actions
extension ConversationViewController{
    
    func onBackItemClick(_ sender:AnyObject) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func clickRightBarItem(_ sender: AnyObject) {
        if outChatGroup {
            self.flashTips("NOT_IN_CHAT_GROUP".localizedString())
        }else if isGroupChat {
            showChatGroupProfile()
        }else{
            showChatterProfile()
        }
    }
    
    
    
    fileprivate func showChatGroupProfile(){
        ChatGroupProfileViewController.showProfileViewController(self.navigationController!, chatGroup: self.chatGroup)
    }
    
    fileprivate func showChatterProfile(){
        if let c = defaultOtherChatterId{
            if let user = userService.getCachedUserProfile(c) {
                let controller = userService.showUserProfile(self, user: user)
                controller.accountIdHidden = !String.isNullOrWhiteSpace(conversation?.acId)
                controller.snsButtonEnabled = !controller.accountIdHidden
                return
            }
        }
        self.playToast("USER_DATA_NOT_READY_RETRY".localizedString())
    }
    
}

//MARK: Observer & Notifications
extension ConversationViewController{
    
    fileprivate func addObservers(){
        userService.addObserver(self, selector: #selector(ConversationViewController.onUserNoteNameUpdated(_:)), name: UserService.userNoteNameUpdated, object: nil)
        userService.addObserver(self, selector: #selector(ConversationViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationViewController.onNewVessagesReveiced(_:)), name: VessageService.onNewVessagesReceived, object: nil)
        
        chatGroupService.addObserver(self, selector: #selector(ConversationViewController.onChatGroupUpdated(_:)), name: ChatGroupService.OnChatGroupUpdated, object: nil)
        addSendVessageObservers()
    }
    
    fileprivate func removeObservers(){
        userService.removeObserver(self)
        vessageService.removeObserver(self)
        chatGroupService.removeObserver(self)
        removeSendVessageObservers()
    }
    
    func onAppResignActive(_:AnyObject?) {
        hideKeyBoard()
    }
    
    func onUserNoteNameUpdated(_ a:Notification) {
        if let userId = a.userInfo?[UserProfileUpdatedUserIdValue] as? String{
            if userId == self.conversation.chatterId {
                if let note = a.userInfo?[UserNoteNameUpdatedValue] as? String{
                    self.controllerTitle = note
                }
            }
        }
    }
    
    func onQuitChatGroup(_ a:Notification) {
        if let group = a.userInfo?[kChatGroupValue] as? ChatGroup{
            if isGroupChat && group.groupId == self.chatGroup.groupId {
                outChatGroup = true
            }
        }
    }
    
    func onChatGroupUpdated(_ a:Notification){
        if let group = a.userInfo?[kChatGroupValue] as? ChatGroup{
            if isGroupChat && group.groupId == self.chatGroup.groupId {
                self.chatGroup = group
                resetTitle()
            }
        }
    }
    
    func onUserProfileUpdated(_ a:Notification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if let chatterids = self.chatGroup?.chatters{
                if chatterids.contains(chatter.userId) {
                    self.userDict[chatter.userId] = chatter
                }
            }
        }
    }
    
    func onNewVessagesReveiced(_ a:Notification){
        var otherConversationVessageCount = 0
        var received = [Vessage]()
        
        if let msgs = a.userInfo?[VessageServiceNotificationValues] as? [Vessage]{
            msgs.forEach({ (msg) in
                if msg.sender == self.conversation?.chatterId{
                    received.append(msg)
                }else{
                    otherConversationVessageCount += 1
                }
            })
        }
        if received.count > 0 {
            if isActivityConversation {
                let vsg = generateTipsVessage("TO_BE_NORMAL_CONVERSATION".localizedString())
                received.insert(vsg, at: 1)
                isActivityConversation = false
            }
            messagesListPushReceivedMessages(received)
        }
        outterNewVessageCount += otherConversationVessageCount
    }
}


extension ConversationViewController{
    func refreshUserDict() {
        var noReadyUsers = [String]()
        let chatters = self.chatGroup.chatters.map { (userId) -> VessageUser in
            if let u = self.userService.getCachedUserProfile(userId){
                return u
            }else{
                noReadyUsers.append(userId)
                let u = VessageUser()
                u.userId = userId
                return u
            }
        }
        for u in chatters {
            userDict[u.userId] = u
        }
        userService.fetchUserProfilesByUserIds(noReadyUsers, callback: nil)
    }
}

//MARK: Send Vessage Status
extension ConversationViewController{
    
    func addSendVessageObservers() {
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationViewController.onVessageSending(_:)), name: VessageQueue.onTaskProgress, object: nil)
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationViewController.onVessageSendError(_:)), name: VessageQueue.onTaskStepError, object: nil)
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationViewController.onVessageSended(_:)), name: VessageQueue.onTaskFinished, object: nil)
        
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationViewController.onNewVessagePushed(_:)), name: VessageQueue.onPushNewVessageTask, object: nil)
    }
    
    func removeSendVessageObservers() {
        VessageQueue.sharedInstance.removeObserver(self)
    }
    
    func onNewVessagePushed(_ a:Notification) {
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation.chatterId {
                if let vsg = task.vessage {
                    let newVsg = vsg.copyToObject(Vessage.self)
                    messagesListPushReceivedMessages([newVsg])
                }
            }
            
        }
    }
    
    func onVessageSending(_ a:Notification){
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation?.chatterId {
                if let persent = a.userInfo?[kBahamutQueueTaskProgressValue] as? Float{
                    self.progressView.isHidden = false
                    self.progressView.setProgress(persent, animated: true)
                }
            }
        }
    }
    
    func onVessageSendError(_ a:Notification){
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation?.chatterId {
                self.progressView.isHidden = true
                self.controllerTitle = "VESSAGE_SEND_FAIL".localizedString()
                if let msg = a.userInfo?[kBahamutQueueTaskMessageValue] as? String{
                    retrySendTask(task, errorMessage: msg)
                }
            }
        }
    }
    
    fileprivate func retrySendTask(_ task:SendVessageQueueTask,errorMessage:String){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .default) { (action) -> Void in
            self.controllerTitle = "VESSAGE_SENDING".localizedString()
            VessageQueue.sharedInstance.startTask(task)
        }
        let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .cancel) { (action) -> Void in
            VessageQueue.sharedInstance.cancelTask(task, message: "USER_CANCELED")
            self.playCrossMark("CANCEL".localizedString())
        }
        self.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: errorMessage.localizedString(), actions: [okAction,cancelAction])
    }
    
    func onVessageSended(_ a:Notification){
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation?.chatterId {
                self.controllerTitle = "VESSAGE_SENDED".localizedString()
                Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(ConversationViewController.resetTitle(_:)), userInfo: nil, repeats: false)
                if isNotRegistFriend{
                    self.showSendTellFriendAlert()
                }
            }
        }
    }
    
    func resetTitle(_:AnyObject? = nil) {
        if let con = self.conversation {
            self.progressView.isHidden = true
            if isGroupChat {
                self.controllerTitle = chatGroup.groupName
            }else{
                self.controllerTitle = userService.getUserNotedName(con.chatterId)
            }
        }
    }
    
    func setProgressSending() {
        DispatchQueue.main.async {
            self.progressView.progress = 0.1
            self.progressView.isHidden = false
            self.controllerTitle = "VESSAGE_SENDING".localizedString()
        }
    }
    
    fileprivate func showSendTellFriendAlert(){
        if let userId = defaultOtherChatterId{
            let send = UIAlertAction(title: "OK".localizedString(), style: .default, handler: { (ac) -> Void in
                let contentText = String(format: "NOTIFY_SMS_FORMAT".localizedString(),"")
                ShareHelper.instance.showTellTextMsgToFriendsAlert(self, content: contentText)
            })
            let name = ServiceContainer.getUserService().getUserNotedName(userId)
            self.showAlert("SEND_NOTIFY_SMS_TO_FRIEND".localizedString(), msg: name, actions: [send])
        }
    }
}

//MARK: Show ConversationViewController Extension
extension ConversationViewController{
    
    static func showConversationViewController(_ nvc:UINavigationController,userId: String,beforeRemoveTs:Int64 = ConversationMaxTimeUpMS,createByActivityId:String? = nil,initMessage:[String:Any]? = nil) {
        if userId == UserSetting.userId {
            nvc.playToast("CANT_CHAT_WITH_YOURSELF".localizedString())
        }else if let user = ServiceContainer.getUserService().getCachedUserProfile(userId){
            let t = user.t == VessageUser.typeSubscription ? Conversation.typeSubscription : Conversation.typeSingleChat
            let c = ServiceContainer.getConversationService().openConversationByUserId(user.userId, beforeRemoveTs: beforeRemoveTs, createByActivityId: createByActivityId, type: t)
            showConversationViewController(nvc, conversation: c,initMessage: initMessage)
        }else{
            ServiceContainer.getUserService().getUserProfile(userId, updatedCallback: { (user) in
                if let u = user{
                    let t = u.t == VessageUser.typeSubscription ? Conversation.typeSubscription : Conversation.typeSingleChat
                    let c = ServiceContainer.getConversationService().openConversationByUserId(u.userId, beforeRemoveTs: beforeRemoveTs, createByActivityId: createByActivityId, type: t)
                    showConversationViewController(nvc, conversation: c,initMessage: initMessage)
                }else{
                    nvc.showAlert("USER_DATA_NOT_READY_RETRY".localizedString(), msg: nil)
                }
            })
        }
    }
    
    static func showConversationViewController(_ nvc:UINavigationController,conversation:Conversation,initMessage:[String:Any]? = nil)
    {
        if String.isNullOrEmpty(conversation.chatterId) {
            nvc.playToast("NO_SUCH_USER".localizedString())
        }else{
            if conversation.isGroupChat {
                if let group = ServiceContainer.getChatGroupService().getChatGroup(conversation.chatterId){
                    showConversationView(nvc, conversation: conversation, group: group,refreshGroup: true, initMessage: initMessage)
                }else{
                    let hud = nvc.showAnimationHud()
                    ServiceContainer.getChatGroupService().fetchChatGroup(conversation.chatterId){ group in
                        hud.hide(animated: true)
                        if let g = group{
                            self.showConversationView(nvc, conversation: conversation, group: g,refreshGroup: false,initMessage: initMessage)
                        }else{
                            nvc.playToast("NO_SUCH_GROUP".localizedString())
                        }
                    }
                }
            }else{
                if let user = ServiceContainer.getUserService().getCachedUserProfile(conversation.chatterId){
                    showConversationView(nvc,conversation: conversation,user: user,refreshUser: true, initMessage: initMessage)
                }else{
                    let hud = nvc.showAnimationHud()
                    ServiceContainer.getUserService().getUserProfile(conversation.chatterId, updatedCallback: { (u) in
                        hud.hide(animated: true)
                        if let updatedUser = u{
                            showConversationView(nvc,conversation: conversation,user: updatedUser,refreshUser: false,initMessage: initMessage)
                        }else{
                            nvc.playToast("NO_SUCH_USER".localizedString())
                        }
                    })
                }
            }
        }
        
    }
    
    fileprivate static func showConversationView(_ nvc:UINavigationController,conversation:Conversation,group:ChatGroup,refreshGroup:Bool,initMessage:[String:Any]?){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversation = conversation
        controller.chatGroup = group
        controller.initMessage = initMessage
        nvc.pushViewController(controller, animated: true)
        if refreshGroup {
            ServiceContainer.getChatGroupService().fetchChatGroup(group.groupId)
        }
    }
    
    fileprivate static func showConversationView(_ nvc:UINavigationController,conversation:Conversation,user:VessageUser,refreshUser:Bool,initMessage:[String:Any]?){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversation = conversation
        if String.isNullOrWhiteSpace(user.accountId){
            controller.isNotRegistFriend = true
        }
        
        let groupChat = ChatGroup()
        groupChat.chatters = [user.userId,UserSetting.userId]
        groupChat.groupId = user.userId
        groupChat.groupName = user.nickName
        groupChat.hosters = groupChat.chatters
        groupChat.inviteCode = user.userId
            
        controller.chatGroup = groupChat
        
        controller.initMessage = initMessage
        nvc.pushViewController(controller, animated: true)
        if refreshUser {
            ServiceContainer.getUserService().fetchLatestUserProfile(user)
        }
    }

}

//MARK: Flash Tips
extension ConversationViewController{
    
    func flashTips(_ msg:String) {
        let center = CGPoint(x: self.vessageViewContainer.frame.width / 2,y: self.vessageViewContainer.frame.height / 2)
        self.flashTipsView.flashTips(self.view, msg: msg, center: center)
    }
    
}


//MARK: animations
extension ConversationViewController{
    
    func playFaceTextButtonAnimation() {
        UIAnimationHelper.flashView(sendFaceTextButton, duration: 0.3, autoStop: true, stopAfterMs: 3000)
    }
}

//MARK:HandleBahamutCmdDelegate
extension ConversationViewController:HandleBahamutCmdDelegate{
    func handleBahamutCmd(_ method: String, args: [String], object: AnyObject?) {
        
    }
}
