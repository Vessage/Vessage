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
    private(set) var conversationId:String!
    private(set) var isGroupChat = false
    
    private(set) var chatter:VessageUser!{
        didSet{
            if let user = chatter{
                recordVessageManager?.onChatterUpdated(user)
                playVessageManager?.onChatterUpdated(user)
            }
        }
    }
    
    private(set) var chatGroup:ChatGroup!{
        didSet{
            if let cg = chatGroup {
                recordVessageManager?.onChatGroupUpdated(cg)
                playVessageManager?.onChatGroupUpdated(cg)
            }
        }
    }
    
    var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    
    private(set) var otherConversationNewVessageReceivedCount:Int = 0{
        didSet{
            if let item = self.navigationController?.navigationBar.backItem?.backBarButtonItem{
                if otherConversationNewVessageReceivedCount <= 0{
                    item.title = VessageConfig.appName
                }else{
                    item.title = "\(VessageConfig.appName)( \(otherConversationNewVessageReceivedCount) )"
                }
            }
        }
    }
    
    private(set) var playVessageManager:PlayVessageManager!
    private(set) var recordVessageManager:RecordVessageManager!
    
    let conversationService = ServiceContainer.getConversationService()
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getService(FileService)
    let vessageService = ServiceContainer.getVessageService()
    
    private(set) var isRecording:Bool = false
    var isReadingVessages:Bool{
        return !isRecording
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var recordViewContainer: UIView!
    @IBOutlet weak var vessageViewContainer: UIView!
    
    @IBOutlet weak var middleButton: UIButton!
    
    @IBOutlet weak var bottomBar: UIVisualEffectView!{
        didSet{
            bottomBar.hidden = true
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
    
    @IBOutlet weak var noMessageTipsLabel: UILabel!{
        didSet{
            noMessageTipsLabel.hidden = true
        }
    }
    @IBOutlet weak var vessageSendTimeLabel: UILabel!{
        didSet{
            vessageSendTimeLabel.hidden = true
        }
    }
    @IBOutlet weak var vessageView: UIView!
    //MARK: Record Views
    @IBOutlet weak var previewRectView: UIView!{
        didSet{
            previewRectView.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var recordingProgress: KDCircularProgress!{
        didSet{
            recordingProgress.hidden = true
        }
    }
    
    @IBOutlet weak var smileFaceImageView: UIImageView!
    @IBOutlet weak var noSmileFaceTipsLabel: UILabel!
    @IBOutlet weak var recordingFlashView: UIView!{
        didSet{
            recordingFlashView.layer.cornerRadius = recordingFlashView.frame.size.height / 2
            recordingFlashView.hidden = true
        }
    }

    //MARK: Actions
    
    func startRecording() {
        isRecording = true
        vessageViewContainer.hidden = true
        recordViewContainer.hidden = false
        recordViewContainer.alpha = 0.3
        UIView.beginAnimations("RecordViewContainer", context: nil)
        UIView.setAnimationDuration(0.3)
        recordViewContainer.alpha = 1
        UIView.commitAnimations()
        
        
        navigationController?.navigationBarHidden = true
        recordVessageManager.onSwitchToManager()
        recordVessageManager.startRecord()
    }
    
    func setReadingVessage() {
        isRecording = false
        recordViewContainer.hidden = true
        vessageViewContainer.hidden = false
        navigationController?.navigationBarHidden = false
        playVessageManager.onSwitchToManager()
    }
        
    @IBAction func onClickMiddleButton(sender: AnyObject) {
        if isReadingVessages {
            if needSetChatBackgroundAndShow() {
                return
            }
            startRecording()
        }else{
            setReadingVessage()
            recordVessageManager.sendVessage()
        }
    }
    
    private func needSetChatBackgroundAndShow() -> Bool{
        if userService.isUserChatBackgroundIsSeted{
            return false
        }else{
            let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                self.isGoAhead = true
                ChatBackgroundPickerController.showPickerController(self) { (sender) -> Void in
                    sender.dismissViewControllerAnimated(true, completion: { () -> Void in
                        
                    })
                }
            })
            self.showAlert("NEED_SET_CHAT_BCG_TITLE".localizedString(), msg: "NEED_SET_CHAT_BCG_MSG".localizedString(), actions: [ok])
            return true
        }
    }
    
    private func showNoteConversationAlert(){
        let title = "NOTE_CONVERSATION_A_NAME".localizedString()
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
            textfield.placeholder = "CONVERSATION_NAME".localizedString()
            textfield.borderStyle = .None
            textfield.text = ServiceContainer.getUserService().getUserNotedName(self.chatter.userId)
        })
        
        let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
            let newNoteName = alertController.textFields?[0].text ?? ""
            if String.isNullOrEmpty(newNoteName)
            {
                self.playToast("NEW_NOTE_NAME_CANT_NULL".localizedString())
            }else{
                if self.conversationService.noteConversation(self.conversationId, noteName: newNoteName){
                    self.controllerTitle = newNoteName
                    if String.isNullOrWhiteSpace(self.chatter?.userId) == false{
                        ServiceContainer.getUserService().setUserNoteName(self.chatter.userId, noteName: newNoteName)
                    }
                    self.playCheckMark("SAVE_NOTE_NAME_SUC".localizedString())
                }else{
                    self.playCrossMark("SAVE_NOTE_NAME_ERROR".localizedString())
                }
            }
        })
        let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
        alertController.addAction(no)
        alertController.addAction(yes)
        self.showAlert(alertController)
    }
    
    @IBAction func showUserProfile(sender: AnyObject) {
        let noteName = ServiceContainer.getUserService().getUserNotedName(self.chatter.userId)
        if String.isNullOrWhiteSpace(chatter.accountId) {
            showAlert(noteName, msg: "MOBILE_USER".localizedString())
        }else{
            let noteNameAction = UIAlertAction(title: "NOTE".localizedString(), style: .Default, handler: { (ac) in
                self.showNoteConversationAlert()
            })
            showAlert(chatter.nickName ?? noteName, msg:String(format: "USER_ACCOUNT_FORMAT".localizedString(),chatter.accountId),actions: [noteNameAction,ALERT_ACTION_CANCEL])
        }
    }
    
    @IBAction func onClickRightButton(sender: AnyObject) {
        if isReadingVessages {
            playVessageManager.showNextVessage()
        }else{
            recordVessageManager.cancelRecord()
            setReadingVessage()
        }
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        playVessageManager = PlayVessageManager()
        playVessageManager.initManager(self)
        recordVessageManager = RecordVessageManager()
        recordVessageManager.initManager(self)
        if let chatter = self.chatter{
            recordVessageManager.onChatterUpdated(chatter)
            recordVessageManager.onChatterUpdated(chatter)
        }
        addObservers()
        setReadingVessage()
        ServiceContainer.getUserService().fetchLatestUserProfile(chatter)
    }
    
    private var isGoAhead = false
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if !isGoAhead {
            removeObservers()
            recordVessageManager.onReleaseManager()
            playVessageManager.onReleaseManager()
        }
    }
    
    private func addObservers(){
        userService.addObserver(self, selector: #selector(ConversationViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationViewController.onNewVessageReveiced(_:)), name: VessageService.onNewVessageReceived, object: nil)
    }
    
    private func removeObservers(){
        userService.removeObserver(self)
        vessageService.removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        isGoAhead = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showBottomBar()
        recordVessageManager.camera.openCamera()
    }
    
    private func showBottomBar(){
        if(bottomBar.hidden){
            bottomBar.frame.origin.y = view.frame.height
            UIView.animateWithDuration(0.08) {
                self.bottomBar.hidden = false
                self.bottomBar.frame.origin.y = self.view.frame.height - self.bottomBar.frame.height
            }
        }
    }
    
    //MARK: notifications
    
    func onUserProfileUpdated(a:NSNotification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if VessageUser.isTheSameUser(chatter, userb: self.chatter){
                self.chatter = chatter
            }
        }
    }
    
    func onNewVessageReveiced(a:NSNotification){
        if let msg = a.userInfo?[VessageServiceNotificationValue] as? Vessage{
            if msg.sender == self.chatter?.userId ?? ""{
                playVessageManager.onVessageReceived(msg)
                recordVessageManager.onVessageReceived(msg)
            }else{
                self.otherConversationNewVessageReceivedCount += 1
            }
        }
    }

    
    //MARK: showConversationViewController
    static func showConversationViewController(nvc:UINavigationController,chatter: String) {
        if let user = ServiceContainer.getUserService().getCachedUserProfile(chatter){
            let conversation = ServiceContainer.getConversationService().openConversationByUserId(chatter,noteName: user.nickName)
            ConversationViewController.showConversationViewController(nvc, conversation: conversation)
        }else{
            let hud = nvc.showActivityHud()
            ServiceContainer.getUserService().getUserProfile(chatter, updatedCallback: { (u) in
                hud.hide(true)
                if let user = u{
                    let conversation = ServiceContainer.getConversationService().openConversationByUserId(chatter,noteName: user.nickName)
                    ConversationViewController.showConversationViewController(nvc, conversation: conversation)
                }else{
                    nvc.playToast("NO_SUCH_USER".localizedString())
                }
            })
        }
    }
    
    static func showConversationViewController(nvc:UINavigationController,conversation:Conversation)
    {
        if String.isNullOrEmpty(conversation.chatterId) {
            nvc.playToast("NO_SUCH_USER".localizedString())
        }else if let user = ServiceContainer.getUserService().getCachedUserProfile(conversation.chatterId){
            showConversationView(nvc,conversation: conversation,user: user)
        }else{
            let hud = nvc.showActivityHud()
            ServiceContainer.getUserService().getUserProfile(conversation.chatterId, updatedCallback: { (u) in
                hud.hide(true)
                if let updatedUser = u{
                    showConversationView(nvc,conversation: conversation,user: updatedUser)
                }else{
                    nvc.playToast("NO_SUCH_USER".localizedString())
                }
            })
        }
        
    }
    
    static func showConversationView(nvc:UINavigationController,conversation:Conversation,user:VessageUser){
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversationId = conversation.conversationId
        controller.chatter = user
        controller.otherConversationNewVessageReceivedCount = 0
        controller.controllerTitle = ServiceContainer.getUserService().getUserNotedName(user.userId)
        nvc.pushViewController(controller, animated: true)
    }

}

