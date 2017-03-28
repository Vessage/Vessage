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
    
    static let defaultSize = CGSize(width: 168, height: 226)
    
    class VessageContentVideoPlayer: BahamutFilmView,BahamutFilmViewDelegate {
        fileprivate var dateTimeLabel:UILabel!
        weak var vessage:Vessage!
        func initVessageContentPlayer(_ vc:UIViewController,vessage:Vessage) {
            self.autoPlay = false
            self.isPlaybackLoops = false
            self.isMute = false
            self.showTimeLine = false
            self.delegate = self
            dateTimeLabel = UILabel()
            dateTimeLabel.textColor = UIColor.white
            dateTimeLabel.font = UIFont.systemFont(ofSize: 10)
            self.addSubview(dateTimeLabel)
        }
        
        override func removeFromSuperview() {
            super.removeFromSuperview()
            vessage = nil
            filePath = nil
        }
        
        fileprivate func updateDateLabel(_ date:Date) {
            dateTimeLabel.text = date.toFriendlyString()
            refreshDateLabel()
        }
        
        fileprivate func refreshDateLabel(){
            dateTimeLabel.sizeToFit()
            if let spv = dateTimeLabel.superview{
                dateTimeLabel.frame.origin.x = spv.frame.width - 6 - dateTimeLabel.frame.width
                dateTimeLabel.frame.origin.y = spv.frame.height - 2 - dateTimeLabel.frame.height
                spv.bringSubview(toFront: dateTimeLabel)
            }
        }
        
        
        func bahamutFilmViewOnDraw(_ sender: BahamutFilmView, rect: CGRect) {
            if let d = vessage?.getSendTime(){
                updateDateLabel(d as Date)
            }
        }
        
        override func playerPlaybackDidEnd(_ player: Player) {
            super.playerPlaybackDidEnd(player)
            self.filePath = nil
            self.filePath = self.vessage?.fileId
        }
        
        override func playerPlaybackWillStartFromBeginning(_ player: Player) {
            super.playerPlaybackWillStartFromBeginning(player)
        }
    }
    
    func getContentView(_ vc:UIViewController,vessage: Vessage) -> UIView {
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
    
    func getContentViewSize(_ vc:UIViewController,vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        let defaultWidth = VideoBubbleVessageHandler.defaultSize.width
        let defaultHeight = VideoBubbleVessageHandler.defaultSize.height
        if maxLimitedSize.width >= defaultWidth && maxLimitedSize.height >= defaultHeight {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }else if maxLimitedSize.height > maxLimitedSize.width {
            return CGSize(width: maxLimitedSize.width, height: maxLimitedSize.width * defaultHeight / defaultWidth)
        }else if maxLimitedSize.width > maxLimitedSize.height{
            return CGSize(width: maxLimitedSize.height * defaultWidth / defaultHeight, height: maxLimitedSize.height)
        }
        return CGSize.zero
    }
    
    func presentContent(_ vc:UIViewController, vessage: Vessage,contentView:UIView) {
        if let videoPlayer = contentView as? VessageContentVideoPlayer{
            if vessage.isMySendingVessage() {
                videoPlayer.fileFetcher = FilePathFileFetcher.shareInstance
            }else{
                videoPlayer.fileFetcher = ServiceContainer.getFileService().getFileFetcherOfFileId(.video)
            }
            UIView.transition(with: videoPlayer, duration: 0.3, options: .transitionCrossDissolve, animations: nil){ flag in
                videoPlayer.filePath = vessage.fileId
            }
        }
    }
    
}
