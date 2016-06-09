//
//  ShowPaperMessageViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class PaperMessageDetailViewController: UIViewController,SelectVessageUserViewControllerDelegate {

    var paperMessage:LittlePaperMessage!{
        didSet{
            if self.paperReceiverInfoLabel != nil {
                refreshPaper()
            }
        }
    }
    
    private var myProfile:VessageUser = ServiceContainer.getUserService().myProfile
    @IBOutlet weak var userTipsButton: UIButton!{
        didSet{
            userTipsButton.clipsToBounds = true
            userTipsButton.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var openPaperButton: UIButton!{
        didSet{
            openPaperButton.clipsToBounds = true
            openPaperButton.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var postButton: UIButton!{
        didSet{
            postButton.clipsToBounds = true
            postButton.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var paperReceiverInfoLabel: UILabel!
    @IBOutlet weak var messageContentLabel: UILabel!{
        didSet{
            messageContentLabel.clipsToBounds = true
            messageContentLabel.layer.cornerRadius = 3
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshPaper()
    }
    
    //MARK: Refresh Paper Bottom Buttons
    private func refreshPaper(){
        paperReceiverInfoLabel.text = paperMessage.receiverInfo
        messageContentLabel.text = nil
        userTipsButton.hidden = true
        userTipsButton.enabled = false
        openPaperButton.hidden = true
        postButton.hidden = true
        messageContentLabel.hidden = true
        if paperMessage.isMySended(myProfile.userId) {
            updateUserTipsButtonOfSendedMessage()
            messageContentLabel.text = paperMessage.message
            messageContentLabel.hidden = false
        }else if paperMessage.isMyOpened(myProfile.userId){
            updateUserTipsButtonOfOpenedMessage()
            messageContentLabel.hidden = false
            UIAnimationHelper.animationPageCurlView(messageContentLabel, duration: 0.3, completion: {
                self.messageContentLabel.text = self.paperMessage.message
            })
            messageContentLabel.hidden = false
        }else if paperMessage.isMyPosted(myProfile.userId){
            updateUserTipsButtonOfPostedMessage()
        }else if paperMessage.isReceivedNotDeal(myProfile.userId){
            openPaperButton.hidden = false
            postButton.hidden = false
        }
    }
    
    private func updateUserTipsButtonOfPostedMessage(){
        if paperMessage.isOpened {
            userTipsButton.setTitle("PAPER_POSTED_TO_RECEIVER".littlePaperString, forState: .Normal)
        }else{
            userTipsButton.setTitle("PAPER_POSTED".littlePaperString, forState: .Normal)
        }
        userTipsButton.hidden = false
    }
    
    private func updateUserTipsButtonOfOpenedMessage(){
        if let sender = ServiceContainer.getUserService().getCachedUserProfile(paperMessage.sender){
            let titleFormat = "PAPER_SEND_BY".littlePaperString
            let nick = ServiceContainer.getUserService().getUserNotedName(sender.userId)
            userTipsButton.setTitle(String(format: titleFormat,nick), forState: .Normal)
            userTipsButton.hidden = false
            userTipsButton.enabled = true
        }else{
            ServiceContainer.getUserService().getUserProfile(paperMessage.sender, updatedCallback: { (user) in
                if user != nil{
                    let titleFormat = "PAPER_SEND_BY".littlePaperString
                    let nick = ServiceContainer.getUserService().getUserNotedName(self.paperMessage.sender)
                    self.userTipsButton.setTitle(String(format: titleFormat,nick), forState: .Normal)
                    self.userTipsButton.hidden = false
                    self.userTipsButton.enabled = true
                }
            })
        }
    }
    
    private func updateUserTipsButtonOfSendedMessage(){
        if paperMessage.isOpened {
            if let receiver = ServiceContainer.getUserService().getCachedUserProfile(paperMessage.receiver){
                let titleFormat = "PAPER_OPEN_BY".littlePaperString
                let nick = ServiceContainer.getUserService().getUserNotedName(receiver.userId)
                userTipsButton.setTitle(String(format: titleFormat,nick), forState: .Normal)
                userTipsButton.hidden = false
                userTipsButton.enabled = true
            }else{
                ServiceContainer.getUserService().getUserProfile(paperMessage.receiver, updatedCallback: { (u) in
                    if let user = u{
                        let titleFormat = "PAPER_OPEN_BY".littlePaperString
                        let nick = ServiceContainer.getUserService().getUserNotedName(user.userId)
                        self.userTipsButton.setTitle(String(format: titleFormat,nick), forState: .Normal)
                        self.userTipsButton.hidden = false
                        self.userTipsButton.enabled = true
                        
                    }
                })
            }
        }else{
            userTipsButton.hidden = false
            userTipsButton.setTitle("PAPER_POSTING".littlePaperString, forState: .Normal)
        }
    }
    
    //MARK: actions
    @IBAction func onClickAllPeople(sender: AnyObject) {
        let userService = ServiceContainer.getUserService()
        var unloadedUsers = [VessageUser]()
        var users = paperMessage.postmen?.map { (userId) -> VessageUser in
            if let user = userService.getCachedUserProfile(userId){
                return user
            }else{
                let user = VessageUser.getUnLoadedUser(userId)
                unloadedUsers.append(user)
                return user
            }
        }
        if !String.isNullOrEmpty(paperMessage.receiver) && !paperMessage.postmen.contains(paperMessage.receiver) {
            if let receiver = userService.getCachedUserProfile(paperMessage.receiver) {
                users?.append(receiver)
            }else{
                let receiver = VessageUser.getUnLoadedUser(paperMessage.receiver)
                unloadedUsers.append(receiver)
                users?.append(receiver)
            }
        }
        UserCollectionViewController.showUserCollectionViewController(self.navigationController!,users: users ?? [])
        for user in unloadedUsers {
            userService.fetchUserProfile(user.userId)
        }
    }
    
    @IBAction func onClickSender(sender: AnyObject) {
        var chatter = paperMessage.sender
        if paperMessage.isMySended(myProfile.userId) && paperMessage.isOpened{
            chatter = paperMessage.receiver
        }
        if let user = ServiceContainer.getUserService().getCachedUserProfile(chatter){
            let conversation = ServiceContainer.getConversationService().openConversationByUserId(chatter,noteName: user.nickName)
            ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
        }else{
            ServiceContainer.getUserService().getUserProfile(chatter, updatedCallback: { (u) in
                if let user = u{
                    let conversation = ServiceContainer.getConversationService().openConversationByUserId(chatter,noteName: user.nickName)
                    ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
                }
            })
        }
    }
    
    //MARK: SelectVessageUserViewControllerDelegate
    func onFinishSelect(sender:SelectVessageUserViewController,selectedUsers: [VessageUser]) {
        let hud = self.showActivityHudWithMessage(nil, message: nil)
        LittlePaperManager.instance.postPaperToNextUser(paperMessage.paperId,userId: selectedUsers.first!.userId,isAnonymous: false) { (suc,errorMsg) in
            hud.hideAsync(true)
            if suc{
                MobClick.event("LittlePaper_PostNext")
                self.playCheckMark("SUCCESS".littlePaperString)
                self.refreshPaper()
            }else{
                self.playCrossMark((errorMsg ?? "UNKNOW_ERROR").littlePaperString)
            }
        }
    }
    
    @IBAction func onClickPostPaper(sender: AnyObject) {
        let controller = SelectVessageUserViewController.showSelectVessageUserViewController(self.navigationController!)
        controller.title = "SELECT_POST_MAN".littlePaperString
        controller.delegate = self
        controller.showActiveUsers = true
        controller.allowsMultipleSelection = false
    }
    
    @IBAction func onClickOpenPaper(sender: AnyObject) {
        let oKAction = UIAlertAction(title: "CONTINUE_OPEN_PAPER".littlePaperString, style: .Default) { (ac) in
            let hud = self.showActivityHudWithMessage(nil, message: nil)
            LittlePaperManager.instance.openPaperMessage(self.paperMessage.paperId) { (openedMsg,errorMsg) in
                hud.hideAsync(true)
                if let m = openedMsg{
                    MobClick.event("LittlePaper_OpenPaper")
                    self.paperMessage = m
                    self.refreshPaper()
                }else{
                    self.playCrossMark((errorMsg ?? "UNKNOW_ERROR").littlePaperString)
                }
            }
        }
        self.showAlert("OPEN_PAPER_CONFIRM_TITLE".littlePaperString, msg: "OPEN_PAPER_CONFIRM_MSG".littlePaperString, actions: [ALERT_ACTION_CANCEL,oKAction])
    }
    
    static func showPaperMessageDetailViewController(nvc:UINavigationController) -> PaperMessageDetailViewController{
        let controller = instanceFromStoryBoard("LittlePaperMessage", identifier: "PaperMessageDetailViewController") as! PaperMessageDetailViewController
        nvc.pushViewController(controller, animated: true)
        return controller
    }
}
