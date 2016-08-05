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
    
    private func generateNoVessageHandler() -> VessageHandler{
        if let h = vessageHandlers[Vessage.typeNoVessage]{
            return h
        }else{
            let handler = NoVessageHandler(manager: self, container: self.vessageView)
            vessageHandlers.updateValue(handler, forKey: Vessage.typeNoVessage)
            return handler
        }
    }
    
    private func generateVessageHandler(typeId:Int) -> VessageHandler{
        var handler:VessageHandler? = vessageHandlers[typeId]
        if handler != nil {
            return handler!
        }
        switch typeId {
        case Vessage.typeVideo:
            handler = VideoVessageHandler(manager: self,container: self.vessageView)
        case Vessage.typeFaceText:
            handler = FaceTextVessageHandler(manager: self, container: self.vessageView)
        default:
            if let h = vessageHandlers[Vessage.typeUnknow]{
                handler = h
            }else{
                handler = UnknowVessageHandler(manager: self, container: self.vessageView)
                vessageHandlers.updateValue(handler!, forKey: Vessage.typeUnknow)
            }
            NSLog("Unknow Vessage TypeId:\(typeId)")
            return handler!
        }
        vessageHandlers.updateValue(handler!, forKey: typeId)
        return handler!
    }
    
    override func onSwitchToManager() {
        imageChatButton.hidden = rootController.bottomBar.hidden
        rightButton.setImage(UIImage(named: "playNext"), forState: .Normal)
        rightButton.setImage(UIImage(named: "playNext"), forState: .Highlighted)
        recordButton.setImage(UIImage(named: "chat"), forState: .Normal)
        recordButton.setImage(UIImage(named: "chat"), forState: .Highlighted)
    }
    
    override func onReleaseManager() {
        ServiceContainer.getVessageService().removeObserver(self)
        vessageHandlers.forEach { (key,handler) in
            handler.releaseHandler()
        }
        vessageHandlers.removeAll()
        super.onReleaseManager()
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        vessageService.addObserver(self, selector: #selector(PlayVessageManager.onVessageReaded(_:)), name: VessageService.onVessageRead, object: nil)
        loadNotReadVessages()
    }
    
    var notReadVessages = [Vessage](){
        didSet{
            var vsg:Vessage? = nil
            if notReadVessages.count > 0{
                vsg = notReadVessages.first
            }else{
                if let chatterId = self.conversation?.chatterId{
                    if let newestVsg = vessageService.getCachedNewestVessage(chatterId){
                        notReadVessages.append(newestVsg)
                        vsg = newestVsg
                    }
                }
            }
            presentingVesseage = vsg
            rightButton?.hidden = notReadVessages.count <= 1
            refreshBadge()
        }
    }
    
    private var presentingVesseage:Vessage!{
        didSet{
            if presentingVesseage == nil{
                self.generateNoVessageHandler().onPresentingVessageSeted(oldValue, newVessage: nil)
            }else if oldValue?.vessageId == presentingVesseage.vessageId{
                return
            }
            else{
                self.generateVessageHandler(presentingVesseage.typeId).onPresentingVessageSeted(oldValue, newVessage: presentingVesseage)
            }
            
            if let startEventCmd = presentingVesseage?.getBodyDict()["startEventCmd"] as? String{
                BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(startEventCmd)
            }
            
            if let endEventCmd = oldValue?.getBodyDict()["endEventCmd"] as? String{
                BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(endEventCmd)
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
        }
    }
    
    //MARK: Notifications
    func onVessageReaded(a:NSNotification) {
        if let cmd = self.presentingVesseage?.getBodyDict()["readedEventCmd"] as? String{
            BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(cmd)
        }
        self.refreshBadge()
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