//
//  ImageVessageExtension.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/14.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
let ImageVessageImageWidth:CGFloat = 600
let ImageVessageImageQuality:CGFloat = 0.8

//MARK: Send Image Vessage Extension
extension ConversationViewController:UIImagePickerControllerDelegate,ChatSendContentConfirmControllerDelegate{
    
    func initSendImage() {
        let tapSendImage = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.onClickImageButton(_:)))
        self.sendImageButton.addGestureRecognizer(tapSendImage)
    }
    
    func onClickImageButton(_ sender: UITapGestureRecognizer) {
        self.view.isUserInteractionEnabled = false
        self.sendImageButton.animationMaxToMin(0.1, maxScale: 1.2) {
            self.view.isUserInteractionEnabled = true
            if self.outChatGroup {
                self.flashTips("NOT_IN_CHAT_GROUP".localizedString())
            }else {
                self.showSendImageAlert()
            }
        }
    }
    
    func showSendImageAlert() {
        let alert = UIImagePickerController.showUIImagePickerAlert(self, title: "SEND_IMAGE".localizedString(), message: "SELECT_IMG_SOURCE".localizedString())
        alert.delegate = self
    }
    
    //MARK:UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        picker.dismiss(animated: true)
        {
            ChatSendContentConfirmController.showConfirmView(self, contentImage: image, delegate: self)
            
        }
    }
    
    //MARK:ChatSendContentConfirmControllerDelegate
    func chatSendContentConfirmControllerSend(_ sender: ChatSendContentConfirmController, contentImage: UIImage?) {
        if let cimg = contentImage{
            let image = cimg.scaleToWidthOf(ImageVessageImageWidth, quality: ImageVessageImageQuality)
            let localPath = PersistentManager.sharedInstance.createTmpFileName(.image)
            let imageData = UIImageJPEGRepresentation(image,1)
            if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
            {
                self.setProgressSending()
                let chatterId = self.conversation.chatterId
                let vsg = Vessage()
                vsg.typeId = Vessage.typeImage
                vsg.body = self.getSendVessageBodyString([:])
                vsg.fileId = localPath
                let url = URL(fileURLWithPath: localPath)
                VessageQueue.sharedInstance.pushNewVessageTo(chatterId,isGroup: self.isGroupChat, vessage: vsg,taskSteps:SendVessageTaskSteps.fileVessageSteps, uploadFileUrl: url)
            }else{
                self.playCrossMark("PROCESS_IMAGE_ERROR".localizedString())
            }
        }
    }
    
    func chatSendContentConfirmControllerCancel(_ sender: ChatSendContentConfirmController) {
        
    }
}
