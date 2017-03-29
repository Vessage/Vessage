//
//  FullScreenSlideshowViewControllerEx.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/27.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import ImageSlideshow

class FullScreenSlideshowViewControllerEx: FullScreenSlideshowViewController {
    private var shown = false{
        didSet{
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shown = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shown = true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .none
    }
    
    override var prefersStatusBarHidden: Bool{
        if shown {
            return true
        }else{
            return false
        }
    }
}

extension UIImageView{
    
    func slideShowFullScreen(_ vc:UIViewController,allowSaveImage:Bool = false,extraActions:[UIAlertAction]? = nil) {
        if let img = self.image {
            let slideshow = ImageSlideshow()
            slideshow.setImageInputs([ImageSource(image: img)])
            slideshow.pageControlPosition = .hidden
            let ctr = FullScreenSlideshowViewControllerEx()
            // called when full-screen VC dismissed and used to set the page to our original slideshow
            ctr.pageSelected = { page in
                slideshow.setScrollViewPage(page, animated: false)
            }
            ctr.modalTransitionStyle = .crossDissolve
            // set the initial page
            ctr.initialPage =  slideshow.scrollViewPage
            // set the inputs
            ctr.inputs = slideshow.images
            ctr.slideshow.pageControlPosition = .hidden
            ctr.closeButton.isHidden = true
            vc.present(ctr, animated: true){
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
    func enableTapViewCloseController(_ hideCloseButton:Bool = true) {
        if hideCloseButton {
            self.closeButton.isHidden = hideCloseButton
        }
        let ges = UITapGestureRecognizer(target: self, action: #selector(FullScreenSlideshowViewController.onTapView(_:)))
        ges.numberOfTapsRequired = 1
        self.slideshow.slideshowItems.forEach { (item) in
            if let iges = item.gestureRecognizer{
                ges.require(toFail: iges)
            }
        }
        self.view.addGestureRecognizer(ges)
    }
    
    func disableTapViewCloseController() {
        self.closeButton.isHidden = false
        if let gess = self.view.gestureRecognizers{
            gess.forEach({ (ges) in
                if let g = ges as? UITapGestureRecognizer{
                    g.removeTarget(self, action: #selector(FullScreenSlideshowViewController.onTapView(_:)))
                }
            })
        }
    }
    
    func enableLongPressImageAlert(_ enableSaveImage:Bool,extraAction:[UIAlertAction]? = nil) {
        extraAlertActions.removeAll()
        
        if enableSaveImage {
            let action = UIAlertAction(title: "SAVE_IMG_TO_ALBUM".localizedString(), style: .default, handler: { (ac) in
                if let img = self.slideshow.currentSlideshowItem?.imageView.image{
                    let seltor = #selector(FullScreenSlideshowViewController.didFinishSavingWithError(_:didFinishSavingWithError:contextInfo:))
                    UIImageWriteToSavedPhotosAlbum(img, self, seltor, nil)
                }
            })
            extraAlertActions.append(action)
        }
        
        if let acs = extraAction{
            extraAlertActions.append(contentsOf: acs)
        }
        
        let ges = UILongPressGestureRecognizer(target: self, action: #selector(FullScreenSlideshowViewController.onLongPressView(_:)))
        self.view.addGestureRecognizer(ges)
    }
    
    func onLongPressView(_ ges:UILongPressGestureRecognizer) {
        if ges.state == .began {
            var actions = [UIAlertAction]()
            actions.append(contentsOf: extraAlertActions)
            actions.append(ALERT_ACTION_CANCEL)
            self.showAlert("SEL_OP".localizedString(), msg: nil, actions:actions)
        }
    }
    
    func didFinishSavingWithError(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error == nil{
            self.playCheckMark()
        }else{
            self.showAlert(nil, msg: "SAVE_IMAGE_ERROR".localizedString())
        }
    }
    
    func onTapView(_ tap:UITapGestureRecognizer) {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(slideshow.scrollViewPage)
        }
        
        dismiss(animated: true, completion: nil)
    }
}
