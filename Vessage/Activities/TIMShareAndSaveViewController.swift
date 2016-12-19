//
//  TIMShareAndSaveViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/18.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import AssetsLibrary

class TIMShareAndSaveViewController: UIViewController {

    private var finished = [Bool](count: 3, repeatedValue: false)
    @IBOutlet weak var imageView: UIImageView!
    private var vgMaskLabel:UILabel!{
        didSet{
            vgMaskLabel.text = "VG聊天"
            vgMaskLabel.font = UIFont.systemFontOfSize(11)
            vgMaskLabel.textColor = UIColor.lightTextColor()
        }
    }
    
    var image:UIImage?{
        didSet{
            imageView?.image = image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.image = image
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func getOutterAppImage() -> UIImage?{
        if vgMaskLabel == nil {
            vgMaskLabel = UILabel()
        }
        vgMaskLabel.sizeToFit()
        self.imageView.addSubview(vgMaskLabel)
        vgMaskLabel.frame.origin = CGPointMake(6, imageView.frame.height - 2 - vgMaskLabel.frame.height)
        if let img = self.imageView.viewToImage(){
            vgMaskLabel.removeFromSuperview()
            return img
        }
        vgMaskLabel.removeFromSuperview()
        return nil
    }
    
    @IBAction func onClickDone(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func shareToSNS(sender: AnyObject) {
        if !finished[0] {
            if let img = image{
                shareImageToSNS(img)
            }
        }else{
            self.showAlert(nil, msg: "IMAGE_SHARED_ONCE".TIMString)
        }
    }

    @IBAction func shareToWXSession(sender: AnyObject) {
        if !finished[1] {
            if let img = getOutterAppImage(){
                shareImageToWxSession(img)
            }else{
                self.showAlert(nil, msg: "SAVE_IMAGE_ERROR".TIMString)
            }
        }else{
            self.showAlert(nil, msg: "IMAGE_SHARED_ONCE".TIMString)
        }
    }
    
    @IBAction func saveImage(sender: AnyObject) {
        if !finished[2] {
            if let img = getOutterAppImage(){
                let seltor = #selector(TIMShareAndSaveViewController.didFinishSavingWithError(_:didFinishSavingWithError:contextInfo:))
                UIImageWriteToSavedPhotosAlbum(img, self, seltor, nil)
            }else{
                self.showAlert(nil, msg: "SAVE_IMAGE_ERROR".TIMString)
            }
        }else{
            self.showAlert(nil, msg: "IMAGE_SAVED_ONCE".TIMString)
        }
        
    }
    
    func didFinishSavingWithError(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error == nil{
            self.playCheckMark()
            finished[2] = true
        }else{
            self.showAlert(nil, msg: "SAVE_IMAGE_ERROR".TIMString)
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
    }
}

extension TIMShareAndSaveViewController:SNSPostNewImageDelegate{
    func shareImageToSNS(image:UIImage) {
        SNSMainViewController.showSNSMainViewControllerWithNewPostImage(self.navigationController!, image: image, sourceName: "TIM".TIMString,postNewImageDelegate: self)
    }
    
    func snsMainViewController(sender: SNSMainViewController, onImagePosted imageId: String!) {
        if imageId != nil {
            finished[0] = true
        }
    }
}

extension TIMShareAndSaveViewController{
    func shareImageToWxSession(image:UIImage) {
        let msg = WXMediaMessage()
        let ext = WXImageObject()
        ext.imageData = UIImageJPEGRepresentation(image, 1)
        msg.mediaObject = ext
        
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = msg
        req.scene = Int32(WXSceneSession.rawValue)
        MobClick.event("TIM_ShareWX")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TIMShareAndSaveViewController.onWXShareResponse(_:)), name: OnWXShareResponse, object: nil)
        WXApi.sendReq(req)
    }
    
    func onWXShareResponse(a:NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if let resp = a.userInfo?[kWXShareResponseValue] as? SendMessageToWXResp {
            if resp.errCode == WXSuccess.rawValue{
                finished[2]  = true
                playCheckMark()
            }else if resp.errCode == WXErrCodeUserCancel.rawValue{
                playCrossMark("CANCELED".localizedString(), async: false, completionHandler: nil)
            }else{
                playCrossMark("FAILED".localizedString(), async: false, completionHandler: nil)
            }
        }
    }
}
