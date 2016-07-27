//
//  PlayVessageManager.swift
//  Vessage
//
//  Created by AlexChow on 16/5/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: PlayVessageManager
class PlayVessageManager: ConversationViewControllerProxy {
    private var vessageHandlers = [Int:VessageHandler]()
    
    private func initVessageHandlers() {
        vessageHandlers[Vessage.typeVideo] = VideoVessageHandler(manager: self,container: self.vessageView)
        vessageHandlers[Vessage.typeFaceText] = FaceTextVessageHandler(manager: self, container: self.vessageView)
    }
    
    override func onSwitchToManager() {
        imageChatButton.hidden = rootController.bottomBar.hidden
        rightButton.setImage(UIImage(named: "playNext"), forState: .Normal)
        rightButton.setImage(UIImage(named: "playNext"), forState: .Highlighted)
        recordButton.setImage(UIImage(named: "chat"), forState: .Normal)
        recordButton.setImage(UIImage(named: "chat"), forState: .Highlighted)
    }
    
    override func onReleaseManager() {
        vessageHandlers.forEach { (key,handler) in
            handler.releaseHandler()
        }
        vessageHandlers.removeAll()
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        initVessageHandlers()
        loadNotReadVessages()
    }
    
    var notReadVessages = [Vessage](){
        didSet{
            if notReadVessages.count > 0{
                presentingVesseage = notReadVessages.first
            }else{
                if let chatterId = self.conversation?.chatterId{
                    if let newestVsg = vessageService.getCachedNewestVessage(chatterId){
                        notReadVessages.append(newestVsg)
                        presentingVesseage = newestVsg
                    }
                }
            }
            rightButton?.hidden = notReadVessages.count <= 1
            vessageView?.hidden = presentingVesseage == nil
            noMessageTipsLabel?.hidden = presentingVesseage != nil
            refreshBadge()
        }
    }
    
    private var presentingVesseage:Vessage!{
        didSet{
            conversationLeftTopLabel.text = nil
            conversationRightBottomLabel.text = nil
            if presentingVesseage != nil{
                if oldValue != nil && oldValue.vessageId == presentingVesseage.vessageId{
                    return
                }else{
                    if let handler = self.vessageHandlers[presentingVesseage.typeId]{
                        handler.onPresentingVessageSeted(oldValue, newVessage: presentingVesseage)
                    }else{
                        rootController.playToast("UNKNOW_VESSAGE_TYPE".localizedString())
                    }
                }
            }
        }
    }
    
    var leftTopLabelText:String? {
        didSet{
            conversationLeftTopLabel?.text = leftTopLabelText
        }
    }
    
    var rightBottomLabelText:String? {
        didSet{
            conversationRightBottomLabel?.text = rightBottomLabelText
        }
    }

    private var badgeValue:Int = 0 {
        didSet{
            setBadgeLabelValue(badgeLabel,value: badgeValue)
        }
    }
    
    override func onChatGroupUpdated(chatGroup: ChatGroup) {
        self.rootController.controllerTitle = chatGroup.groupName
    }
    
    override func onChatterUpdated(chatter: VessageUser) {
        self.rootController.controllerTitle = ServiceContainer.getUserService().getUserNotedName(conversation.chatterId)
    }
    
    override func onVessageReceived(vessage: Vessage) {
        self.notReadVessages.append(vessage)
    }
    
    private func loadNotReadVessages() {
        if !String.isNullOrWhiteSpace(self.conversation.chatterId) {
            var vessages = vessageService.getNotReadVessages(self.conversation.chatterId)
            vessages.sortInPlace({ (a, b) -> Bool in
                a.sendTime.dateTimeOfAccurateString.isBefore(b.sendTime.dateTimeOfAccurateString)
            })
            notReadVessages = vessages
        }else{
            rightButton?.hidden = notReadVessages.count <= 1
            vessageView?.hidden = presentingVesseage == nil
            noMessageTipsLabel?.hidden = presentingVesseage != nil
        }
    }
    
    //MARK: actions
    
    func refreshBadge(){
        if let chatterId = conversation.chatterId{
            self.badgeValue = vessageService.getChatterNotReadVessageCount(chatterId)
        }else{
            self.badgeValue = 0
        }
    }
    
    func showNextVessage() {
        if self.presentingVesseage.isRead{
            loadNextVessage()
        }else{
            let continueAction = UIAlertAction(title: "CONTINUE".localizedString(), style: .Default, handler: { (action) -> Void in
                MobClick.event("Vege_JumpVessage")
                self.loadNextVessage()
            })
            rootController.showAlert("CLICK_NEXT_MESSAGE_TIPS_TITLE".localizedString(), msg: "CLICK_NEXT_MESSAGE_TIPS".localizedString(), actions: [ALERT_ACTION_I_SEE,continueAction])
        }
    }
    
    func loadNextVessage(){
        if notReadVessages.count <= 1{
            rootController.playToast("THE_LAST_NOT_READ_VESSAGE".localizedString())
        }else{
            let vsg = notReadVessages.removeFirst()
            vessageService.removeVessage(vsg)
            if let filePath = fileService.getFilePath(vsg.fileId, type: .Video){
                PersistentFileHelper.deleteFile(filePath)
            }
        }
    }
    
}