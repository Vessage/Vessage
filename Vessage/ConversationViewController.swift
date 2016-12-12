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
            if let cg = chatGroup {
                outChatGroup = !chatGroup.chatters.contains(UserSetting.userId)
                if !outChatGroup {
                    playVessageManager?.onChatGroupUpdated(cg)
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
    
    private(set) var playVessageManager:PlayVessageManager!
    
    
    
    var currentManager:ConversationViewControllerProxy!
    
    let conversationService = ServiceContainer.getConversationService()
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getService(FileService)
    let vessageService = ServiceContainer.getVessageService()
    let chatGroupService = ServiceContainer.getChatGroupService()
    
    @IBOutlet weak var topChattersBoardHeight: NSLayoutConstraint!
    @IBOutlet weak var topChattersBoard: ChattersBoard!
    @IBOutlet weak var bottomChattersBoardBottom: NSLayoutConstraint!
    @IBOutlet weak var bottomChattersBoardHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomChattersBoard: ChattersBoard!
    @IBOutlet weak var sendImageButton: UIButton!
    @IBOutlet weak var sendFaceTextButton: UIButton!
    @IBOutlet weak var sendVideoChatButton: UIButton!
    @IBOutlet weak var mgrChatImagesButton: UIButton!{
        didSet{
            mgrChatImagesButton.layoutIfNeeded()
            mgrChatImagesButton.clipsToBounds = true
            mgrChatImagesButton.layer.cornerRadius = mgrChatImagesButton.frame.height / 2
        }
    }
    
    @IBOutlet weak var timemachineButton: UIButton!
    @IBOutlet weak var readingLineProgress: UIProgressView!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var vessageViewContainer: UIView!
    
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    //MARK: flash tips properties
    private var flashTipsView:UILabel!
    
    private var baseVessageBodyDict:[String:AnyObject]{
        var dict = [String:AnyObject]()
        if let selectedFaceId = playVessageManager.selectedImageId {
            dict.updateValue(selectedFaceId, forKey: "faceId")
        }
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
        currentManager?.onKeyBoardShown()
    }
    
    func onKeyboardHidden(a:NSNotification) {
        self.hideKeyBoard()
        currentManager?.onKeyBoardHidden()
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
        
        addObservers()
        if let group = self.chatGroup{
            playVessageManager.onInitGroup(group)
        }
        
        playVessageManager.onSwitchToManager()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: isGroupChat ? "user_group":"userInfo"), style: .Plain, target: self, action: #selector(ConversationViewController.clickRightBarItem(_:)))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.themeColor
        outterNewVessageCount = 0
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipe(_:)))
        swipeLeft.direction = .Left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipe(_:)))
        swipeRight.direction = .Right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipe(_:)))
        swipeUp.direction = .Up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipe(_:)))
        swipeDown.direction = .Down
        self.view.addGestureRecognizer(swipeDown)
        
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(ConversationViewController.onPanGesture(_:)))
        panGes.requireGestureRecognizerToFail(swipeLeft)
        panGes.requireGestureRecognizerToFail(swipeRight)
        panGes.requireGestureRecognizerToFail(swipeUp)
        panGes.requireGestureRecognizerToFail(swipeDown)
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
        ServiceContainer.getAppService().addObserver(self, selector: #selector(ConversationViewController.onAppResignActive(_:)), name: AppService.onAppResignActive, object: nil)
        handleInitMessage()
        playVessageManager.loadVessages()
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
        self.playVessageManager.onReleaseManager()
        self.playVessageManager = nil
        self.conversation = nil
        self.chatGroup = nil
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

//MARK: Actions
extension ConversationViewController{
    
    func onPanGesture(a:UIPanGestureRecognizer) {
        if let handler = currentManager as? HandlePanGesture {
            let v = a.velocityInView(self.view)
            handler.onPan(v)
        }
    }
    
    func onSwipe(a:UISwipeGestureRecognizer) {
        if let handler = currentManager as? HandleSwipeGesture{
            handler.onSwipe(a.direction)
        }
    }
    
    func onBackItemClick(sender:AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func onLongPressMiddleButton(sender:UILongPressGestureRecognizer) {
        
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
            }
        }
    }
    
    func onUserProfileUpdated(a:NSNotification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if let chatterids = self.chatGroup?.chatters{
                if chatterids.contains(chatter.userId) {
                    playVessageManager.onGroupChatterUpdated(chatter)
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
            self.playVessageManager.onVessagesReceived(received)
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
                self.startRecordVideoVessage()
            })
            self.showAlert("CHAT_BCG_SETED_TITLE".localizedString(), msg: "CHAT_BCG_SETED_MSG".localizedString(), actions: [ok])
        }
    }
    
    func chatBackgroundPickerSetImageCancel(sender: ChatBackgroundPickerController) {
        let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
            self.startRecordVideoVessage()
        })
        self.showAlert("CHAT_BCG_NOT_SET_TITLE".localizedString(), msg: "CHAT_BCG_SETED_MSG".localizedString(), actions: [ok])
    }
    
    func needSetChatBackgroundAndShow() -> Bool{
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
                if isNotRegistFriend{
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
        if flashTipsView == nil {
            flashTipsView = UILabel()
            flashTipsView.clipsToBounds = true
            flashTipsView.textColor = UIColor.orangeColor()
            flashTipsView.textAlignment = .Center
            flashTipsView.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.3)
        }
        self.flashTipsView.text = msg
        self.flashTipsView.sizeToFit()
        self.flashTipsView.layoutIfNeeded()
        
        self.flashTipsView.frame.size.height += 10
        self.flashTipsView.frame.size.width += 16
        
        flashTipsView.layer.cornerRadius = self.flashTipsView.frame.height / 2
        
        let bottomChattersBoard = self.bottomChattersBoard
        let topChattersBoard = self.topChattersBoard
        let topChattersBoardBottomY = topChattersBoard.frame.origin.y + topChattersBoard.frame.height
        
        let centerY = topChattersBoardBottomY + (bottomChattersBoard.frame.origin.y - topChattersBoardBottomY) / 2
        let center = CGPointMake(self.vessageViewContainer.frame.width / 2,centerY)
        self.flashTipsView.center = center
        self.view.addSubview(self.flashTipsView)
        UIAnimationHelper.flashView(self.flashTipsView, duration: 0.4, autoStop: true, stopAfterMs: 1600){
            self.flashTipsView.removeFromSuperview()
        }
    }
    
}


//MARK: animations
extension ConversationViewController{
    
    func playVideoChatButtonAnimation() {
        UIAnimationHelper.flashView(sendVideoChatButton, duration: 0.3, autoStop: true, stopAfterMs: 3000)
    }
    
    func playFaceTextButtonAnimation() {
        UIAnimationHelper.flashView(sendFaceTextButton, duration: 0.3, autoStop: true, stopAfterMs: 3000)
    }
}

//MARK:HandleBahamutCmdDelegate
extension ConversationViewController:HandleBahamutCmdDelegate{
    func handleBahamutCmd(method: String, args: [String], object: AnyObject?) {
        switch method {
        case "showInviteFriendsAlert":ShareHelper.instance.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString())
        case "showSetupChatImagesController":showChatImagesMrgController(1)
        case "showSetupChatBackgroundController":showChatImagesMrgController(0)
        case "playFaceTextButtonAnimation":playFaceTextButtonAnimation()
        case "playVideoChatButtonAnimation":playVideoChatButtonAnimation()
        default:
            break
        }
    }
}
