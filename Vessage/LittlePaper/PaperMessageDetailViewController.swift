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
            refreshPaper()
        }
    }
    
    private var myProfile:VessageUser = ServiceContainer.getUserService().myProfile
    @IBOutlet weak var senderButton: UIButton!{
        didSet{
            senderButton.layer.cornerRadius = 28
        }
    }
    @IBOutlet weak var openPaperButton: UIButton!{
        didSet{
            openPaperButton.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var postButton: UIButton!{
        didSet{
            postButton.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var paperReceiverInfoLabel: UILabel!
    @IBOutlet weak var messageContentLabel: UITextView!{
        didSet{
            
        }
    }
    
    
    private func refreshPaper(){
        paperReceiverInfoLabel.text = paperMessage.receiverInfo
        messageContentLabel.text = paperMessage.message
        
        senderButton.hidden = !paperMessage.isMyOpened(myProfile.userId)
        openPaperButton.hidden = !paperMessage.isReceivedNotDeal(myProfile.userId)
        postButton.hidden = openPaperButton.hidden
        messageContentLabel.hidden = senderButton.hidden
    }
    
    //MARK: actions
    @IBAction func onClickAllPeople(sender: AnyObject) {
        let userService = ServiceContainer.getUserService()
        var unloadedUsers = [VessageUser]()
        let users = paperMessage.postmen.split(",").map { (userId) -> VessageUser in
            if let user = userService.getCachedUserProfile(userId){
                return user
            }else{
                let user = VessageUser.getUnLoadedUser(userId)
                unloadedUsers.append(user)
                return user
            }
        }
        UserCollectionViewController.showUserCollectionViewController(self.navigationController!,users: users)
        for user in unloadedUsers {
            userService.fetchUserProfile(user.userId)
        }
    }
    
    @IBAction func onClickSender(sender: AnyObject) {
        let conversation = ServiceContainer.getConversationService().openConversationByUserId(paperMessage.sender,noteName: "NEW_FRIEND".localizedString())
        ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
    }
    
    //MARK: SelectVessageUserViewControllerDelegate
    func onFinishSelect(sender:SelectVessageUserViewController,selectedUsers: [VessageUser]) {
        let hud = self.showActivityHudWithMessage(nil, message: nil)
        LittlePaperManager.instance.postPaperToNextUser(paperMessage.paperId, userId: selectedUsers.first!.userId) { (suc) in
            hud.hideAsync(true)
            if suc{
                self.playCheckMark("SUCCESS".localizedString())
                if String.isNullOrWhiteSpace(self.paperMessage.postmen){
                    self.paperMessage.postmen.appendContentsOf(self.myProfile.userId)
                }else{
                    self.paperMessage.postmen.appendContentsOf(",\(self.myProfile.userId)")
                }
                self.refreshPaper()
            }else{
                self.playCrossMark("FAIL".localizedString())
            }
        }
    }
    
    @IBAction func onClickPostPaper(sender: AnyObject) {
        let controller = SelectVessageUserViewController.showSelectVessageUserViewController(self.navigationController!)
        controller.title = "SELECT_POST_MAN".localizedString()
        controller.delegate = self
        controller.allowsMultipleSelection = false
    }
    
    @IBAction func onClickOpenPaper(sender: AnyObject) {
        let hud = self.showActivityHudWithMessage(nil, message: nil)
        LittlePaperManager.instance.openPaperMessage(paperMessage.paperId) { (openedMsg) in
            hud.hideAsync(true)
            if openedMsg != nil{
                self.paperMessage = openedMsg
            }
        }
    }
    
    static func showPaperMessageDetailViewController(nvc:UINavigationController) -> PaperMessageDetailViewController{
        let controller = instanceFromStoryBoard("LittlePaperMessage", identifier: "PaperMessageDetailViewController") as! PaperMessageDetailViewController
        nvc.pushViewController(controller, animated: true)
        return controller
    }
}
