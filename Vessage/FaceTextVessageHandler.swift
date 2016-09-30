//
//  FaceTextVessageHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/7/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class FaceTextViewFullScreenController: UIViewController {
    private var fullScrFaceTextView:FaceTextImageView!
    private var fileId:String!
    private var message:String!
    override func viewDidLoad() {
        super.viewDidLoad()
        let bcgImageView = UIImageView(image: getRandomConversationBackground())
        self.view.addSubview(bcgImageView)
        bcgImageView.frame = self.view.bounds
        fullScrFaceTextView = FaceTextImageView()
        fullScrFaceTextView.initContainer(self.view)
        self.view.addSubview(fullScrFaceTextView)
        fullScrFaceTextView.frame = self.view.bounds
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FaceTextViewFullScreenController.onTapFullScreenController(_:))))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fullScrFaceTextView.setTextImage(fileId, message: message)
    }
    
    func onTapFullScreenController(ges:UITapGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

class FaceTextVessageHandler: VessageHandlerBase {
    private var faceTextView:FaceTextImageView!
    
    override init(manager:PlayVessageManager,container:UIView) {
        super.init(manager: manager,container: container)
        self.faceTextView = FaceTextImageView()
        self.faceTextView.initContainer(container)
        let ges = UITapGestureRecognizer(target: self, action: #selector(FaceTextVessageHandler.onTapFaceTextView(_:)))
        ges.numberOfTapsRequired = 2
        self.faceTextView.addGestureRecognizer(ges)
    }
    
    func onTapFaceTextView(ges:UITapGestureRecognizer) {
        if self.faceTextView.imageLoaded {
            let controller = FaceTextViewFullScreenController()
            controller.modalTransitionStyle = .CrossDissolve
            let textMessage = self.presentingVesseage.getBodyDict()["textMessage"] as? String
            controller.message = textMessage
            controller.fileId = self.presentingVesseage.fileId
            self.playVessageManager.rootController.presentViewController(controller, animated: true){
                
            }
        }
    }
    
    override func onPresentingVessageSeted(oldVessage: Vessage?, newVessage: Vessage!) {
        super.onPresentingVessageSeted(oldVessage, newVessage: newVessage)
        container.removeAllSubviews()
        container.addSubview(self.faceTextView)
        container.sendSubviewToBack(self.faceTextView)
        let textMessage = newVessage.getBodyDict()["textMessage"] as? String
        self.faceTextView.setTextImage(newVessage.fileId, message: textMessage){
            ServiceContainer.getVessageService().readVessage(newVessage)
            if let cmd = self.presentingVesseage.getBodyDict()["textMessageShownEvent"] as? String{
                BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(cmd)
            }
        }
        refreshConversationLabel()
    }
    
    private func refreshConversationLabel(){
        let friendTimeString = presentingVesseage.sendTime?.dateTimeOfAccurateString.toFriendlyString() ?? "UNKNOW_TIME".localizedString()
        if presentingVesseage.isMySendingVessage() {
            playVessageManager.leftTopLabelText = "MY_SENDING_VSG".localizedString()
        }else{
            let readStatus = presentingVesseage.isRead ? "VSG_READED".localizedString() : "VSG_UNREADED".localizedString()
            playVessageManager.leftTopLabelText = "\(friendTimeString) \(readStatus)"
        }
        playVessageManager.rightBottomLabelText = nil
    }
    
    override func releaseHandler() {
        super.releaseHandler()
        self.faceTextView = nil
    }
}
