//
//  FullScreenSlideshowViewControllerEx.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/27.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import ImageSlideshow

extension UIImageView{
    func slideShowFullScreen(vc:UIViewController,allowSaveImage:Bool = false,extraActions:[UIAlertAction]? = nil) {
        if let img = self.image {
            let slideshow = ImageSlideshow()
            slideshow.setImageInputs([ImageSource(image: img)])
            slideshow.pageControlPosition = .Hidden
            let ctr = FullScreenSlideshowViewController()
            // called when full-screen VC dismissed and used to set the page to our original slideshow
            ctr.pageSelected = { page in
                slideshow.setScrollViewPage(page, animated: false)
            }
            ctr.modalTransitionStyle = .CrossDissolve
            // set the initial page
            ctr.initialImageIndex = slideshow.scrollViewPage
            // set the inputs
            ctr.inputs = slideshow.images
            ctr.slideshow.pageControlPosition = .Hidden
            ctr.modalTransitionStyle = .CrossDissolve
            ctr.closeButton.hidden = true
            vc.presentViewController(ctr, animated: true){
                ctr.enableTapViewCloseController()
                if allowSaveImage{
                    ctr.enableLongPressImageAlert(allowSaveImage, extraAction: extraActions)
                }
            }
        }
    }
}

private var extraAlertActions = [UIAlertAction]()

extension FullScreenSlideshowViewController{
    func enableTapViewCloseController(hideCloseButton:Bool = true) {
        if hideCloseButton {
            self.closeButton.hidden = hideCloseButton
        }
        let ges = UITapGestureRecognizer(target: self, action: #selector(FullScreenSlideshowViewController.onTapView(_:)))
        ges.numberOfTapsRequired = 1
        self.slideshow.slideshowItems.forEach { (item) in
            if let iges = item.gestureRecognizer{
                ges.requireGestureRecognizerToFail(iges)
            }
        }
        self.view.addGestureRecognizer(ges)
    }
    
    func disableTapViewCloseController() {
        self.closeButton.hidden = false
        if let gess = self.view.gestureRecognizers{
            gess.forEach({ (ges) in
                if let g = ges as? UITapGestureRecognizer{
                    g.removeTarget(self, action: #selector(FullScreenSlideshowViewController.onTapView(_:)))
                }
            })
        }
    }
    
    func enableLongPressImageAlert(enableSaveImage:Bool,extraAction:[UIAlertAction]? = nil) {
        extraAlertActions.removeAll()
        
        if enableSaveImage {
            let action = UIAlertAction(title: "SAVE_IMG_TO_ALBUM".localizedString(), style: .Default, handler: { (ac) in
                if let img = self.slideshow.currentSlideshowItem?.imageView.image{
                    let seltor = #selector(FullScreenSlideshowViewController.didFinishSavingWithError(_:didFinishSavingWithError:contextInfo:))
                    UIImageWriteToSavedPhotosAlbum(img, self, seltor, nil)
                }
            })
            extraAlertActions.append(action)
        }
        
        if let acs = extraAction{
            extraAlertActions.appendContentsOf(acs)
        }
        
        let ges = UILongPressGestureRecognizer(target: self, action: #selector(FullScreenSlideshowViewController.onLongPressView(_:)))
        self.view.addGestureRecognizer(ges)
    }
    
    func onLongPressView(ges:UILongPressGestureRecognizer) {
        if ges.state == .Began {
            var actions = [UIAlertAction]()
            actions.appendContentsOf(extraAlertActions)
            actions.append(ALERT_ACTION_CANCEL)
            self.showAlert("SEL_OP".localizedString(), msg: nil, actions:actions)
        }
    }
    
    func didFinishSavingWithError(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error == nil{
            self.playCheckMark()
        }else{
            self.showAlert(nil, msg: "SAVE_IMAGE_ERROR".localizedString())
        }
    }
    
    func onTapView(tap:UITapGestureRecognizer) {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(page: slideshow.scrollViewPage)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
