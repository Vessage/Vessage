//
//  ViewController.swift
//  SeeYou
//
//  Created by AlexChow on 16/2/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: ConversationViewController
class ConversationViewController: UIViewController,PlayerDelegate {
    
    let conversationService = ServiceContainer.getService(ConversationService)
    let userService = ServiceContainer.getService(UserService)
    let fileService = ServiceContainer.getService(FileService)
    let vessageService = ServiceContainer.getService(VessageService)
    @IBOutlet weak var vessagebadgeButton: UIButton!{
        didSet{
            vessagebadgeButton.shouldHideBadgeAtZero = true
            vessagebadgeButton.backgroundColor = UIColor.clearColor()
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
    
    private var vessagePlayer:BahamutFilmView!
    @IBOutlet weak var vessageView: UIView!{
        didSet{
            vessagePlayer = BahamutFilmView(frame: vessageView.bounds)
            vessagePlayer.fileFetcher = fileService.getFileFetcherOfFileId(.Video)
            vessagePlayer.autoPlay = false
            vessagePlayer.isPlaybackLoops = false
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
            conversationNotReadCount = (notReadVessages.filter{$0.isRead == false}).count
            if notReadVessages.count > 0{
                presentingVesseage = notReadVessages.first
            }else{
                if let chatterId = self.chatter?.userId{
                    presentingVesseage = vessageService.getCachedNewestVessage(chatterId)
                }else{
                    presentingVesseage = nil
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
                
                if oldValue != nil{
                    UIAnimationHelper.animationPageCurlView(vessagePlayer, duration: 0.3, completion: { () -> Void in
                        self.vessagePlayer.filePath = nil
                        self.vessagePlayer.filePath = self.presentingVesseage.fileId
                    })
                }else{
                    vessagePlayer.filePath = presentingVesseage.fileId
                }
            }
            
        }
    }
    
    private var controllerTitle:String!{
        didSet{
            self.navigationItem.title = controllerTitle
        }
    }
    
    private var conversationNotReadCount:Int = 0{
        didSet{
            vessagebadgeButton.badgeValue = "\(conversationNotReadCount)"
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
                    self.playCheckMark("SAVE_NOTE_NAME_SUC")
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
    }
    
    @IBAction func showNextMessage(sender: AnyObject) {
        if self.presentingVesseage.isRead{
            loadNextVessage()
        }else{
            let continueAction = UIAlertAction(title: "CONTINUE", style: .Default, handler: { (action) -> Void in
                self.loadNextVessage()
            })
            self.showAlert("CLICK_NEXT_MESSAGE_TIPS".localizedString(), msg: nil, actions: [ALERT_ACTION_I_SEE.first!,continueAction])
        }
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        userService.addObserver(self, selector: "onUserProfileUpdated:", name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: "onNewVessageReveiced:", name: VessageService.onNewVessageReceived, object: nil)
    }
    
    deinit{
        userService.removeObserver(self)
        vessageService.removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if chatterChanged{
            chatterChanged = false
            var vessages = vessageService.getNotReadVessage(self.chatter.userId)
            vessages.sortInPlace({ (a, b) -> Bool in
                a.sendTime.dateTimeOfAccurateString.isBefore(b.sendTime.dateTimeOfAccurateString)
            })
            notReadVessages = vessages
            updateAvatar(self.chatter.avatar)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //MARK: notifications
    
    func onUserProfileUpdated(a:NSNotification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if self.chatter.userId == chatter.userId || self.chatter.mobile == chatter.mobile || self.chatter.mobile.md5 == chatter.mobile{
                self.chatter = chatter
            }
        }
    }
    
    func onNewVessageReveiced(a:NSNotification){
        if let msg = a.userInfo?[VessageServiceNotificationValue] as? Vessage{
            if msg.sender == self.chatter?.userId ?? ""{
                self.notReadVessages.append(msg)
            }else{
                self.otherConversationNewVessageReceivedCount++
            }
        }
    }

    //MARK: Player Delegate
    
    func playerBufferingStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackDidEnd(player: Player) {
        
    }
    
    func playerPlaybackStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
        if self.presentingVesseage?.isRead == false {
            self.vessageService.readVessage(self.presentingVesseage)
            self.conversationNotReadCount--
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
            controller.chatter = ServiceContainer.getService(UserService).getUserProfile(conversation.chatterId){ user in }
        }else if String.isNullOrEmpty(conversation.chatterMobile) == false{
            controller.chatter = ServiceContainer.getService(UserService).getUserProfileByMobile(conversation.chatterMobile){ user in }
        }
        if controller.chatter == nil{
            let chatter = VessageUser()
            chatter.userId = conversation.chatterMobile.md5
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

