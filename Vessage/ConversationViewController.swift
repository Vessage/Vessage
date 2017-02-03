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
    private var needSetChatImageIfNotExists = true
    
    private var isNotRegistFriend = false
    
    var isGroupChat:Bool{
        return conversation.isGroupChat
    }
    
    private(set) var outterNewVessageCount:Int = 0{
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
    
    private(set) var conversation:Conversation!
    
    private var defaultOtherChatterId:String?{
        return (self.chatGroup?.chatters?.filter{$0 != UserSetting.userId})?.first
    }
    
    private(set) var chatGroup:ChatGroup!{
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
    
    private(set) var outChatGroup = true
    
    var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    let conversationService = ServiceContainer.getConversationService()
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getService(FileService)
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
    private var flashTipsView:FlashTipsLabel = {
        return FlashTipsLabel()
    }()
    
    private var baseVessageBodyDict:[String:AnyObject]{
        let dict = [String:AnyObject]()
        return dict
    }
    
    func getSendVessageBodyString(values:[String:AnyObject?],withBaseDict:Bool = true) -> String? {
        var bodyDict = withBaseDict ? baseVessageBodyDict : [String:AnyObject]()
        values.forEach { (key,value) in
            if let v = value{
                bodyDict.updateValue(v, forKey: key)
            }
        }
        let json = try! NSJSONSerialization.dataWithJSONObject(bodyDict, options: NSJSONWritingOptions(rawValue: 0))
        return String(data: json, encoding: NSUTF8StringEncoding)
    }
    
    var textChatInputView:TextChatInputView!
    var textChatInputResponderTextFiled:UITextField!
    
    private var initMessage:[String:AnyObject]!
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
}

extension ConversationViewController{
    func onKeyBoardShown(a:NSNotification) {
        let rect = self.view.convertRect(self.textChatInputView.sendButton.frame, fromView: self.textChatInputView)
        
        let constant = self.view.frame.height - rect.origin.y - self.textChatInputView.frame.height + 10
        self.vessageViewContainer.constraints.filter{$0.identifier == "messageListBottom"}.first?.constant = constant
        self.messageList.updateConstraintsIfNeeded()
    }
    
    func onKeyboardHidden(a:NSNotification) {
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: isGroupChat ? "user_group":"userInfo"), style: .Plain, target: self, action: #selector(ConversationViewController.clickRightBarItem(_:)))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.themeColor
        outterNewVessageCount = 0
        resetTitle()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        BahamutCmdManager.sharedInstance.registHandler(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        BahamutCmdManager.sharedInstance.removeHandler(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.onKeyboardHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ConversationViewController.onKeyBoardShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationViewController.onAppResignActive(_:)), name: AppService.onAppResignActive, object: nil)
        handleInitMessage()
        messageListLoadMessages()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func handleInitMessage(){
        if let t = initMessage?["input_text"] as? String{
            if tryShowTextChatInputView(){
                textChatInputView.inputTextField.insertText(t)
            }
        }
        initMessage = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if !(self.navigationController?.viewControllers.contains(self) ?? false) {
            releaseController()
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
        ServiceContainer.getAppService().removeObserver(self)
    }
    
    private func releaseController(){
        self.removeObservers()
        self.conversation = nil
        self.chatGroup = nil
        self.timeMachineListController = nil
        removeReadedVessages()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

//MARK: Actions
extension ConversationViewController{
    
    func onBackItemClick(sender:AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func clickRightBarItem(sender: AnyObject) {
        if outChatGroup {
            self.flashTips("NOT_IN_CHAT_GROUP".localizedString())
        }else if isGroupChat {
            showChatGroupProfile()
        }else{
            showChatterProfile()
        }
    }
    
    
    
    private func showChatGroupProfile(){
        ChatGroupProfileViewController.showProfileViewController(self.navigationController!, chatGroup: self.chatGroup)
    }
    
    private func showChatterProfile(){
        if let c = defaultOtherChatterId{
            if let user = userService.getCachedUserProfile(c) {
                let controller = userService.showUserProfile(self, user: user)
                controller.accountIdHidden = !String.isNullOrWhiteSpace(conversation?.acId)
                return
            }
        }
        self.playToast("USER_DATA_NOT_READY_RETRY".localizedString())
    }
    
}

//MARK: Observer & Notifications
extension ConversationViewController{
    
    private func addObservers(){
        userService.addObserver(self, selector: #selector(ConversationViewController.onUserNoteNameUpdated(_:)), name: UserService.userNoteNameUpdated, object: nil)
        userService.addObserver(self, selector: #selector(ConversationViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationViewController.onNewVessagesReveiced(_:)), name: VessageService.onNewVessagesReceived, object: nil)
        
        chatGroupService.addObserver(self, selector: #selector(ConversationViewController.onChatGroupUpdated(_:)), name: ChatGroupService.OnChatGroupUpdated, object: nil)
        addSendVessageObservers()
    }
    
    private func removeObservers(){
        userService.removeObserver(self)
        vessageService.removeObserver(self)
        chatGroupService.removeObserver(self)
        removeSendVessageObservers()
    }
    
    func onAppResignActive(_:AnyObject?) {
        hideKeyBoard()
    }
    
    func onUserNoteNameUpdated(a:NSNotification) {
        if let userId = a.userInfo?[UserProfileUpdatedUserIdValue] as? String{
            if userId == self.conversation.chatterId {
                if let note = a.userInfo?[UserNoteNameUpdatedValue] as? String{
                    self.controllerTitle = note
                }
            }
        }
    }
    
    func onQuitChatGroup(a:NSNotification) {
        if let group = a.userInfo?[kChatGroupValue] as? ChatGroup{
            if isGroupChat && group.groupId == self.chatGroup.groupId {
                outChatGroup = true
            }
        }
    }
    
    func onChatGroupUpdated(a:NSNotification){
        if let group = a.userInfo?[kChatGroupValue] as? ChatGroup{
            if isGroupChat && group.groupId == self.chatGroup.groupId {
                self.chatGroup = group
                resetTitle()
            }
        }
    }
    
    func onUserProfileUpdated(a:NSNotification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if let chatterids = self.chatGroup?.chatters{
                if chatterids.contains(chatter.userId) {
                    self.userDict[chatter.userId] = chatter
                }
            }
        }
    }
    
    func onNewVessagesReveiced(a:NSNotification){
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
    
    func onNewVessagePushed(a:NSNotification) {
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation.chatterId {
                if let vsg = task.vessage {
                    let newVsg = vsg.copyToObject(Vessage.self)
                    if vsg.isMySendingVessage() {
                        newVsg.fileId = task.filePath
                    }
                    messagesListPushReceivedMessages([newVsg])
                }
            }
            
        }
    }
    
    func onVessageSending(a:NSNotification){
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation?.chatterId {
                if let persent = a.userInfo?[kBahamutQueueTaskProgressValue] as? Float{
                    self.progressView.hidden = false
                    self.progressView.setProgress(persent, animated: true)
                }
            }
        }
    }
    
    func onVessageSendError(a:NSNotification){
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation?.chatterId {
                self.progressView.hidden = true
                self.controllerTitle = "VESSAGE_SEND_FAIL".localizedString()
                if let msg = a.userInfo?[kBahamutQueueTaskMessageValue] as? String{
                    retrySendTask(task, errorMessage: msg)
                }
            }
        }
    }
    
    private func retrySendTask(task:SendVessageQueueTask,errorMessage:String){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.controllerTitle = "VESSAGE_SENDING".localizedString()
            VessageQueue.sharedInstance.startTask(task)
        }
        let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (action) -> Void in
            VessageQueue.sharedInstance.cancelTask(task, message: "USER_CANCELED")
            self.playCrossMark("CANCEL".localizedString())
        }
        self.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: errorMessage.localizedString(), actions: [okAction,cancelAction])
    }
    
    func onVessageSended(a:NSNotification){
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation?.chatterId {
                self.controllerTitle = "VESSAGE_SENDED".localizedString()
                NSTimer.scheduledTimerWithTimeInterval(2.3, target: self, selector: #selector(ConversationViewController.resetTitle(_:)), userInfo: nil, repeats: false)
                if isNotRegistFriend{
                    self.showSendTellFriendAlert()
                }
            }
        }
    }
    
    func resetTitle(_:AnyObject? = nil) {
        if let con = self.conversation {
            self.progressView.hidden = true
            if isGroupChat {
                self.controllerTitle = chatGroup.groupName
            }else{
                self.controllerTitle = userService.getUserNotedName(con.chatterId)
            }
        }
    }
    
    func setProgressSending() {
        dispatch_async(dispatch_get_main_queue()) {
            self.progressView.progress = 0.1
            self.progressView.hidden = false
            self.controllerTitle = "VESSAGE_SENDING".localizedString()
        }
    }
    
    private func showSendTellFriendAlert(){
        if let userId = defaultOtherChatterId{
            let send = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) -> Void in
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
    
    static func showConversationViewController(nvc:UINavigationController,userId: String,beforeRemoveTs:Int64 = ConversationMaxTimeUpMS,createByActivityId:String? = nil,initMessage:[String:AnyObject]? = nil) {
        if userId == UserSetting.userId {
            nvc.playToast("CANT_CHAT_WITH_YOURSELF".localizedString())
        }else{
            let conversation = ServiceContainer.getConversationService().openConversationByUserId(userId,beforeRemoveTs: beforeRemoveTs,createByActivityId: createByActivityId)
            ConversationViewController.showConversationViewController(nvc, conversation: conversation, initMessage: initMessage)
        }
    }
    
    static func showConversationViewController(nvc:UINavigationController,conversation:Conversation,initMessage:[String:AnyObject]? = nil)
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
                        hud.hideAnimated(true)
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
                        hud.hideAnimated(true)
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
    
    private static func showConversationView(nvc:UINavigationController,conversation:Conversation,group:ChatGroup,refreshGroup:Bool,initMessage:[String:AnyObject]?){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversation = conversation
        controller.chatGroup = group
        controller.initMessage = initMessage
        nvc.pushViewController(controller, animated: true)
        if refreshGroup {
            ServiceContainer.getChatGroupService().fetchChatGroup(group.groupId)
        }
    }
    
    private static func showConversationView(nvc:UINavigationController,conversation:Conversation,user:VessageUser,refreshUser:Bool,initMessage:[String:AnyObject]?){
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
    
    func flashTips(msg:String) {
        let center = CGPointMake(self.vessageViewContainer.frame.width / 2,self.vessageViewContainer.frame.height / 2)
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
    func handleBahamutCmd(method: String, args: [String], object: AnyObject?) {
        
    }
}
