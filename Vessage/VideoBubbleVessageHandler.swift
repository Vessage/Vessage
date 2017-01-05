//
//  VideoBubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class VideoBubbleVessageHandler: BubbleVessageHandler,PlayerDelegate,BahamutFilmViewDelegate {
    let defaultWidth:CGFloat = 180
    let defaultHeight:CGFloat = 240
    
    private var videoPlayer:BahamutFilmView!
    private var dateTimeLabel:UILabel!
    private var presentingVessage:Vessage!
    
    func getContentView(vessage: Vessage) -> UIView {
        if videoPlayer == nil {
            videoPlayer = BahamutFilmView()
            videoPlayer.autoPlay = false
            videoPlayer.isPlaybackLoops = false
            videoPlayer.isMute = false
            videoPlayer.showTimeLine = false
            videoPlayer.delegate = self
            dateTimeLabel = UILabel()
            dateTimeLabel.textColor = UIColor.whiteColor()
            dateTimeLabel.font = UIFont.systemFontOfSize(10)
            videoPlayer.addSubview(dateTimeLabel)
        }
        return videoPlayer
    }
    
    private func updateDateLabel(date:NSDate) {
        dateTimeLabel.text = date.toFriendlyString()
        refreshDateLabel()
    }
    
    private func refreshDateLabel(){
        dateTimeLabel.sizeToFit()
        if let spv = dateTimeLabel.superview{
            dateTimeLabel.frame.origin.x = spv.frame.width - 6 - dateTimeLabel.frame.width
            dateTimeLabel.frame.origin.y = spv.frame.height - 2 - dateTimeLabel.frame.height
            spv.bringSubviewToFront(dateTimeLabel)
        }
    }
    
    func getContentViewSize(vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        if maxLimitedSize.width >= defaultWidth && maxLimitedSize.height >= defaultHeight {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }else if maxLimitedSize.height > maxLimitedSize.width {
            return CGSize(width: maxLimitedSize.width, height: maxLimitedSize.width * defaultHeight / defaultWidth)
        }else if maxLimitedSize.width > maxLimitedSize.height{
            return CGSize(width: maxLimitedSize.height * defaultWidth / defaultHeight, height: maxLimitedSize.height)
        }
        return CGSizeZero
    }
    
    func presentContent(oldVessage: Vessage?, newVessage: Vessage,contentView:UIView) {
        if let videoPlayer = contentView  as? BahamutFilmView{
            self.presentingVessage = newVessage
            if newVessage.isMySendingVessage() {
                videoPlayer.fileFetcher = FilePathFileFetcher.shareInstance
            }else{
                videoPlayer.fileFetcher = ServiceContainer.getFileService().getFileFetcherOfFileId(.Video)
            }
            UIView.transitionWithView(videoPlayer, duration: 0.3, options: .TransitionCrossDissolve, animations: nil){ flag in
                videoPlayer.filePath = newVessage.fileId
            }
            if let d = newVessage.getSendTime(){
                updateDateLabel(d)
            }
        }
    }
    
    func bahamutFilmViewOnDraw(sender: BahamutFilmView, rect: CGRect) {
        refreshDateLabel()
    }
    
    //MARK: Player Delegate
    
    func playerBufferingStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackDidEnd(player: Player) {
        videoPlayer.filePath = nil
        videoPlayer.filePath = self.presentingVessage?.fileId
    }
    
    func playerPlaybackStateDidChange(player: Player) {
        
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
        if let vsg = self.presentingVessage{
            if vsg.isRead == false {
                ServiceContainer.getVessageService().readVessage(vsg)
            }
        }
    }
    
    func playerReady(player: Player) {
        
    }
}
