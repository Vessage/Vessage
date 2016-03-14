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
    
    let conversationService = ServiceContainer.getService(ConversationService)
    let userService = ServiceContainer.getService(UserService)
    let fileService = ServiceContainer.getService(FileService)
    let vessageService = ServiceContainer.getService(VessageService)
    @IBOutlet weak var vessagebadgeButton: UIButton!{
        didSet{
            vessagebadgeButton.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var avatarButton: UIButton!
    @IBOutlet weak var nextVessageButton: UIButton!{
        didSet{
            nextVessageButton.hidden = conversationNotReadCount < 2
        }
    }
    @IBOutlet weak var vessageView: ShareLinkFilmView!{
        didSet{
            vessageView.fileFetcher = fileService.getFileFetcherOfFileId(.Video)
            vessageView.hidden = (presentingVesseage == nil)
            if presentingVesseage != nil{
                
            }
        }
    }
    
    var conversationId:String!
    var chatter:VessageUser!
    var notReadVessages = [Vessage](){
        didSet{
            conversationNotReadCount = notReadVessages.count
            if conversationNotReadCount > 0{
                presentingVesseage = notReadVessages.first
            }
        }
    }
    private var presentingVesseage:Vessage!{
        didSet{
            if presentingVesseage != nil{
                vessageView.filePath = presentingVesseage.fileId
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
            if conversationNotReadCount == 0{
                vessagebadgeButton.badgeValue = ""
            }else{
                vessagebadgeButton.badgeValue = "\(conversationNotReadCount)"
            }
            nextVessageButton?.hidden = conversationNotReadCount < 2
        }
    }
    
    //MARK: actions
    
    func loadNextVessage(){
        if notReadVessages.count == 0{
            self.playToast("NO_VESSAGE".localizedString())
        }else if notReadVessages.count == 1{
            self.playToast("THE_LAST_NOT_READ_VESSAGE".localizedString())
        }else{
            notReadVessages.removeFirst()
            self.presentingVesseage = notReadVessages.first
            vessageService.readVessage(presentingVesseage.vessageId)
        }
    }
    
    @IBAction func showRecordMessage(sender: AnyObject) {
        let conversation = Conversation()
        conversation.conversationId = self.conversationId
        conversation.chatterId = self.chatter.userId
        conversation.chatterMobile = self.chatter.mobile
        RecordMessageController.showRecordMessageController(self,conversation: conversation)
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
                
                self.conversationService.noteConversation(self.conversationId, noteName: newNoteName)
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
        let userSettingKey = "IS_CLICK_NEXT_MESSAGE_TIPS_SHOWN"
        if UserSetting.isSettingEnable(userSettingKey){
            loadNextVessage()
        }else{
            let continueAction = UIAlertAction(title: "CONTINUE", style: .Default, handler: { (action) -> Void in
                self.loadNextVessage()
                UserSetting.enableSetting(userSettingKey)
            })
            self.showAlert("CLICK_NEXT_MESSAGE_TIPS".localizedString(), msg: nil, actions: [ALERT_ACTION_I_SEE.first!,continueAction])
        }
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        userService.addObserver(self, selector: "onUserProfileUpdated:", name: UserService.userProfileUpdated, object: nil)
        vessageService.addObserver(self, selector: "onNewVessageReveiced:", name: VessageService.onNewVessageReceived, object: nil)
        ChicagoClient.sharedInstance.addBahamutAppNotificationObserver(self, notificationType: "NewVessageNotify", selector: "onNewVessageNotify:", object: nil)
    }
    
    deinit{
        userService.removeObserver(self)
        vessageService.removeObserver(self)
        ChicagoClient.sharedInstance.removeBahamutAppNotificationObserver(self, notificationType: "NewVessageNotify", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        notReadVessages = vessageService.getConversationNotReadVessage(self.conversationId)
    }
    
    //MARK: notifications
    func onNewVessageNotify(a:NSNotification){
        vessageService.newVessageFromServer()
    }
    
    func onUserProfileUpdated(a:NSNotification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            self.chatter = chatter
        }
    }
    
    func onNewVessageReveiced(a:NSNotification){
        if let msg = a.userInfo?[NewVessageReceivedValue] as? Vessage{
            if msg.conversationId == conversationId{
                self.notReadVessages.append(msg)
                conversationNotReadCount++
            }
        }
    }

    //MARK: showConversationViewController
    static func showConversationViewController(nvc:UINavigationController,conversation:Conversation)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "ConversationViewController") as! ConversationViewController
        controller.conversationId = conversation.conversationId
        if String.isNullOrEmpty(conversation.chatterId) == false{
            controller.chatter = ServiceContainer.getService(UserService).getUserProfile(conversation.chatterId){ user in
                
            }
        }else if String.isNullOrEmpty(conversation.chatterMobile) == false{
            controller.chatter = ServiceContainer.getService(UserService).getUserProfile(conversation.chatterMobile){ user in
                
            }
        }else{
            return
        }
        controller.controllerTitle = conversation.noteName
        nvc.pushViewController(controller, animated: true)
    }

}

