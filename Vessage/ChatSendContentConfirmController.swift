//
//  ChatSendContentConfirmController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/3.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

protocol ChatSendContentConfirmControllerDelegate {
    func chatSendContentConfirmControllerCancel(sender:ChatSendContentConfirmController)
    func chatSendContentConfirmControllerSend(sender:ChatSendContentConfirmController,contentImage:UIImage?)
}

class ChatSendContentConfirmController: UIViewController {
    @IBOutlet weak var bcgMaskView: UIView!
    @IBOutlet weak var contentView: UIImageView!{
        didSet{
            contentView.contentMode = .ScaleAspectFill
            contentView.image = contentImage
        }
    }
    
    var contentImage:UIImage?{
        didSet{
            contentView?.image = contentImage
        }
    }
    
    var delegate:ChatSendContentConfirmControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bcgMaskView.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.bcgMaskView.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.bcgMaskView.hidden = false
    }
    
    @IBAction func onCancelClick(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) {
            self.delegate?.chatSendContentConfirmControllerCancel(self)
        }
    }
    
    @IBAction func onSendClick(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { 
            self.delegate?.chatSendContentConfirmControllerSend(self,contentImage: self.contentImage)
        }
    }
    
    static func showConfirmView(vc:UIViewController,contentImage:UIImage,delegate:ChatSendContentConfirmControllerDelegate) -> ChatSendContentConfirmController {
        let controller = instanceFromStoryBoard("Conversation", identifier: "ChatSendContentConfirmController") as! ChatSendContentConfirmController
        controller.delegate = delegate
        controller.contentImage = contentImage
        vc.presentViewController(controller, animated: true, completion: nil)
        return controller
    }
}
