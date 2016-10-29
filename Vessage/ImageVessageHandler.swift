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
    private var loadingIndicator:UIActivityIndicatorView!
    private var imageLoaded = false
    
    override init(manager: PlayVessageManager, container: UIView) {
        super.init(manager: manager, container: container)
        container.layoutIfNeeded()
        imageView = UIImageView(frame:container.bounds)
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = true
        imageView.contentMode = .ScaleAspectFill
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(ImageVessageHandler.onTapImage(_:))))
        self.loadingIndicator = UIActivityIndicatorView()
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage!) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        if let oldVsg = oldVessage{
            if oldVsg.typeId != newVessage.typeId {
                container.removeAllSubviews()
                initVessageViews()
            }
            refreshImage()
        }else{
            initVessageViews()
            refreshImage()
        }
    }
    
    private func refreshImage(){
        imageLoaded = false
        showLoadingIndicator()
        ServiceContainer.getFileService().setImage(self.imageView, iconFileId: presentingVesseage.fileId,defaultImage: UIImage(named: "recording_bcg_0")!){ suc in
            self.imageLoaded = suc
            if suc{
                ServiceContainer.getVessageService().readVessage(self.presentingVesseage)
                self.loadingIndicator.removeFromSuperview()
            }else{
                self.loadingIndicator.stopAnimating()
            }
        }
        refreshConversationLabel()
    }
    
    private func showLoadingIndicator(){
        self.container.addSubview(self.loadingIndicator)
        let x = (self.container.frame.width - 20) / 2
        let y = (self.container.frame.height - 20) / 2
        self.loadingIndicator.frame = CGRectMake(x, y, 20, 20)
        container.bringSubviewToFront(self.loadingIndicator)
        self.loadingIndicator.startAnimating()
        self.loadingIndicator.hidesWhenStopped = false
    }
    
    private func refreshConversationLabel(){
        if presentingVesseage.isMySendingVessage() {
            let msg = "MY_SENDING_VSG".localizedString()
        }else{
            let friendTimeString = presentingVesseage.sendTime?.dateTimeOfAccurateString.toFriendlyString() ?? "UNKNOW_TIME".localizedString()
            
        }
        
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        if imageLoaded {
            self.imageView?.slideShowFullScreen(self.playVessageManager.rootController)
        }else{
            refreshImage()
        }
    }
    
    private func initVessageViews() {
        container.addSubview(imageView)
        container.sendSubviewToBack(imageView)
    }
}
