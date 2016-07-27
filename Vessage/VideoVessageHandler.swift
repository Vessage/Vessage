//
//  VideoVessageHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VideoVessageHandler:VessageHandlerBase,PlayerDelegate {
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
    }
    
    override func releaseHandler() {
        super.releaseHandler()
        vessagePlayer.removeFromSuperview()
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?,newVessage:Vessage) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        if let oldVsg = oldVessage{
            if oldVsg.typeId != newVessage.typeId {
                container.subviews.forEach{$0.removeFromSuperview()}
                initVessageViews()
            }
            UIAnimationHelper.animationPageCurlView(vessagePlayer, duration: 0.3, completion: { () -> Void in
                self.vessagePlayer.filePath = nil
                self.vessagePlayer.filePath = self.presentingVesseage.fileId
            })
        }else{
            initVessageViews()
            vessagePlayer.filePath = presentingVesseage.fileId
        }
        refreshConversationLabel(newVessage)
    }
    
    private func refreshConversationLabel(presentingVesseage:Vessage){
        let friendTimeString = presentingVesseage.sendTime?.dateTimeOfAccurateString.toFriendlyString() ?? "UNKNOW_TIME".localizedString()
        let readStatus = presentingVesseage.isRead ? "VSG_READED".localizedString() : "VSG_UNREADED".localizedString()
        playVessageManager.rightBottomLabelText = "\(friendTimeString) \(readStatus)"
        playVessageManager.leftTopLabelText = nil
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
    }
    
    func playerPlaybackStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
        if self.presentingVesseage?.isRead == false {
            MobClick.event("Vege_ReadVessage")
            ServiceContainer.getVessageService().readVessage(self.presentingVesseage)
            playVessageManager.refreshBadge()
            
        }
    }
    
    func playerReady(player: Player) {
        
    }
}
