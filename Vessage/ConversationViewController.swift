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
    
    private(set) var outerNewsVessageCount:Int = 0{
        didSet{
            if let item = self.navigationController?.navigationBar.backItem?.backBarButtonItem{
                if outerNewsVessageCount <= 0{
                    item.title = VessageConfig.appName
                }else{
                    item.title = "\(VessageConfig.appName)( \(outerNewsVessageCount) )"
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
    let chatGroupService = ServiceContainer.getChatGroupService()
    
    private(set) var isRecording:Bool = false
    var isReadingVessages:Bool{
        return !isRecording
    }
    
    private var isGoAhead = false
    
    @IBOutlet weak var imageChatButton: UIButton!{
        didSet{
            imageChatButton.hidden = true
        }
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
    
    @IBOutlet weak var recordingFlashView: UIView!{
        didSet{
            recordingFlashView.layer.cornerRadius = recordingFlashView.frame.size.height / 2
            recordingFlashView.hidden = true
        }
    }
    
    @IBOutlet weak var noSmileFaceTipsLabel: UILabel!
    @IBOutlet weak var groupFaceContainer: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!

}

//MARK: Life Circle
extension ConversationViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.backgroundImage.image = UIImage(named: "recording_bcg_\(rand() % 5)") ?? UIImage(named: "recording_bcg_0")
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
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if !isGoAhead {
            removeObservers()
            recordVessageManager.onReleaseManager()
            playVessageManager.onReleaseManager()
        }
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

//MARK: Actions
extension ConversationViewController{
    
    @IBAction func onClickMiddleButton(sender: AnyObject) {
        if outChatGroup {
            self.playToast("NOT_IN_CHAT_GROUP".localizedString())
            return
        }
        
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
    
    func clickRightBarItem(sender: AnyObject) {
        if outChatGroup {
            self.playToast("NOT_IN_CHAT_GROUP".localizedString())
            return
        }
        isGoAhead = true
        if isGroupChat {
            showChatGroupProfile()
        }else{
            showChatterProfile()
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
    
    private func showBottomBar(){
        if(bottomBar.hidden){
            bottomBar.frame.origin.y = view.frame.height
            UIView.animateWithDuration(0.08) {
                self.bottomBar.hidden = false
                self.bottomBar.frame.origin.y = self.view.frame.height - self.bottomBar.frame.height
                self.imageChatButton.hidden = false
            }
        }
    }
}

//MARK: Show Chatter Profile
extension UserService{
    func showUserProfile(vc:UIViewController,user:VessageUser) {
        let noteName = self.getUserNotedName(user.userId)
        if String.isNullOrWhiteSpace(user.accountId) {
            vc.showAlert(noteName, msg: "MOBILE_USER".localizedString())
        }else{
            let noteNameAction = UIAlertAction(title: "NOTE".localizedString(), style: .Default, handler: { (ac) in
                self.showNoteConversationAlert(vc,user: user)
            })
            vc.showAlert(user.nickName ?? noteName, msg:String(format: "USER_ACCOUNT_FORMAT".localizedString(),user.accountId),actions: [noteNameAction,ALERT_ACTION_CANCEL])
        }
    }
    
    private func showNoteConversationAlert(vc:UIViewController,user:VessageUser){
        let title = "NOTE_CONVERSATION_A_NAME".localizedString()
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
            textfield.placeholder = "CONVERSATION_NAME".localizedString()
            textfield.borderStyle = .None
            textfield.text = ServiceContainer.getUserService().getUserNotedName(user.userId)
        })
        
        let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
            let newNoteName = alertController.textFields?[0].text ?? ""
            if String.isNullOrEmpty(newNoteName)
            {
                vc.playToast("NEW_NOTE_NAME_CANT_NULL".localizedString())
            }else{
                if String.isNullOrWhiteSpace(user.userId) == false{
                    ServiceContainer.getUserService().setUserNoteName(user.userId, noteName: newNoteName)
                }
                vc.playCheckMark("SAVE_NOTE_NAME_SUC".localizedString())
            }
        })
        let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
        alertController.addAction(no)
        alertController.addAction(yes)
        vc.showAlert(alertController)
    }
}

//MARK: Observer & Notifications
extension ConversationViewController{
    
    private func addObservers(){
        userService.addObserver(self, selector: #selector(ConversationViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationViewController.onNewVessageReveiced(_:)), name: VessageService.onNewVessageReceived, object: nil)
        chatGroupService.addObserver(self, selector: #selector(ConversationViewControllerProxy.onChatGroupUpdated(_:)), name: ChatGroupService.OnChatGroupUpdated, object: nil)
    }
    
    private func removeObservers(){
        userService.removeObserver(self)
        vessageService.removeObserver(self)
        chatGroupService.removeObserver(self)
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
    
    func onNewVessageReveiced(a:NSNotification){
        if let msg = a.userInfo?[VessageServiceNotificationValue] as? Vessage{
            var forConversation = false
            if isGroupChat {
                forConversation = msg.sender == self.chatGroup?.groupId ?? ""
            }else{
                forConversation = msg.sender == self.chatter?.userId ?? ""
            }
            
            if forConversation{
                playVessageManager.onVessageReceived(msg)
                recordVessageManager.onVessageReceived(msg)
            }else{
                self.outerNewsVessageCount += 1
            }
        }
    }
}

//MARK: Set Chat Backgroud
extension ConversationViewController:ChatBackgroundPickerControllerDelegate{
    
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
                self.isGoAhead = true
                ChatBackgroundPickerController.showPickerController(self,delegate: self)
            })
            self.showAlert("NEED_SET_CHAT_BCG_TITLE".localizedString(), msg: "NEED_SET_CHAT_BCG_MSG".localizedString(), actions: [ok])
            return true
        }
    }
    
}

//MARK: Note Chatter Name
extension ConversationViewController{
    
}

//MARK: Show ConversationViewController Extension
extension ConversationViewController{
    
    static func showConversationViewController(nvc:UINavigationController,userId: String) {
        let conversation = ServiceContainer.getConversationService().openConversationByUserId(userId)
        ConversationViewController.showConversationViewController(nvc, conversation: conversation)
    }
    
    static func showConversationViewController(nvc:UINavigationController,conversation:Conversation)
    {
        if String.isNullOrEmpty(conversation.chatterId) {
            nvc.playToast("NO_SUCH_USER".localizedString())
        }else{
            if conversation.isGroup {
                if let group = ServiceContainer.getChatGroupService().getChatGroup(conversation.chatterId){
                    showConversationView(nvc, conversation: conversation, group: group)
                }else{
                    let hud = nvc.showAnimationHud()
                    ServiceContainer.getChatGroupService().fetchChatGroup(conversation.chatterId){ group in
                        hud.hide(true)
                        if let g = group{
                            self.showConversationView(nvc, conversation: conversation, group: g)
                        }else{
                            nvc.playToast("NO_SUCH_GROUP".localizedString())
                        }
                    }
                }
            }else{
                if let user = ServiceContainer.getUserService().getCachedUserProfile(conversation.chatterId){
                    showConversationView(nvc,conversation: conversation,user: user)
                }else{
                    let hud = nvc.showAnimationHud()
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
        }
        
    }
    
    private static func showConversationView(nvc:UINavigationController,conversation:Conversation,group:ChatGroup){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversation = conversation
        controller.chatGroup = group
        controller.outerNewsVessageCount = 0
        nvc.pushViewController(controller, animated: true)
    }
    
    private static func showConversationView(nvc:UINavigationController,conversation:Conversation,user:VessageUser){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversation = conversation
        controller.chatter = user
        controller.outerNewsVessageCount = 0
        nvc.pushViewController(controller, animated: true)
    }

}

