//
//  ImageBubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ImageBubbleVessageHandler: NSObject,BubbleVessageHandler {
    static let viewPool:ViewPool<ImageVessageContainer> = {
        return ViewPool<ImageVessageContainer>()
    }()
    class ImageVessageContainer: UIView {
        fileprivate var imageLoaded = false
        weak fileprivate var vessage:Vessage!
        weak fileprivate var vc:UIViewController?
        
        fileprivate var imageView:UIImageView
        fileprivate var dateTimeLabel:UILabel
        fileprivate var loadingIndicator:UIActivityIndicatorView
        
        override init(frame: CGRect) {
            self.dateTimeLabel = UILabel()
            self.dateTimeLabel.textColor = UIColor.white
            self.dateTimeLabel.font = UIFont.systemFont(ofSize: 10)
            self.imageView = UIImageView()
            self.loadingIndicator = UIActivityIndicatorView()
            self.loadingIndicator.hidesWhenStopped = true
            self.loadingIndicator.stopAnimating()
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .scaleAspectFill
            super.init(frame: frame)
            self.addSubview(imageView)
            self.addSubview(loadingIndicator)
            self.addSubview(dateTimeLabel)
            self.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(ImageVessageContainer.onTapImage(_:))))
        }
        
        override func removeFromSuperview() {
            super.removeFromSuperview()
            vc = nil
            vessage = nil
            imageView.image = nil
            dateTimeLabel.text = nil
            imageLoaded = false
            loadingIndicator.stopAnimating()
        }
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            imageView.frame.size = rect.size
            let x = (rect.width - 20) / 2
            let y = (rect.height - 20) / 2
            self.loadingIndicator.frame = CGRect(x: x, y: y, width: 20, height: 20)
            if let spv = dateTimeLabel.superview{
                dateTimeLabel.frame.origin.x = spv.frame.width - 6 - dateTimeLabel.frame.width
                dateTimeLabel.frame.origin.y = spv.frame.height - 2 - dateTimeLabel.frame.height
            }
        }
        
        func initVessageContentView(_ vc:UIViewController,vessage:Vessage) {
            self.vc = vc
            self.vessage = vessage
            self.imageLoaded = false
        }
        
        fileprivate func updateDateLabel() {
            dateTimeLabel.sizeToFit()
            if let spv = dateTimeLabel.superview{
                dateTimeLabel.frame.origin.x = spv.frame.width - 6 - dateTimeLabel.frame.width
                dateTimeLabel.frame.origin.y = spv.frame.height - 2 - dateTimeLabel.frame.height
            }
        }
        
        func onTapImage(_ ges:UITapGestureRecognizer) {
            if let controller = self.vc {
                if imageLoaded {
                    imageView.slideShowFullScreen(controller,allowSaveImage: true)
                }else{
                    refreshImage()
                }
            }
        }
        
        fileprivate func refreshImage(){
            if let vsg = self.vessage{
                self.dateTimeLabel.text = vsg.getSendTime()?.toFriendlyString()
                self.dateTimeLabel.layoutIfNeeded()
                self.updateDateLabel()
                if vsg.isMySendingVessage() {
                    self.imageView.image = UIImage(contentsOfFile: vsg.fileId)
                    imageLoaded = true
                }else{
                    imageLoaded = false
                    self.loadingIndicator.startAnimating()
                    ServiceContainer.getFileService().setImage(self.imageView, iconFileId: vessage.fileId,defaultImage: UIImage(named: "vg_default_bcg_2")!){ suc in
                        if self.vessage.vessageId == vsg.vessageId{
                            self.imageLoaded = suc
                            self.loadingIndicator.stopAnimating()
                        }
                    }
                }
                
            }
            
        }
        
        convenience init() {
            self.init(frame:CGRect.zero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    static let defaultSize = CGSize(width: 128, height: 168)
    
    func getContentViewSize(_ vc:UIViewController,vessage: Vessage, maxLimitedSize: CGSize, contentView: UIView) -> CGSize {
        let defaultWidth = ImageBubbleVessageHandler.defaultSize.width
        let defaultHeight = ImageBubbleVessageHandler.defaultSize.height
        
        if maxLimitedSize.width >= defaultWidth && maxLimitedSize.height >= defaultHeight {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }else if maxLimitedSize.height > maxLimitedSize.width {
            return CGSize(width: maxLimitedSize.width, height: maxLimitedSize.width * defaultHeight / defaultWidth)
        }else if maxLimitedSize.width > maxLimitedSize.height{
            return CGSize(width: maxLimitedSize.height * defaultWidth / defaultHeight, height: maxLimitedSize.height)
        }
        return CGSize.zero
    }
    
    func getContentView(_ vc:UIViewController,vessage: Vessage) -> UIView {
        if let view = ImageBubbleVessageHandler.viewPool.getFreeView() {
            view.initVessageContentView(vc, vessage: vessage)
            return view
        }else{
            let view = ImageVessageContainer()
            view.initVessageContentView(vc, vessage: vessage)
            ImageBubbleVessageHandler.viewPool.pushNewPooledView(view)
            return view
        }
    }
    
    func presentContent(_ vc:UIViewController, vessage: Vessage, contentView: UIView) {
        if let c = contentView as? ImageVessageContainer{
            c.refreshImage()
        }
    }
}
