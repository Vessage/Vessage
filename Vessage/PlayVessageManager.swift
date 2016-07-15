//
//  PlayVessageManager.swift
//  Vessage
//
//  Created by AlexChow on 16/5/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: PlayVessageManager
class PlayVessageManager: ConversationViewControllerProxy,PlayerDelegate {
    private var vessagePlayer:BahamutFilmView!
    private func initVessageViews() {
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
    
    override func onSwitchToManager() {
        rightButton.setImage(UIImage(named: "playNext"), forState: .Normal)
        rightButton.setImage(UIImage(named: "playNext"), forState: .Highlighted)
        recordButton.setImage(UIImage(named: "chat"), forState: .Normal)
        recordButton.setImage(UIImage(named: "chat"), forState: .Highlighted)
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        initVessageViews()
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
            refreshTimeLabel()
        }
    }
    
    private var presentingVesseage:Vessage!{
        didSet{
            if presentingVesseage != nil{
                if oldValue != nil && oldValue.vessageId == presentingVesseage.vessageId{
                    return
                }
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

    private var badgeValue:Int = 0 {
        didSet{
            if badgeLabel != nil{
                if badgeValue == 0{
                    badgeLabel.hidden = true
                }else{
                    badgeLabel.text = "\(badgeValue)"
                    badgeLabel.hidden = false
                    badgeLabel.animationMaxToMin()
                }
            }
        }
    }
    
    override func onChatGroupUpdated(chatGroup: ChatGroup) {
        self.rootController.controllerTitle = chatGroup.groupName
    }
    
    override func onChatterUpdated(chatter: VessageUser) {
        super.onChatterUpdated(chatter)
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
    private func refreshTimeLabel(){
        if presentingVesseage != nil{
            vessageSendTimeLabel.hidden = false
            let friendTimeString = presentingVesseage.sendTime.dateTimeOfAccurateString.toFriendlyString()
            let readStatus = presentingVesseage.isRead ? "VSG_READED".localizedString() : "VSG_UNREADED".localizedString()
            vessageSendTimeLabel.text = "\(friendTimeString) \(readStatus)"
        }else{
            vessageSendTimeLabel.hidden = true
        }
        
    }
    
    private func refreshBadge(){
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
            MobClick.event("Vege_ReadVessage")
            self.vessageService.readVessage(self.presentingVesseage)
            refreshBadge()
            
        }
    }
    
    func playerReady(player: Player) {
        
    }

    
}