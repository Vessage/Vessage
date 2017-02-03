//
//  ImageBubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ImageBubbleVessageHandler: NSObject,BubbleVessageHandler {
    
    class ImageVessageContainer: UIView {
        private var imageLoaded = false
        weak private var vessage:Vessage!
        weak private var vc:UIViewController?
        
        private var imageView:UIImageView
        private var dateTimeLabel:UILabel
        private var loadingIndicator:UIActivityIndicatorView
        
        override init(frame: CGRect) {
            self.dateTimeLabel = UILabel()
            self.dateTimeLabel.textColor = UIColor.whiteColor()
            self.dateTimeLabel.font = UIFont.systemFontOfSize(10)
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
            self.addSubview(dateTimeLabel)
            self.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(ImageVessageContainer.onTapImage(_:))))
        }
        
        override func drawRect(rect: CGRect) {
            super.drawRect(rect)
            imageView.frame.size = rect.size
            let x = (rect.width - 20) / 2
            let y = (rect.height - 20) / 2
            self.loadingIndicator.frame = CGRectMake(x, y, 20, 20)
            if let spv = dateTimeLabel.superview{
                dateTimeLabel.frame.origin.x = spv.frame.width - 6 - dateTimeLabel.frame.width
                dateTimeLabel.frame.origin.y = spv.frame.height - 2 - dateTimeLabel.frame.height
            }
        }
        
        func initVessageContentView(vc:UIViewController,vessage:Vessage) {
            self.vc = vc
            self.vessage = vessage
            self.imageLoaded = false
        }
        
        private func updateDateLabel() {
            dateTimeLabel.sizeToFit()
            if let spv = dateTimeLabel.superview{
                dateTimeLabel.frame.origin.x = spv.frame.width - 6 - dateTimeLabel.frame.width
                dateTimeLabel.frame.origin.y = spv.frame.height - 2 - dateTimeLabel.frame.height
            }
        }
        
        func onTapImage(ges:UITapGestureRecognizer) {
            if let controller = self.vc {
                if imageLoaded {
                    imageView.slideShowFullScreen(controller)
                }else{
                    refreshImage()
                }
            }
        }
        
        private func refreshImage(){
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
                            if suc{
                                ServiceContainer.getVessageService().readVessage(vsg)
                            }
                        }
                    }
                }
                
            }
            
        }
        
        convenience init() {
            self.init(frame:CGRectZero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    static let defaultSize = CGSizeMake(128, 168)
    
    func getContentViewSize(vc:UIViewController,vessage: Vessage, maxLimitedSize: CGSize, contentView: UIView) -> CGSize {
        let defaultWidth = ImageBubbleVessageHandler.defaultSize.width
        let defaultHeight = ImageBubbleVessageHandler.defaultSize.height
        
        if maxLimitedSize.width >= defaultWidth && maxLimitedSize.height >= defaultHeight {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }else if maxLimitedSize.height > maxLimitedSize.width {
            return CGSize(width: maxLimitedSize.width, height: maxLimitedSize.width * defaultHeight / defaultWidth)
        }else if maxLimitedSize.width > maxLimitedSize.height{
            return CGSize(width: maxLimitedSize.height * defaultWidth / defaultHeight, height: maxLimitedSize.height)
        }
        return CGSizeZero
    }
    
    func getContentView(vc:UIViewController,vessage: Vessage) -> UIView {
        let container = ImageVessageContainer()
        container.initVessageContentView(vc, vessage: vessage)
        return container
    }
    
    func presentContent(vc:UIViewController, vessage: Vessage, contentView: UIView) {
        if let c = contentView as? ImageVessageContainer{
            c.refreshImage()
        }
    }
}
