//
//  VideoVessageHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VideoVessageHandler:VessageHandlerBase,PlayerDelegate,HandleBahamutCmdDelegate {
    private var vessagePlayer:BahamutFilmView!
    
    override init(manager:PlayVessageManager,container:UIView) {
        super.init(manager: manager,container: container)
        vessagePlayer = BahamutFilmView(frame: container.bounds)
        vessagePlayer.fileFetcher = ServiceContainer.getFileService().getFileFetcherOfFileId(.Video)
        vessagePlayer.autoPlay = false
        vessagePlayer.isPlaybackLoops = false
        vessagePlayer.isMute = false
        vessagePlayer.showTimeLine = false
        vessagePlayer.delegate = self
        BahamutCmdManager.sharedInstance.registHandler(self)
    }
    
    override func releaseHandler() {
        super.releaseHandler()
        BahamutCmdManager.sharedInstance.removeHandler(self)
        vessagePlayer.removeFromSuperview()
        vessagePlayer.delegate = nil
        vessagePlayer.releasePlayer()
    }
    
    override func onLeftVessageNumberUpdated(oldNumber: Int, newNumber: Int) {
        //TODO:
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?,newVessage:Vessage!) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        if let oldVsg = oldVessage{
            if oldVsg.typeId != newVessage.typeId {
                container.removeAllSubviews()
                initVessageViews()
            }
            UIAnimationHelper.animationPageCurlView(vessagePlayer, duration: 0.3, completion: { () -> Void in
                self.vessagePlayer.filePath = self.presentingVesseage.fileId
            })
        }else{
            initVessageViews()
            vessagePlayer.filePath = presentingVesseage.fileId
        }
        refreshConversationLabel()
    }
    
    private func refreshConversationLabel(){
        let friendTimeString = presentingVesseage.sendTime?.dateTimeOfAccurateString.toFriendlyString() ?? "UNKNOW_TIME".localizedString()
        let readStatus = presentingVesseage.isRead ? "VSG_READED".localizedString() : "VSG_UNREADED".localizedString()
        let info = "\(friendTimeString) \(readStatus)"
        
    }
    
    //private var vessagePlayer:BahamutFilmView!
    private func initVessageViews() {
        container.addSubview(vessagePlayer)
        container.sendSubviewToBack(vessagePlayer)
    }
    
    //MARK: Player Delegate
    
    func playerBufferingStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackDidEnd(player: Player) {
        self.vessagePlayer.filePath = nil
        self.vessagePlayer.filePath = self.presentingVesseage.fileId
        self.refreshConversationLabel()
        if let cmd = self.presentingVesseage.getBodyDict()["videoEndedEvent"] as? String{
            BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(cmd)
        }
    }
    
    func playerPlaybackStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
        if self.presentingVesseage?.isRead == false {
            MobClick.event("Vege_ReadVessage")
            ServiceContainer.getVessageService().readVessage(self.presentingVesseage)
        }
        if let cmd = self.presentingVesseage.getBodyDict()["videoStartedEvent"] as? String{
            BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(cmd)
        }
    }
    
    func playerReady(player: Player) {
        
    }
    
    func handleBahamutCmd(method: String, args: [String], object: AnyObject?) {
        switch method {
        case "maxVideoPlayer":
            if !self.vessagePlayer.isVideoFullScreen {
                self.vessagePlayer.switchFullScreenOnOff()
            }
        case "minVideoPlayer":
            if self.vessagePlayer.isVideoFullScreen {
                self.vessagePlayer.switchFullScreenOnOff()
            }
        default:
            break
        }
    }
}
