//
//  VideoBubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class VideoBubbleVessageHandler: BubbleVessageHandler {
    static let viewPool:ViewPool<VessageContentVideoPlayer> = {
        return ViewPool<VessageContentVideoPlayer>()
    }()
    
    static let defaultSize = CGSizeMake(168, 226)
    
    class VessageContentVideoPlayer: BahamutFilmView,BahamutFilmViewDelegate {
        private var dateTimeLabel:UILabel!
        weak var vessage:Vessage!
        func initVessageContentPlayer(vc:UIViewController,vessage:Vessage) {
            self.autoPlay = false
            self.isPlaybackLoops = false
            self.isMute = false
            self.showTimeLine = false
            self.delegate = self
            dateTimeLabel = UILabel()
            dateTimeLabel.textColor = UIColor.whiteColor()
            dateTimeLabel.font = UIFont.systemFontOfSize(10)
            self.addSubview(dateTimeLabel)
        }
        
        override func removeFromSuperview() {
            super.removeFromSuperview()
            vessage = nil
            filePath = nil
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
        
        
        func bahamutFilmViewOnDraw(sender: BahamutFilmView, rect: CGRect) {
            if let d = vessage?.getSendTime(){
                updateDateLabel(d)
            }
        }
        
        override func playerPlaybackDidEnd(player: Player) {
            super.playerPlaybackDidEnd(player)
            self.filePath = nil
            self.filePath = self.vessage?.fileId
        }
        
        override func playerPlaybackWillStartFromBeginning(player: Player) {
            super.playerPlaybackWillStartFromBeginning(player)
            if let vsg = self.vessage{
                if vsg.isRead == false {
                    ServiceContainer.getVessageService().readVessage(vsg)
                }
            }
        }
    }
    
    func getContentView(vc:UIViewController,vessage: Vessage) -> UIView {
        if let view = VideoBubbleVessageHandler.viewPool.getFreeView() {
            view.initVessageContentPlayer(vc, vessage: vessage)
            return view
        }else{
            let view = VessageContentVideoPlayer()
            view.initVessageContentPlayer(vc, vessage: vessage)
            VideoBubbleVessageHandler.viewPool.pushNewPooledView(view)
            return view
        }
    }
    
    func getContentViewSize(vc:UIViewController,vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        let defaultWidth = VideoBubbleVessageHandler.defaultSize.width
        let defaultHeight = VideoBubbleVessageHandler.defaultSize.height
        if maxLimitedSize.width >= defaultWidth && maxLimitedSize.height >= defaultHeight {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }else if maxLimitedSize.height > maxLimitedSize.width {
            return CGSize(width: maxLimitedSize.width, height: maxLimitedSize.width * defaultHeight / defaultWidth)
        }else if maxLimitedSize.width > maxLimitedSize.height{
            return CGSize(width: maxLimitedSize.height * defaultWidth / defaultHeight, height: maxLimitedSize.height)
        }
        return CGSizeZero
    }
    
    func presentContent(vc:UIViewController, vessage: Vessage,contentView:UIView) {
        if let videoPlayer = contentView as? VessageContentVideoPlayer{
            if vessage.isMySendingVessage() {
                videoPlayer.fileFetcher = FilePathFileFetcher.shareInstance
            }else{
                videoPlayer.fileFetcher = ServiceContainer.getFileService().getFileFetcherOfFileId(.Video)
            }
            UIView.transitionWithView(videoPlayer, duration: 0.3, options: .TransitionCrossDissolve, animations: nil){ flag in
                videoPlayer.filePath = vessage.fileId
            }
        }
    }
    
}
