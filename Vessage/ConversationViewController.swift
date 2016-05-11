//
//  ViewController.swift
//  SeeYou
//
//  Created by AlexChow on 16/2/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import ReachabilitySwift

//MARK: ConversationViewController
class ConversationViewController: UIViewController,PlayerDelegate {
    
    var reachability:Reachability?
    let conversationService = ServiceContainer.getConversationService()
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getService(FileService)
    let vessageService = ServiceContainer.getVessageService()
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.hidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var bottomBar: UIVisualEffectView!{
        didSet{
            bottomBar.hidden = true
        }
    }
    @IBOutlet weak var avatarButton: UIButton!{
        didSet{
            avatarButton.imageView?.layer.cornerRadius = avatarButton.frame.height / 2
        }
    }
    @IBOutlet weak var nextVessageButton: UIButton!{
        didSet{
            nextVessageButton.hidden = true
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
    
    private var vessagePlayer:BahamutFilmView!
    @IBOutlet weak var vessageView: UIView!{
        didSet{
            vessagePlayer = BahamutFilmView(frame: vessageView.bounds)
            vessagePlayer.fileFetcher = fileService.getFileFetcherOfFileId(.Video)
            vessagePlayer.autoPlay = false
            vessagePlayer.isPlaybackLoops = false
            vessagePlayer.isMute = false
            vessagePlayer.showTimeLine = false
            vessagePlayer.delegate = self
            vessageView.addSubview(vessagePlayer)
            vessageView.sendSubviewToBack(vessagePlayer)
            vessageView.hidden = (presentingVesseage == nil)
        }
    }
    
    var conversationId:String!
    var chatterChanged = true
    private var chatter:VessageUser!{
        didSet{
            let oldAvatar = oldValue?.avatar
            if oldAvatar != chatter?.avatar{
                self.updateAvatar(chatter?.avatar)
            }
        }
    }
    
    var notReadVessages = [Vessage](){
        didSet{
            badgeValue = (notReadVessages.filter{$0.isRead == false}).count
            if notReadVessages.count > 0{
                presentingVesseage = notReadVessages.first
            }else{
                if let chatterId = self.chatter?.userId{
                    presentingVesseage = vessageService.getCachedNewestVessage(chatterId)
                }
            }
            nextVessageButton?.hidden = notReadVessages.count <= 1
            vessageView?.hidden = presentingVesseage == nil
            noMessageTipsLabel?.hidden = presentingVesseage != nil
        }
    }
    
    private var presentingVesseage:Vessage!{
        didSet{
            
            if presentingVesseage != nil{
                
                if oldValue != nil && oldValue.vessageId == presentingVesseage.vessageId{
                    return
                }
                
                vessageSendTimeLabel.hidden = false
                vessageSendTimeLabel.text = presentingVesseage.sendTime.dateTimeOfAccurateString.toFriendlyString()
                if oldValue != nil{
                    UIAnimationHelper.animationPageCurlView(vessagePlayer, duration: 0.3, completion: { () -> Void in
                        self.vessagePlayer.filePath = nil
                        self.vessagePlayer.filePath = self.presentingVesseage.fileId
                    })
                }else{
                    vessagePlayer.filePath = presentingVesseage.fileId
                }
            }else{
                vessageSendTimeLabel.hidden = true
            }
            
        }
    }
    
    private var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    
    private var badgeValue:Int = 0 {
        didSet{
            if badgeLabel != nil{
                if badgeValue == 0{
                    badgeLabel.hidden = true
                }else{
                    badgeLabel.text = "\(badgeValue)"
                }
            }
        }
    }
    
    var otherConversationNewVessageReceivedCount:Int = 0{
        didSet{
            if otherConversationNewVessageReceivedCount <= 0{
                return
            }
            if let item = self.navigationController?.navigationBar.backItem?.backBarButtonItem{
                item.title = "( \(otherConversationNewVessageReceivedCount) )"
            }
        }
    }
    
    //MARK: actions
    
    private func updateAvatar(avatar:String?){
        if let btn = self.avatarButton{
            ServiceContainer.getService(FileService).setAvatar(btn, iconFileId: avatar)
        }
    }
    
    func loadNextVessage(){
        if notReadVessages.count <= 1{
            self.playToast("THE_LAST_NOT_READ_VESSAGE".localizedString())
        }else{
            notReadVessages.removeFirst()
            vessageService.removeVessage(self.presentingVesseage)
            if let filePath = fileService.getFilePath(self.presentingVesseage.fileId, type: .Video){
                PersistentFileHelper.deleteFile(filePath)
            }
            self.presentingVesseage = notReadVessages.first
        }
    }
    
    @IBAction func showRecordMessage(sender: AnyObject) {
        RecordMessageController.showRecordMessageController(self,chatter: self.chatter)
    }
    
    @IBAction func noteConversation(sender: AnyObject) {
        showNoteConversationAlert()
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
            showAlert("CHATTER_INFO".localizedString(), msg: "MOBILE_USER".localizedString())
        }else{
            showAlert("CHATTER_INFO".localizedString(), msg:String(format: "USER_ACCOUNT_FORMAT".localizedString(),chatter.accountId))
        }
    }
    
    @IBAction func showNextMessage(sender: AnyObject) {
        if self.presentingVesseage.isRead{
            loadNextVessage()
        }else{
            let continueAction = UIAlertAction(title: "CONTINUE".localizedString(), style: .Default, handler: { (action) -> Void in
                MobClick.event("JumpVessage")
                self.loadNextVessage()
            })
            self.showAlert("CLICK_NEXT_MESSAGE_TIPS_TITLE".localizedString(), msg: "CLICK_NEXT_MESSAGE_TIPS".localizedString(), actions: [ALERT_ACTION_I_SEE,continueAction])
        }
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        userService.addObserver(self, selector: #selector(ConversationViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: #selector(ConversationViewController.onNewVessageReveiced(_:)), name: VessageService.onNewVessageReceived, object: nil)
    }
    
    deinit{
        userService.removeObserver(self)
        vessageService.removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if chatterChanged{
            chatterChanged = false
            if !String.isNullOrWhiteSpace(self.chatter.userId) {
                var vessages = vessageService.getNotReadVessages(self.chatter.userId)
                vessages.sortInPlace({ (a, b) -> Bool in
                    a.sendTime.dateTimeOfAccurateString.isBefore(b.sendTime.dateTimeOfAccurateString)
                })
                notReadVessages = vessages
                updateAvatar(self.chatter?.avatar)
            }else{
                nextVessageButton?.hidden = notReadVessages.count <= 1
                vessageView?.hidden = presentingVesseage == nil
                noMessageTipsLabel?.hidden = presentingVesseage != nil
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showBottomBar()
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
                self.notReadVessages.append(msg)
            }else{
                self.otherConversationNewVessageReceivedCount += 1
            }
        }
    }

    //MARK: Player Delegate
    
    func playerBufferingStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackDidEnd(player: Player) {
        self.vessagePlayer.filePath = nil
        self.vessagePlayer.filePath = self.presentingVesseage.fileId
    }
    
    func playerPlaybackStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
        if self.presentingVesseage?.isRead == false {
            MobClick.event("ReadVessage")
            self.vessageService.readVessage(self.presentingVesseage)
            self.badgeValue -= 1
        }
    }
    
    func playerReady(player: Player) {
        
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

