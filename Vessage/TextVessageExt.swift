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
        self.textChatInputView.layoutIfNeeded()
        self.textChatInputView.frame.origin = CGPoint.zero
        
        
        let tapFaceText = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.onClickFaceTextButton(_:)))
        self.sendFaceTextButton.addGestureRecognizer(tapFaceText)
        let tap = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.onTapInputView(_:)))
        self.messageList.addGestureRecognizer(tap)
        
        self.textChatInputView.delegate = self
        textChatInputResponderTextFiled = UITextField(frame: CGRect(x: -10,y: -10,width: 10,height: 10))
        textChatInputView.inputTextField.returnKeyType = .send
        self.view.addSubview(textChatInputResponderTextFiled)
        self.textChatInputResponderTextFiled.inputAccessoryView = textChatInputView
    }
    
    func onTapInputView(_ ges:UITapGestureRecognizer) {
        self.hideKeyBoard()
    }
    
    //MARK: TextChatInputViewDelegate
    func textChatInputViewDidBeginEditing(_ textField: UITextView) {
        textChatInputViewChanged(textField)
    }
    
    func textChatInputViewChanged(_ textField: UITextView) {

    }
    
    func textChatInputViewDidEndEditing(_ textField: UITextView) {
        textChatInputResponderTextFiled.resignFirstResponder()
    }
    
    func textChatInputViewDidClickSend(_ sender: AnyObject?, textField: UITextView) {
        sendImageChatVessage()
    }
    
    func textChatInputViewDidClickChatImage(_ sender: AnyObject?) {
        //self.showChatImagesMrgController(1)
    }
    
    //MARK: actions
    
    func onClickFaceTextButton(_ sender: UITapGestureRecognizer) {
        self.sendFaceTextButton.animationMaxToMin(0.1, maxScale: 1.2) {
            if self.outChatGroup{
                self.flashTips("NOT_IN_CHAT_GROUP".localizedString())
            }else{
                self.tryShowTextChatInputView()
            }
        }
    }
    
    @discardableResult
    func tryShowTextChatInputView() -> Bool{
        self.textChatInputResponderTextFiled.becomeFirstResponder()
        self.textChatInputView.inputTextField.becomeFirstResponder()
        return true
    }
    
    /*
    func showNoChatImagesAlert(){
        let ok = UIAlertAction(title: "OK".localizedString(), style: .Default) { (ac) in
            self.showChatImagesMrgController(1)
        }
        self.showAlert("NO_CHAT_IMAGES".localizedString(), msg: "U_MUST_SET_CHAT_IMAGES".localizedString(), actions: [ok])
    }
 */
    
    fileprivate func sendImageChatVessage() {
        self.setProgressSending()
        let textMessage = self.textChatInputView.inputTextField.text
        self.textChatInputView.inputTextField.text = nil
        self.textChatInputView.refreshSendButtonColor()
        let vsg = Vessage()
        let isGroup = self.conversation.isGroupChat
        vsg.typeId = Vessage.typeFaceText
        vsg.body = getSendVessageBodyString(["textMessage":textMessage])
        VessageQueue.sharedInstance.pushNewVessageTo(self.conversation.chatterId,isGroup: isGroup, vessage: vsg,taskSteps: SendVessageTaskSteps.normalVessageSteps)
    }
}
