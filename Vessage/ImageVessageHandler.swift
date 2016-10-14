//
//  ImageVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ImageVessageHandler: VessageHandlerBase {
    private var imageView:UIImageView!
    
    override init(manager: PlayVessageManager, container: UIView) {
        super.init(manager: manager, container: container)
        container.layoutIfNeeded()
        imageView = UIImageView(frame:container.bounds)
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = true
        imageView.contentMode = .ScaleAspectFill
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(ImageVessageHandler.onTapImage(_:))))
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage!) {
        
        if let oldVsg = oldVessage{
            if oldVsg.typeId != newVessage.typeId {
                container.removeAllSubviews()
                initVessageViews()
                
            }
            UIAnimationHelper.animationPageCurlView(imageView, duration: 0.3, completion: { () -> Void in
                ServiceContainer.getFileService().setImage(self.imageView, iconFileId: newVessage.fileId){ suc in
                    if suc{
                        ServiceContainer.getVessageService().readVessage(newVessage)
                    }
                }
            })
        }else{
            initVessageViews()
            ServiceContainer.getFileService().setImage(self.imageView, iconFileId: newVessage.fileId){ suc in
                if suc{
                    ServiceContainer.getVessageService().readVessage(newVessage)
                }
            }
        }
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        self.imageView?.slideShowFullScreen(self.playVessageManager.rootController)
    }
    
    private func initVessageViews() {
        container.addSubview(imageView)
        container.sendSubviewToBack(imageView)
    }
}
