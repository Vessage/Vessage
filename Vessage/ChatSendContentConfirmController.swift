//
//  ChatSendContentConfirmController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/3.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

protocol ChatSendContentConfirmControllerDelegate {
    func chatSendContentConfirmControllerCancel(_ sender:ChatSendContentConfirmController)
    func chatSendContentConfirmControllerSend(_ sender:ChatSendContentConfirmController,contentImage:UIImage?)
}

class ChatSendContentConfirmController: UIViewController {
    @IBOutlet weak var bcgMaskView: UIView!
    @IBOutlet weak var contentView: UIImageView!{
        didSet{
            contentView.clipsToBounds = true
            contentView.contentMode = .scaleAspectFill
            contentView.image = contentImage
            let tapContentView = UITapGestureRecognizer(target: self, action: #selector(ChatSendContentConfirmController.onTapContentView(_:)))
            contentView.addGestureRecognizer(tapContentView)
            contentView.isUserInteractionEnabled = true
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
        bcgMaskView.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bcgMaskView.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.bcgMaskView.isHidden = false
    }
    
    @IBAction func onCancelClick(_ sender: AnyObject) {
        self.dismiss(animated: true) {
            self.delegate?.chatSendContentConfirmControllerCancel(self)
        }
    }
    
    func onTapContentView(_ ges:UITapGestureRecognizer) {
        contentView.slideShowFullScreen(self)
    }
    
    @IBAction func onSendClick(_ sender: AnyObject) {
        self.dismiss(animated: true) { 
            self.delegate?.chatSendContentConfirmControllerSend(self,contentImage: self.contentImage)
        }
    }
    
    @discardableResult
    static func showConfirmView(_ vc:UIViewController,contentImage:UIImage,delegate:ChatSendContentConfirmControllerDelegate) -> ChatSendContentConfirmController {
        let controller = instanceFromStoryBoard("Conversation", identifier: "ChatSendContentConfirmController") as! ChatSendContentConfirmController
        controller.delegate = delegate
        controller.contentImage = contentImage
        
        let nvc = UINavigationController(rootViewController: controller)
        nvc.providesPresentationContextTransitionStyle = true
        nvc.definesPresentationContext = true
        nvc.modalPresentationStyle = .overCurrentContext
        
        vc.present(nvc, animated: true, completion: nil)
        return controller
    }
}
