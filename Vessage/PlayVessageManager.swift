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
    
    var haveNextVessage:Bool{
        return notReadVessages.count > 1
    }
    
    var isPresentingVessage:Bool{
        return self.presentingVesseage != nil
    }
    
    private var flashTipsView:UILabel!{
        didSet{
            flashTipsView.clipsToBounds = true
            flashTipsView.layer.cornerRadius = 6
            flashTipsView.textColor = UIColor.orangeColor()
            flashTipsView.textAlignment = .Center
            flashTipsView.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.1)
        }
    }
    
    private var vessageHandlerFactory:VessageHandlerFactory!
    
    func flashTips(msg:String) {
        if flashTipsView == nil {
            flashTipsView = UILabel()
        }
        self.flashTipsView.text = msg
        self.flashTipsView.sizeToFit()
        let center = CGPointMake(self.rootController.view.frame.width / 2, self.vessageView.frame.origin.y - 10 - self.flashTipsView.frame.height / 2)
        self.flashTipsView.center = center
        self.rootController.view.addSubview(self.flashTipsView)
        UIAnimationHelper.flashView(self.flashTipsView, duration: 0.4, autoStop: true, stopAfterMs: 1600){
            self.flashTipsView.removeFromSuperview()
        }
    }
    
    private func generateNoVessageHandler() -> VessageHandler{
        return vessageHandlerFactory.generateNoVessageHandler()
    }
    
    private func generateVessageHandler(typeId:Int) -> VessageHandler{
        return vessageHandlerFactory.generateVessageHandler(typeId)
    }
    
    override func onSwitchToManager() {
        rightButton.hidden = false
        rightButton.setImage(UIImage(named: "image_chat_btn"), forState: .Normal)
        rightButton.setImage(UIImage(named: "image_chat_btn"), forState: .Highlighted)
        recordButton.setImage(UIImage(named: "chat"), forState: .Normal)
        recordButton.setImage(UIImage(named: "chat"), forState: .Highlighted)
        refreshNextButton()
        super.onSwitchToManager()
    }
    
    override func onReleaseManager() {
        ServiceContainer.getVessageService().removeObserver(self)
        vessageHandlerFactory.release()
        super.onReleaseManager()
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        vessageService.addObserver(self, selector: #selector(PlayVessageManager.onVessageReaded(_:)), name: VessageService.onVessageRead, object: nil)
        vessageHandlerFactory = VessageHandlerFactory(manager: self, vessageView: self.vessageView)
        loadNotReadVessages()
    }
    
    override func onPanGesture(v: CGPoint) {
        (currentVessageHandler as? HandlePanGesture)?.onPan(v)
    }
    
    private var notReadVessages = [Vessage](){
        didSet{
            presentingVesseage = getNeedPresentVessage()
            refreshNextButton()
            refreshBadge()
        }
    }
    
    private func getNeedPresentVessage() -> Vessage?{
        if notReadVessages.count > 0{
            return notReadVessages.first
        }else{
            if let chatterId = self.conversation?.chatterId{
                if let newestVsg = vessageService.getCachedNewestVessage(chatterId){
                    notReadVessages.append(newestVsg)
                    return newestVsg
                }
            }
        }
        return nil
    }
    
    private var currentVessageHandler:VessageHandler!
    
    private var presentingVesseage:Vessage!{
        didSet{
            if presentingVesseage == nil{
                currentVessageHandler = self.generateNoVessageHandler()
                
            }else if oldValue?.vessageId == presentingVesseage.vessageId{
                return
            }else{
                currentVessageHandler = self.generateVessageHandler(presentingVesseage.typeId)
            }
            
            currentVessageHandler?.onPresentingVessageSeted(oldValue, newVessage: presentingVesseage)
            
            if let startEventCmd = presentingVesseage?.getBodyDict()["startEventCmd"] as? String{
                BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(startEventCmd)
            }
            
            if let endEventCmd = oldValue?.getBodyDict()["endEventCmd"] as? String{
                BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(endEventCmd)
            }
        }
    }
    
    static let sendingVessageDisppearTimeMs:UInt64 = 10000
    
    var sendingVessage:Vessage!{
        didSet{
            if sendingVessage == nil {
                presentingVesseage = getNeedPresentVessage()
            }else{
                presentingVesseage = sendingVessage
                dispatch_main_queue_after(PlayVessageManager.sendingVessageDisppearTimeMs, handler: {
                    if let vsgView = self.vessageView{
                        if (self.presentingVesseage?.isMySendingVessage() ?? false) {
                            self.presentingVesseage = self.getNeedPresentVessage()
                            vsgView.alpha = 0.3
                            UIView.animateWithDuration(0.2, animations: {
                                vsgView.alpha = 1
                            })
                        }
                    }
                })
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
            refreshNextButton()
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
    func refreshNextButton() {
        self.nextVessageButton?.hidden = !haveNextVessage
    }
    
    func refreshBadge(){
        self.badgeValue = notReadVessages.filter{!$0.isRead}.count
    }
    
    func showNextVessage() {
        if !haveNextVessage {
            return
        }
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
    
    private func loadNextVessage(){
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
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
}
