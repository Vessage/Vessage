//
//  ImageBubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ImageBubbleVessageHandler: NSObject,BubbleVessageHandler,RequestPlayVessageManagerDelegate,UnloadPresentContentHandler {
    
    class ImageVessageContainer: UIView {
        private var imageView:UIImageView
        private var loadingIndicator:UIActivityIndicatorView
        override init(frame: CGRect) {
            self.imageView = UIImageView()
            self.loadingIndicator = UIActivityIndicatorView()
            self.loadingIndicator.hidesWhenStopped = true
            self.loadingIndicator.stopAnimating()
            imageView.clipsToBounds = true
            imageView.userInteractionEnabled = true
            imageView.contentMode = .ScaleAspectFill
            super.init(frame: frame)
            self.addSubview(imageView)
            self.addSubview(loadingIndicator)
        }
        
        override func drawRect(rect: CGRect) {
            super.drawRect(rect)
            imageView.frame.size = rect.size
            let x = (rect.width - 20) / 2
            let y = (rect.height - 20) / 2
            self.loadingIndicator.frame = CGRectMake(x, y, 20, 20)
        }
        
        convenience init() {
            self.init(frame:CGRectZero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private var imageLoaded = false
    
    private var vessage:Vessage!
    
    let defaultWidth:CGFloat = 180
    let defaultHeight:CGFloat = 240
    
    
    func getContentViewSize(vessage: Vessage, maxLimitedSize: CGSize, contentView: UIView) -> CGSize {
        if maxLimitedSize.width >= defaultWidth && maxLimitedSize.height > defaultHeight {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }else if maxLimitedSize.height > maxLimitedSize.width {
            return CGSize(width: maxLimitedSize.width, height: maxLimitedSize.width * defaultHeight / defaultWidth)
        }else if maxLimitedSize.width > maxLimitedSize.height{
            return CGSize(width: maxLimitedSize.height * defaultWidth / defaultHeight, height: maxLimitedSize.height)
        }
        return CGSizeZero
    }
    
    func getContentView(vessage: Vessage) -> UIView {
        let container = ImageVessageContainer()
        container.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(ImageBubbleVessageHandler.onTapImage(_:))))
        return container
    }
    
    func presentContent(oldVessage: Vessage?, newVessage: Vessage, contentView: UIView) {
        self.vessage = newVessage
        if let c = contentView as? ImageVessageContainer{
            refreshImage(c)
        }
    }
    
    func unloadPresentContent(vessage: Vessage) {
        self.vessage = nil
    }
    
    private var playVessageManager:PlayVessageManager?{
        return getPlayVessageManagerDelegate?.getPlayVessageManager()
    }
    
    private var getPlayVessageManagerDelegate:GetPlayVessageManagerDelegate?
    
    func setGetPlayVessageManagerDelegate(delegate: GetPlayVessageManagerDelegate) {
        self.getPlayVessageManagerDelegate = delegate
    }
    
    func unsetGetPlayVessageManagerDelegate() {
        self.getPlayVessageManagerDelegate = nil
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        if let c = ges.view as? ImageVessageContainer {
            if let controller = self.playVessageManager?.rootController{
                if imageLoaded {
                    c.imageView.slideShowFullScreen(controller)
                }else{
                    refreshImage(c)
                }
            }
            
        }
    }
    
    private func refreshImage(contentView:ImageVessageContainer){
        if let vsg = self.vessage{
            if vsg.isMySendingVessage() {
                contentView.imageView.image = UIImage(contentsOfFile: vsg.fileId)
                imageLoaded = true
            }else{
                imageLoaded = false
                contentView.loadingIndicator.startAnimating()
                ServiceContainer.getFileService().setImage(contentView.imageView, iconFileId: vessage.fileId,defaultImage: UIImage(named: "recording_bcg_0")!){ suc in
                    if self.vessage.vessageId == vsg.vessageId{
                        self.imageLoaded = suc
                        contentView.loadingIndicator.stopAnimating()
                        if suc{
                            ServiceContainer.getVessageService().readVessage(vsg)
                        }
                    }
                }
            }
            
        }
        
    }
}
