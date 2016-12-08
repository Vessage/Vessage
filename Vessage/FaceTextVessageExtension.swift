//
//  FaceTextVessageExtension.swift
//  Vessage
//
//  Created by AlexChow on 16/7/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: Face Text Vessage
extension ConversationViewController:TextChatInputViewDelegate,UIPopoverPresentationControllerDelegate {
    func initChatImageButton() {
        self.textChatInputView = TextChatInputView.instanceFromXib()
        self.textChatInputView.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipeInputView(_:)))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipeInputView(_:)))
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipeInputView(_:)))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ConversationViewController.onSwipeInputView(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.onTapInputView(_:)))
        swipeLeft.direction = .Left
        swipeRight.direction = .Right
        swipeUp.direction = .Up
        swipeDown.direction = .Down
        
        self.textChatInputView.addGestureRecognizer(swipeRight)
        self.textChatInputView.addGestureRecognizer(swipeLeft)
        self.textChatInputView.addGestureRecognizer(swipeUp)
        self.textChatInputView.addGestureRecognizer(swipeDown)
 
        self.textChatInputView.addGestureRecognizer(tap)
        self.textChatInputView.delegate = self
        textChatInputResponderTextFiled = UITextField(frame: CGRectMake(-10,-10,10,10))
        textChatInputView.inputTextField.returnKeyType = .Send
        self.view.addSubview(textChatInputResponderTextFiled)
        self.textChatInputResponderTextFiled.inputAccessoryView = textChatInputView
    }
    
    func onTapInputView(ges:UITapGestureRecognizer) {
        self.hideKeyBoard()
    }
    
    func onSwipeInputView(ges:UISwipeGestureRecognizer) {
        switch ges.direction {
        case UISwipeGestureRecognizerDirection.Left,UISwipeGestureRecognizerDirection.Down:
            self.playVessageManager.showNextVessage()
        case UISwipeGestureRecognizerDirection.Right,UISwipeGestureRecognizerDirection.Up:
            self.playVessageManager.showPreviousVessage()
        default:
            break
        }
    }
    
    //MARK: TextChatInputViewDelegate
    func textChatInputViewDidBeginEditing(textField: UITextView) {
        textChatInputViewChanged(textField)
    }
    
    func textChatInputViewChanged(textField: UITextView) {

    }
    
    func textChatInputViewDidEndEditing(textField: UITextView) {
        textChatInputResponderTextFiled.resignFirstResponder()
    }
    
    func textChatInputViewDidClickSend(sender: AnyObject?, textField: UITextView) {
        sendImageChatVessage()
    }
    
    func textChatInputViewDidClickChatImage(sender: AnyObject?) {
        self.showChatImagesMrgController(1)
    }
    
    //MARK: actions
    func tryShowTextChatInputView() -> Bool{
        self.textChatInputResponderTextFiled.becomeFirstResponder()
        self.textChatInputView.inputTextField.becomeFirstResponder()
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
        let textMessage = self.textChatInputView.inputTextField.text
        self.textChatInputView.inputTextField.text = nil
        self.textChatInputView.refreshSendButtonColor()
        let vsg = Vessage()
        let isGroup = self.conversation.isGroupChat
        vsg.typeId = Vessage.typeFaceText        
        vsg.body = getSendVessageBodyString(["textMessage":textMessage])
        vsg.fileId = chatImage
        VessageQueue.sharedInstance.pushNewVessageTo(self.conversation.chatterId,isGroup: isGroup, vessage: vsg,taskSteps: SendVessageTaskSteps.normalVessageSteps)
    }
}
