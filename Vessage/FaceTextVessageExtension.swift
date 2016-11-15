//
//  FaceTextVessageExtension.swift
//  Vessage
//
//  Created by AlexChow on 16/7/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: Face Text Vessage
extension ConversationViewController:ImageChatInputViewDelegate,UIPopoverPresentationControllerDelegate {
    func initChatImageButton() {
        self.imageChatInputView = ImageChatInputView.instanceFromXib()
        self.imageChatInputView.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipeInputView(_:)))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipeInputView(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.onTapInputView(_:)))
        swipeLeft.direction = .Left
        swipeRight.direction = .Right
        self.imageChatInputView.addGestureRecognizer(swipeRight)
        self.imageChatInputView.addGestureRecognizer(swipeLeft)
        self.imageChatInputView.addGestureRecognizer(tap)
        self.imageChatInputView.delegate = self
        imageChatInputResponderTextFiled = UITextField(frame: CGRectMake(-10,-10,10,10))
        imageChatInputView.inputTextField.returnKeyType = .Send
        self.view.addSubview(imageChatInputResponderTextFiled)
        self.imageChatInputResponderTextFiled.inputAccessoryView = imageChatInputView
    }
    
    func onTapInputView(ges:UITapGestureRecognizer) {
        self.hideKeyBoard()
    }
    
    func onSwipeInputView(ges:UISwipeGestureRecognizer) {
        if ges.direction == .Left {
            self.playVessageManager.showNextVessage()
        }else if ges.direction == .Right{
            self.playVessageManager.showPreviousVessage()
        }
    }
    
    //MARK: ImageChatInputViewDelegate
    func imageChatInputViewDidBeginEditing(textField: UITextView) {
        imageChatInputViewChanged(textField)
    }
    
    func imageChatInputViewChanged(textField: UITextView) {

    }
    
    func imageChatInputViewDidEndEditing(textField: UITextView) {
        imageChatInputResponderTextFiled.resignFirstResponder()
    }
    
    func imageChatInputViewDidClickSend(sender: AnyObject?, textField: UITextView) {
        sendImageChatVessage()
    }
    
    func imageChatInputViewDidClickChatImage(sender: AnyObject?) {
        self.showChatImagesMrgController(1)
    }
    
    //MARK: actions
    func tryShowImageChatInputView() -> Bool{
        self.imageChatInputResponderTextFiled.becomeFirstResponder()
        self.imageChatInputView.inputTextField.becomeFirstResponder()
        return true
    }
    
    func showNoChatImagesAlert(){
        let ok = UIAlertAction(title: "OK".localizedString(), style: .Default) { (ac) in
            self.showChatImagesMrgController(1)
        }
        self.showAlert("NO_CHAT_IMAGES".localizedString(), msg: "U_MUST_SET_CHAT_IMAGES".localizedString(), actions: [ok])
    }
    
    private func sendImageChatVessage() {
        let chatImage = self.playVessageManager.selectedImageId
        self.setProgressSending()
        let textMessage = self.imageChatInputView.inputTextField.text
        self.imageChatInputView.inputTextField.text = nil
        self.imageChatInputView.refreshSendButtonColor()
        let vsg = Vessage()
        vsg.isGroup = self.conversation.isGroup
        vsg.typeId = Vessage.typeFaceText        
        vsg.body = getSendVessageBodyString(["textMessage":textMessage])
        vsg.fileId = chatImage
        vsg.isReady = true
        VessageQueue.sharedInstance.pushNewVessageTo(self.conversation.chatterId,vessage: vsg,taskSteps: SendVessageTaskSteps.normalVessageSteps)
    }
}
