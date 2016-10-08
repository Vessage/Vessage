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
    
    var isGroupChat:Bool{
        return chatGroup != nil
    }
    
    private(set) var outterNewVessageCount:Int = 0{
        didSet{
            if let backBtn = self.navigationController?.navigationBar.backItem?.backBarButtonItem {
                var title = "\(VessageConfig.appName)"
                if outterNewVessageCount > 99 {
                    title = "\(title)(99+)"
                }else if outterNewVessageCount > 0 {
                    title = "\(title)(\(outterNewVessageCount))"
                }
                backBtn.title = title
            }
        }
    }
    
    private(set) var conversation:Conversation!
    
    private(set) var chatter:VessageUser!{
        didSet{
            if let user = chatter{
                recordVessageManager?.onChatterUpdated(user)
                playVessageManager?.onChatterUpdated(user)
                chatGroup = nil
            }
        }
    }
    
    private(set) var chatGroup:ChatGroup!{
        didSet{
            if let cg = chatGroup {
                outChatGroup = !chatGroup.chatters.contains(userService.myProfile.userId)
                recordVessageManager?.onChatGroupUpdated(cg)
                playVessageManager?.onChatGroupUpdated(cg)
                chatter = nil
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
    
    private(set) var playVessageManager:PlayVessageManager!
    private(set) var recordVessageManager:RecordVessageManager!
    
    var currentManager:ConversationViewControllerProxy!
    
    let conversationService = ServiceContainer.getConversationService()
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getService(FileService)
    let vessageService = ServiceContainer.getVessageService()
    let chatGroupService = ServiceContainer.getChatGroupService()
    
    private(set) var isRecording:Bool = false
    var isReadingVessages:Bool{
        return !isRecording
    }
    
    @IBOutlet weak var nextVessageButton: UIButton!{
        didSet{
            nextVessageButton.hidden = true
        }
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var recordViewContainer: UIView!
    @IBOutlet weak var vessageViewContainer: UIView!
    
    @IBOutlet weak var middleButton: UIButton!
    
    @IBOutlet weak var bottomBar: UIView!{
        didSet{
            bottomBar.hidden = true
        }
    }
    @IBOutlet weak var bottomBarContainer: UIView!{
        didSet{
            bottomBarContainer.hidden = true
        }
    }
    @IBOutlet weak var rightButton: UIButton!{
        didSet{
            rightButton.hidden = true
        }
    }
    
    //MARK: Read Vessage Views
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.hidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
        }
    }
    
    @IBOutlet weak var conversationLeftTopLabel: UILabel!{
        didSet{
            conversationLeftTopLabel.text = nil
        }
    }
    @IBOutlet weak var conversationRightBottomLabel: UILabel!{
        didSet{
            conversationRightBottomLabel.text = nil
        }
    }
    @IBOutlet weak var vessageView: UIView!
    
    //MARK: Record Views
    @IBOutlet weak var previewRectView: VideoPreviewBubble!{
        didSet{
            previewRectView.backgroundColor = UIColor.clearColor()
        }
    }
    
    @IBOutlet weak var recordingProgress: KDCircularProgress!{
        didSet{
            recordingProgress.layoutIfNeeded()
            recordingProgress.hidden = true
        }
    }
    
    @IBOutlet weak var recordingFlashView: UIView!{
        didSet{
            recordingFlashView.layoutIfNeeded()
            recordingFlashView.layer.cornerRadius = recordingFlashView.frame.size.height / 2
            recordingFlashView.hidden = true
        }
    }
    
    @IBOutlet weak var noSmileFaceTipsLabel: UILabel!
    @IBOutlet weak var groupFaceContainer: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    
    var imageChatInputView:ImageChatInputView!
    var imageChatInputResponderTextFiled:UITextField!
    var chatImageBoardSourceView:UIView!
    var chatImageBoardController:ChatImageBoardController!
    var chatImageBoardShown = false
    var chatImageBoardShowing = false
    
    var hadChatImagesMgrControllerShown = false
    
    private var initMessage:[String:AnyObject]!
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }

}

//MARK: Life Circle
extension ConversationViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.backgroundImage.image = getRandomConversationBackground()
        initChatImageButton()
        playVessageManager = PlayVessageManager()
        playVessageManager.initManager(self)
        recordVessageManager = RecordVessageManager()
        recordVessageManager.initManager(self)
        addObservers()
        if let chatter = self.chatter{
            recordVessageManager.onChatterUpdated(chatter)
            playVessageManager.onChatterUpdated(chatter)
            ServiceContainer.getUserService().fetchLatestUserProfile(chatter)
        }else if let group = self.chatGroup{
            recordVessageManager.onChatGroupUpdated(group)
            playVessageManager.onChatGroupUpdated(group)
            ServiceContainer.getChatGroupService().fetchChatGroup(group.groupId){ updatedGroup in
                if let ug = updatedGroup{
                    ug.chatters.forEach({ (userId) in
                        ServiceContainer.getUserService().getUserProfile(userId)
                    })
                }
            }
        }
        setReadingVessage()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: isGroupChat ? "user_group":"userInfo"), style: .Plain, target: self, action: #selector(ConversationViewController.clickRightBarItem(_:)))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.themeColor
        outterNewVessageCount = 0
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipeLeft(_:)))
        swipeLeft.direction = .Left
        self.view.addGestureRecognizer(swipeLeft)
        self.nextVessageButton.hidden = true
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(ConversationViewController.onPanGesture(_:)))
        panGes.requireGestureRecognizerToFail(swipeLeft)
        self.view.addGestureRecognizer(panGes)
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
        showBottomBar()
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationViewController.onAppResignActive(_:)), name: AppService.onAppResignActive, object: nil)
        handleInitMessage()
    }
    
    private func handleInitMessage(){
        if let t = initMessage?["input_text"] as? String{
            if tryShowImageChatInputView(){
                imageChatInputView.inputTextField.insertText(t)
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
        self.recordVessageManager.onReleaseManager()
        self.playVessageManager.onReleaseManager()
        self.playVessageManager = nil
        self.recordVessageManager = nil
        self.conversation = nil
        self.chatter = nil
        self.chatGroup = nil
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

//MARK: Actions
extension ConversationViewController{
    
    func onPanGesture(a:UIPanGestureRecognizer) {
        let v = a.velocityInView(self.view)
        currentManager?.onPanGesture(v)
    }
    
    func onSwipeLeft(_:UIGestureRecognizer) {
        onClickNextButton(self.nextVessageButton)
    }
    
    func onBackItemClick(sender:AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func onClickMiddleButton(sender: UIView) {
        
        self.view.userInteractionEnabled = false
        sender.animationMaxToMin(0.1, maxScale: 1.2) { 
            if self.outChatGroup {
                self.playToast("NOT_IN_CHAT_GROUP".localizedString())
            }else if self.isReadingVessages {
                if self.needSetChatBackgroundAndShow() {
                    self.view.userInteractionEnabled = true
                    return
                }
                self.startRecording()
            }else{
                self.setReadingVessage()
                self.recordVessageManager.sendVessage()
            }
        }
        self.view.userInteractionEnabled = true
    }
    
    func clickRightBarItem(sender: AnyObject) {
        if outChatGroup {
            self.playToast("NOT_IN_CHAT_GROUP".localizedString())
            return
        }
        if isGroupChat {
            showChatGroupProfile()
        }else{
            showChatterProfile()
        }
    }
    
    @IBAction func onClickRightButton(sender: UIView) {
        if self.isReadingVessages {
            sender.animationMaxToMin(0.1, maxScale: 1.2) {
                self.tryShowImageChatInputView()
            }
        }else{
            self.recordVessageManager.cancelRecord()
            self.setReadingVessage()
        }
        
    }
    
    @IBAction func onClickNextButton(sender: UIView) {
        if self.isReadingVessages{
            if playVessageManager.haveNextVessage {
                sender.animationMaxToMin(0.1, maxScale: 1.2) {
                    self.playVessageManager.showNextVessage()
                }
            }else if playVessageManager.isPresentingVessage{
                self.playVessageManager.flashTips("THE_LAST_NOT_READ_VESSAGE".localizedString())
            }else{
                self.playVideoChatButtonAnimation()
                self.playFaceTextButtonAnimation()
            }
        }
    }
    
    private func showChatGroupProfile(){
        ChatGroupProfileViewController.showProfileViewController(self.navigationController!, chatGroup: self.chatGroup)
    }
    
    private func showChatterProfile(){
        if let c = self.chatter{
            userService.showUserProfile(self, user: c)
        }else{
            self.playToast("USER_DATA_NOT_READY_RETRY".localizedString())
        }
    }
    
    private func startRecording() {
        isRecording = true
        vessageViewContainer.hidden = true
        recordViewContainer.hidden = false
        recordViewContainer.alpha = 0.3
        bottomBar.alpha = 1
        UIView.beginAnimations("RecordViewContainer", context: nil)
        UIView.setAnimationDuration(0.3)
        recordViewContainer.alpha = 1
        bottomBar.alpha = 0
        UIView.commitAnimations()
        navigationController?.navigationBarHidden = true
        recordVessageManager.onSwitchToManager()
        recordVessageManager.startRecord()
    }
    
    func setReadingVessage() {
        isRecording = false
        recordViewContainer.hidden = true
        vessageViewContainer.hidden = false
        bottomBar.alpha = 1
        navigationController?.navigationBarHidden = false
        playVessageManager.onSwitchToManager()
    }
    
    private func showBottomBar(){
        if(bottomBarContainer.hidden){
            let layerOriginFrame = bottomBarContainer.layer.frame
            bottomBarContainer.layer.frame = CGRectMake(layerOriginFrame.origin.x, layerOriginFrame.origin.y + layerOriginFrame.height, layerOriginFrame.width, layerOriginFrame.height)
            bottomBarContainer.hidden = false
            bottomBarContainer.alpha = 0.1
            bottomBar.hidden = false
            let barLayerOriginFrame = bottomBar.layer.frame
            bottomBar.layer.frame = CGRectMake(barLayerOriginFrame.origin.x, barLayerOriginFrame.origin.y + barLayerOriginFrame.height, barLayerOriginFrame.width, barLayerOriginFrame.height)
            nextVessageButton?.hidden = true
            UIView.animateWithDuration(0.1) {
                self.bottomBar.layer.frame = barLayerOriginFrame
                self.bottomBarContainer.alpha = 1
                self.bottomBarContainer.layer.frame = layerOriginFrame
                let nextVessageButtonLayerFrame = self.nextVessageButton.layer.frame
                self.nextVessageButton.layer.frame = CGRectMake(nextVessageButtonLayerFrame.origin.x + nextVessageButtonLayerFrame.width, nextVessageButtonLayerFrame.origin.y + nextVessageButtonLayerFrame.height, nextVessageButtonLayerFrame.width, nextVessageButtonLayerFrame.height)
                self.playVessageManager.refreshNextButton()
                self.nextVessageButton.alpha = 0.3
                UIView.animateWithDuration(0.6){
                    self.nextVessageButton.layer.frame = nextVessageButtonLayerFrame
                    self.nextVessageButton.alpha = 1
                }
            }
        }
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
        if isRecording {
            self.recordVessageManager.cancelRecord()
            self.setReadingVessage()
        }
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
    
    func onChatGroupUpdated(a:NSNotification){
        if let group = a.userInfo?[kChatGroupValue] as? ChatGroup{
            if isGroupChat && group.groupId == self.chatGroup.groupId {
                self.chatGroup = group
            }
        }
    }
    
    func onUserProfileUpdated(a:NSNotification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if VessageUser.isTheSameUser(chatter, userb: self.chatter){
                self.chatter = chatter
            }
        }
    }
    
    func onNewVessagesReveiced(a:NSNotification){
        var otherConversationVessageCount = 0
        if let msgs = a.userInfo?[VessageServiceNotificationValues] as? [Vessage]{
            msgs.forEach({ (msg) in
                if msg.sender == self.conversation?.chatterId{
                    self.playVessageManager.onVessageReceived(msg)
                    self.recordVessageManager.onVessageReceived(msg)
                }else{
                    otherConversationVessageCount += 1
                }
            })
        }
        outterNewVessageCount += otherConversationVessageCount
    }
}

//MARK: Set Chat Backgroud
extension ConversationViewController:ChatBackgroundPickerControllerDelegate{
    
    func showChatImagesMrgController(index:Int){
        ChatImageMgrViewController.showChatImageMgrVeiwController(self,defaultIndex: index)
    }
    
    func chatBackgroundPickerSetedImage(sender: ChatBackgroundPickerController) {
        sender.dismissViewControllerAnimated(true){
            let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                self.startRecording()
            })
            self.showAlert("CHAT_BCG_SETED_TITLE".localizedString(), msg: "CHAT_BCG_SETED_MSG".localizedString(), actions: [ok])
        }
    }
    
    func chatBackgroundPickerSetImageCancel(sender: ChatBackgroundPickerController) {
        let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
            self.startRecording()
        })
        self.showAlert("CHAT_BCG_NOT_SET_TITLE".localizedString(), msg: "CHAT_BCG_SETED_MSG".localizedString(), actions: [ok])
    }
    
    private func needSetChatBackgroundAndShow() -> Bool{
        if !needSetChatImageIfNotExists || userService.isUserChatBackgroundIsSeted{
            return false
        }else{
            needSetChatImageIfNotExists = false
            let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                ChatImageMgrViewController.showChatImageMgrVeiwController(self, defaultIndex: 0)
            })
            self.showAlert("NEED_SET_CHAT_BCG_TITLE".localizedString(), msg: "NEED_SET_CHAT_BCG_MSG".localizedString(), actions: [ok])
            return true
        }
    }
    
}

//MARK: Send Vessage Status
extension ConversationViewController{
    
    func addSendVessageObservers() {
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationViewController.onVessageSending(_:)), name: VessageQueue.onTaskProgress, object: nil)
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationViewController.onVessageSendError(_:)), name: VessageQueue.onTaskStepError, object: nil)
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(ConversationViewController.onVessageSended(_:)), name: VessageQueue.onTaskFinished, object: nil)
    }
    
    func removeSendVessageObservers() {
        VessageQueue.sharedInstance.removeObserver(self)
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
                if !self.isGroupChat && String.isNullOrEmpty(chatter?.accountId) {
                    self.showSendTellFriendAlert()
                }
            }
        }
    }
    
    func resetTitle(_:AnyObject?) {
        if let con = self.conversation {
            self.progressView.hidden = true
            if isGroupChat {
                self.controllerTitle = chatGroup.groupName
            }else{
                self.controllerTitle = userService.getUserNotedName(con.chatterId)
            }
        }
    }
    
    private func showSendTellFriendAlert(){
        let send = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) -> Void in
            let contentText = String(format: "NOTIFY_SMS_FORMAT".localizedString(),"")
            ShareHelper.instance.showTellTextMsgToFriendsAlert(self, content: contentText)
        })
        let name = ServiceContainer.getUserService().getUserNotedName(chatter.userId)
        self.showAlert("SEND_NOTIFY_SMS_TO_FRIEND".localizedString(), msg: name, actions: [send])
    }
}

//MARK: Show ConversationViewController Extension
extension ConversationViewController{
    
    static func showConversationViewController(nvc:UINavigationController,userId: String,initMessage:[String:AnyObject]? = nil) {
        if userId == ServiceContainer.getUserService().myProfile.userId {
            nvc.playToast("CANT_CHAT_WITH_YOURSELF".localizedString())
        }else{
            let conversation = ServiceContainer.getConversationService().openConversationByUserId(userId)
            ConversationViewController.showConversationViewController(nvc, conversation: conversation)
        }
        
    }
    
    static func showConversationViewController(nvc:UINavigationController,conversation:Conversation,initMessage:[String:AnyObject]? = nil)
    {
        if String.isNullOrEmpty(conversation.chatterId) {
            nvc.playToast("NO_SUCH_USER".localizedString())
        }else{
            if conversation.isGroup {
                if let group = ServiceContainer.getChatGroupService().getChatGroup(conversation.chatterId){
                    showConversationView(nvc, conversation: conversation, group: group,initMessage: initMessage)
                }else{
                    let hud = nvc.showAnimationHud()
                    ServiceContainer.getChatGroupService().fetchChatGroup(conversation.chatterId){ group in
                        hud.hideAnimated(true)
                        if let g = group{
                            self.showConversationView(nvc, conversation: conversation, group: g,initMessage: initMessage)
                        }else{
                            nvc.playToast("NO_SUCH_GROUP".localizedString())
                        }
                    }
                }
            }else{
                if let user = ServiceContainer.getUserService().getCachedUserProfile(conversation.chatterId){
                    showConversationView(nvc,conversation: conversation,user: user,initMessage: initMessage)
                }else{
                    let hud = nvc.showAnimationHud()
                    ServiceContainer.getUserService().getUserProfile(conversation.chatterId, updatedCallback: { (u) in
                        hud.hideAnimated(true)
                        if let updatedUser = u{
                            showConversationView(nvc,conversation: conversation,user: updatedUser,initMessage: initMessage)
                        }else{
                            nvc.playToast("NO_SUCH_USER".localizedString())
                        }
                    })
                }
            }
        }
        
    }
    
    private static func showConversationView(nvc:UINavigationController,conversation:Conversation,group:ChatGroup,initMessage:[String:AnyObject]?){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversation = conversation
        controller.chatGroup = group
        controller.initMessage = initMessage
        nvc.pushViewController(controller, animated: true)
    }
    
    private static func showConversationView(nvc:UINavigationController,conversation:Conversation,user:VessageUser,initMessage:[String:AnyObject]?){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversation = conversation
        controller.chatter = user
        controller.initMessage = initMessage
        nvc.pushViewController(controller, animated: true)
    }

}

//MARK: animations
extension ConversationViewController{
    func playNextButtonAnimation(){
        UIAnimationHelper.flashView(nextVessageButton, duration: 0.3, autoStop: true, stopAfterMs: 3000)
    }
    
    func playVideoChatButtonAnimation() {
        UIAnimationHelper.flashView(middleButton, duration: 0.3, autoStop: true, stopAfterMs: 3000)
    }
    
    func playFaceTextButtonAnimation() {
        UIAnimationHelper.flashView(rightButton, duration: 0.3, autoStop: true, stopAfterMs: 3000)
    }
}

extension ConversationViewController:HandleBahamutCmdDelegate{
    func handleBahamutCmd(method: String, args: [String], object: AnyObject?) {
        switch method {
        case "showInviteFriendsAlert":ShareHelper.instance.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString())
        case "showSetupChatImagesController":showChatImagesMrgController(1)
        case "showSetupChatBackgroundController":showChatImagesMrgController(0)
        case "playNextButtonAnimation":playNextButtonAnimation()
        case "playFaceTextButtonAnimation":playFaceTextButtonAnimation()
        case "playVideoChatButtonAnimation":playVideoChatButtonAnimation()
        default:
            break
        }
    }
}
