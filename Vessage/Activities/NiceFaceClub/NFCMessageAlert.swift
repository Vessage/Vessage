//
//  NFCMessageAlert.swift
//  Vessage
//
//  Created by AlexChow on 16/8/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class NFCMessageAlert:UIViewController{
    
    
    @IBOutlet weak var continueButton: UIButton!{
        didSet{
            continueButton.layer.cornerRadius = 6
            continueButton.layer.borderColor = UIColor.orangeColor().CGColor
            continueButton.layer.borderWidth = 1
            
            continueButton.superview?.layer.cornerRadius = 6
            continueButton.superview?.layer.borderColor = UIColor.orangeColor().CGColor
            continueButton.superview?.layer.borderWidth = 1
        }
    }
    
    @IBOutlet weak var shareTipsLabel: UILabel!
    @IBOutlet weak var bcgMaskView: UIView!
    var onCloseHandler:((NFCMessageAlert)->Void)?
    var onTestScoreHandler:((NFCMessageAlert)->Void)?
    
    var alertTitle:String!{
        didSet{
            titleLabel?.text = alertTitle
        }
    }
    
    var alertMessage:String!{
        didSet{
            messageLabel?.text = alertTitle
        }
    }
    
    @IBOutlet weak var shareButton: UIButton!{
        didSet{
            shareButton.layer.cornerRadius = 6
            shareButton.layer.borderColor = UIColor.orangeColor().CGColor
            shareButton.layer.borderWidth = 1
            if NiceFaceClubManager.faceScoreAddition {
                shareButton.setImage(UIImage(named: "nice_face_shared")!, forState: .Normal)
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.text = alertTitle
        }
    }
    @IBOutlet weak var messageLabel: UILabel!{
        didSet{
            messageLabel.text = alertMessage
        }
    }
    
    @IBAction func onClose(sender: AnyObject) {
        if let handler = onCloseHandler{
            handler(self)
        }else{
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func onClickShare(sender: AnyObject) {
        ShareHelper.instance.showTellVegeToFriendsAlert(self, message: "SHARE_NICE_FACE_CLUB_MSG".niceFaceClubString, alertMsg: "SHARE_VG_ALERT_MSG".niceFaceClubString, title: "NICE_FACE_CLUB".niceFaceClubString)
        #if DEBUG
            self.onShareSuccess(NSNotification(name: ShareHelper.onShareSuccess, object: nil))
        #endif
    }
    
    @IBAction func onClickTestFace(sender: AnyObject) {
        if let handler = onTestScoreHandler{
            handler(self)
        }else{
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ShareHelper.instance.addObserver(self, selector: #selector(NFCMessageAlert.onShareSuccess(_:)), name: ShareHelper.onShareSuccess, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        bcgMaskView.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        bcgMaskView.hidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        bcgMaskView.hidden = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        ShareHelper.instance.removeObserver(self)
    }
    
    func onShareSuccess(a:NSNotification) {
        NiceFaceClubManager.faceScoreAddition = true
        shareButton.setImage(UIImage(named: "nice_face_shared")!, forState: .Normal)
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    static func showNFCMessageAlert(vc:UIViewController, title:String?, message:String?) -> NFCMessageAlert{
        let controller = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCMessageAlert") as! NFCMessageAlert
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.modalPresentationStyle = .OverCurrentContext
        controller.alertMessage = message
        controller.alertTitle = title
        vc.presentViewController(controller, animated: true) {
            
        }
        return controller
    }
}