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

    private var finished = [Bool](count: 4, repeatedValue: false)
    private var postedFileId:String?
    
    @IBOutlet weak var imageView: UIImageView!
    private var vgMaskLabel:UILabel!{
        didSet{
            vgMaskLabel.text = "VG聊天"
            vgMaskLabel.font = UIFont(name: "ChalkboardSE-Regular",size: 10) ?? UIFont.systemFontOfSize(10)
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
        imageView?.userInteractionEnabled = true
        imageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TIMShareAndSaveViewController.onTapImageView(_:))))
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
    
    func onTapImageView(ges:UITapGestureRecognizer) {
        self.imageView?.slideShowFullScreen(self)
    }
    
    @IBAction func onClickDone(sender: AnyObject) {
        var finish = false
        for f in finished {
            if f {
                finish = true
            }
        }
        if finish {
            self.dismissViewControllerAnimated(true, completion: nil)
        }else{
            let ok = UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (ac) in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            self.showAlert(nil, msg: "IMAGE_NOT_SAVED_OR_SHARED".TIMString, actions: [ok,ALERT_ACTION_CANCEL])
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
    }
}

extension TIMShareAndSaveViewController:SNSPostNewImageDelegate{
    
    @IBAction func shareToSNS(sender: AnyObject) {
        if !finished[1] {
            if let img = image{
                shareImageToSNS(img)
            }
        }else{
            self.showAlert(nil, msg: "IMAGE_SHARED_ONCE".TIMString)
        }
    }
    
    func shareImageToSNS(image:UIImage) {
        if String.isNullOrWhiteSpace(self.postedFileId) == false {
            SNSMainViewController.showSNSMainViewControllerWithNewPostImage(self.navigationController!, imageId: self.postedFileId!,image: image, sourceName: "TIM".TIMString,delegate: self)
        }else{
            SNSMainViewController.showSNSMainViewControllerWithNewPostImage(self.navigationController!, image: image, sourceName: "TIM".TIMString,delegate: self)
        }
    }
    
    func snsMainViewController(sender: SNSMainViewController, onImagePosted imageId: String!) {
        if imageId != nil {
            finished[1] = true
            self.postedFileId = imageId
        }
    }
}

extension TIMShareAndSaveViewController{
    
    @IBAction func shareToWXSession(sender: AnyObject) {
        if !finished[2] {
            if let img = getOutterAppImage(){
                shareImageToWxSession(img)
            }else{
                self.showAlert(nil, msg: "SAVE_IMAGE_ERROR".TIMString)
            }
        }else{
            self.showAlert(nil, msg: "IMAGE_SHARED_ONCE".TIMString)
        }
    }
    
    
    func shareImageToWxSession(image:UIImage) {
        let msg = WXMediaMessage()
        let ext = WXImageObject()
        ext.imageData = UIImageJPEGRepresentation(image, 1)
        msg.mediaObject = ext
        
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = msg
        req.scene = Int32(WXSceneTimeline.rawValue)
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

extension TIMShareAndSaveViewController{
    
    
    @IBAction func saveImage(sender: AnyObject) {
        if !finished[3] {
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
            finished[3] = true
        }else{
            self.showAlert(nil, msg: "SAVE_IMAGE_ERROR".TIMString)
        }
    }
}

/*
extension TIMShareAndSaveViewController:NFCPostNewImageDelegate{
    
    @IBAction func shareToNFC(sender: AnyObject) {
        if !finished[0] {
            if let img = image{
                shareImageToNFC(img)
            }
        }else{
            self.showAlert(nil, msg: "IMAGE_SHARED_ONCE".TIMString)
        }
    }
    
    func shareImageToNFC(image:UIImage) {
        if String.isNullOrWhiteSpace(self.postedFileId) == false {
            NFCMainViewController.showNFCMainViewControllerWithNewPostImage(self.navigationController!, imageId: self.postedFileId!, image: image, sourceName: "TIM".TIMString,delegate: self)
        }else{
            NFCMainViewController.showNFCMainViewControllerWithNewPostImage(self.navigationController!, image: image, sourceName: "TIM".TIMString,delegate: self)
        }
    }
    
    func nfcMainViewController(sender: NFCMainViewController, onImagePosted imageId: String!) {
        if imageId != nil {
            finished[0] = true
            self.postedFileId = imageId
        }
    }
}
*/
