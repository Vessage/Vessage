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
extension ConversationViewController:UIImagePickerControllerDelegate{
    func showSendImageAlert() {
        let alert = UIImagePickerController.showUIImagePickerAlert(self, title: "SEND_IMAGE".localizedString(), message: "SELECT_IMG_SOURCE".localizedString())
        alert.delegate = self
    }
    
    //MARK:UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        picker.dismissViewControllerAnimated(true)
        {
            let image = image.scaleToWidthOf(ImageVessageImageWidth, quality: ImageVessageImageQuality)
            let localPath = PersistentManager.sharedInstance.createTmpFileName(.Image)
            let imageData = UIImageJPEGRepresentation(image,1)
            if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
            {
                self.setProgressSending()
                let chatterId = self.conversation.chatterId
                let vsg = Vessage()
                vsg.isGroup = self.isGroupChat
                vsg.typeId = Vessage.typeImage
                vsg.body = self.getSendVessageBodyString([:])
                let url = NSURL(fileURLWithPath: localPath)
                VessageQueue.sharedInstance.pushNewVessageTo(chatterId, vessage: vsg,taskSteps:SendVessageTaskSteps.fileVessageSteps, uploadFileUrl: url)
            }else{
                self.playCrossMark("PROCESS_IMAGE_ERROR".localizedString())
            }
        }
    }
}
