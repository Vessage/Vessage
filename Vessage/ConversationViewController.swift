//
//  ViewController.swift
//  SeeYou
//
//  Created by AlexChow on 16/2/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import MNReachabilitySwift

class ConversationViewControllerProxy: NSObject {
    private(set) var rootController:ConversationViewController!
    
    var vessageView:UIView!{
        return rootController.vessageView
    }
    var fileService:FileService!{
        return rootController.fileService
    }
    var chatter:VessageUser!{
        return rootController.chatter
    }
    var vessageService:VessageService!{
        return rootController.vessageService
    }
    var rightButton:UIButton!{
        return rootController.rightButton
    }
    var noMessageTipsLabel:UILabel!{
        return rootController.noMessageTipsLabel
    }
    var badgeLabel:UILabel!{
        return rootController.badgeLabel
    }
    var vessageSendTimeLabel:UILabel{
        return rootController.vessageSendTimeLabel
    }
    
    var recordButton: UIButton!{
        return rootController.middleButton
    }
    
    var cancelRecordButton: UIButton!{
        return rootController.rightButton
    }
    
    var smileFaceImageView: UIImageView!{
        return rootController.smileFaceImageView
    }
    var noSmileFaceTipsLabel: UILabel!{
        return rootController.noSmileFaceTipsLabel
    }
    var recordingFlashView: UIView!{
        return rootController.recordingFlashView
    }
    var recordingProgress:KDCircularProgress!{
        return rootController.recordingProgress
    }
    var previewRectView: UIView!{
        return rootController.previewRectView
    }
    func onVessageReceived(vessages:Vessage) {}
    func onChatterUpdated(chatter:VessageUser) {}
    func initManager(controller:ConversationViewController) {
        self.rootController = controller
    }
    func onReleaseManager() {
        
    }
    func onSwitchToManager() {
        
    }
}

//MARK: ConversationViewController
class ConversationViewController: UIViewController {
    var conversationId:String!
    var chatterChanged = true
    private(set) var chatter:VessageUser!{
        didSet{
            if let user = chatter{
                recordVessageManager?.onChatterUpdated(user)
                recordVessageManager?.onChatterUpdated(user)
            }
        }
    }
    
    private var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    
    var otherConversationNewVessageReceivedCount:Int = 0{
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
    
    var playVessageManager:PlayVessageManager!
    var recordVessageManager:RecordVessageManager!
    
    var reachability:MNReachability?
    let conversationService = ServiceContainer.getConversationService()
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getService(FileService)
    let vessageService = ServiceContainer.getVessageService()
    
    var isRecording:Bool = false
    var isReadingVessages:Bool{
        return !isRecording
    }
    
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

        //isGoAhead = true
        //RecordMessageController.showRecordMessageController(self,chatter: self.chatter)
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
            textfield.text = self.controllerTitle
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
        if String.isNullOrWhiteSpace(chatter.accountId) {
            showAlert(controllerTitle, msg: "MOBILE_USER".localizedString())
        }else{
            let noteNameAction = UIAlertAction(title: "NOTE".localizedString(), style: .Default, handler: { (ac) in
                self.showNoteConversationAlert()
            })
            showAlert(controllerTitle, msg:String(format: "USER_ACCOUNT_FORMAT".localizedString(),chatter.accountId),actions: [noteNameAction,ALERT_ACTION_CANCEL])
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
        if chatterChanged{
            chatterChanged = false
        }
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
    static func showConversationViewController(nvc:UINavigationController,conversation:Conversation)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversationId = conversation.conversationId
        if String.isNullOrEmpty(conversation.chatterId) == false{
            controller.chatter = ServiceContainer.getUserService().getUserProfile(conversation.chatterId){ user in }
        }else if String.isNullOrEmpty(conversation.chatterMobile) == false{
            controller.chatter = ServiceContainer.getUserService().getUserProfileByMobile(conversation.chatterMobile){ user in }
        }
        if controller.chatter == nil{
            let chatter = VessageUser()
            
            chatter.nickName = conversation.noteName
            chatter.mobile = conversation.chatterMobile
            controller.chatter = chatter
        }
        controller.chatterChanged = true
        controller.otherConversationNewVessageReceivedCount = 0
        controller.controllerTitle = conversation.noteName
        nvc.pushViewController(controller, animated: true)
    }

}

