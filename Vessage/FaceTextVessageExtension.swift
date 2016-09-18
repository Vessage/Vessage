//
//  FaceTextVessageExtension.swift
//  Vessage
//
//  Created by AlexChow on 16/7/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: Face Text Vessage
extension ConversationViewController:ImageChatInputViewDelegate,UIPopoverPresentationControllerDelegate,ChatImageBoardControllerDelegate{
    func initChatImageButton() {
        self.imageChatInputView = ImageChatInputView.instanceFromXib()
        self.imageChatInputView.frame = CGRectMake(0, 0, self.view.frame.width, 42)
        self.imageChatInputView.delegate = self
        imageChatInputResponderTextFiled = UITextField(frame: CGRectMake(-10,-10,10,10))
        imageChatInputView.inputTextField.returnKeyType = .Send
        self.view.addSubview(imageChatInputResponderTextFiled)
        self.imageChatInputResponderTextFiled.inputAccessoryView = imageChatInputView
    }
    
    func onKeyBoardShown(a:NSNotification) {
        
    }
    
    func onKeyboardHidden(a:NSNotification) {
        chatImageBoardShown = false
        chatImageBoardSourceView?.removeFromSuperview()
        chatImageBoardController?.dismissViewControllerAnimated(true, completion: nil)
        self.hideKeyBoard()
    }
    
    //MARK: ImageChatInputViewDelegate
    
    func imageChatInputViewChanged(textField: UITextView) {
        if String.isNullOrEmpty(textField.text) {
            chatImageBoardController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func imageChatInputViewDidEndEditing(textField: UITextView) {
        imageChatInputResponderTextFiled.resignFirstResponder()
    }
    
    func imageChatInputViewDidClickSend(sender: AnyObject?, textField: UITextView) {
        if chatImageBoardShown {
            chatImageBoardShown = false
            sendImageChatVessage()
        }else{
            showChatImageBoard()
        }
    }
    
    func imageChatInputViewDidClickChatImage(sender: AnyObject?) {
        if chatImageBoardShown {
            chatImageBoardController?.dismissViewControllerAnimated(true, completion: {
                self.showChatImagesMrgController(1)
            })
        }else{
            self.showChatImagesMrgController(1)
        }
    }
    
    //MARK: UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    //MARK: ChatImageBoardController Delegate
    
    func chatImageBoardController(appearController sender: ChatImageBoardController) {
        self.chatImageBoardShown = true
    }
    
    func chatImageBoardController(dissmissController sender: ChatImageBoardController) {
        self.chatImageBoardShown = false
    }
    
    func chatImageBoardController(sender: ChatImageBoardController, selectedIndexPath: NSIndexPath, selectedItem: ChatImage, deselectItem: ChatImage?) {
        if selectedItem.imageId == deselectItem?.imageId {
            sendImageChatVessage()
        }
    }
    
    //MARK: actions
    
    func tryShowImageChatInputView(){
        if userService.myChatImages.count > 0{
            self.imageChatInputResponderTextFiled.becomeFirstResponder()
            self.imageChatInputView.inputTextField.becomeFirstResponder()
        }else{
            showNoChatImagesAlert()
        }
    }
    
    private func showChatImageBoard() {
        self.initChatImageBoard()
        self.presentChatImageBoard()
    }
    
    private func presentChatImageBoard(){
        let rect = self.view.convertRect(self.imageChatInputView.sendButton.frame, fromView: self.imageChatInputView)
        self.chatImageBoardSourceView.frame = CGRectMake(rect.origin.x + rect.width / 2, rect.origin.y, 0, 0)
        self.view.addSubview(self.chatImageBoardSourceView)
        
        if let ppvc = self.chatImageBoardController.popoverPresentationController{
            if userService.myChatImages.count > 0{
                let lineCount = CGFloat(userService.myChatImages.count > 4 ? 4 : userService.myChatImages.count)
                self.chatImageBoardController.preferredContentSize = CGSizeMake(lineCount * (72) + (lineCount - 1) * 3 + 12, 112)
                ppvc.sourceView = self.chatImageBoardSourceView
                ppvc.sourceRect = self.chatImageBoardSourceView.bounds
                ppvc.permittedArrowDirections = .Any
                ppvc.delegate = self
                self.presentViewController(self.chatImageBoardController, animated: true, completion: nil)
            }else{
                self.playToast("U_MUST_SET_CHAT_IMAGES".localizedString())
            }
        }
    }
    
    private func showNoChatImagesAlert(){
        let ok = UIAlertAction(title: "OK".localizedString(), style: .Default) { (ac) in
            self.showChatImagesMrgController(1)
        }
        self.showAlert("NO_CHAT_IMAGES".localizedString(), msg: "U_MUST_SET_CHAT_IMAGES".localizedString(), actions: [ok])
    }
    
    private func initChatImageBoard(){
        if self.chatImageBoardSourceView == nil{
            chatImageBoardSourceView = UIView()
        }
        
        if self.chatImageBoardController == nil {
            self.chatImageBoardController = ChatImageBoardController.instanceFromStoryBoard()
            self.chatImageBoardController.modalPresentationStyle = .Popover
            self.chatImageBoardController.delegate = self
        }
    }
    
    private func sendImageChatVessage() {
        if let chatImage = self.chatImageBoardController.selectedChatImage{
            let textMessage = self.imageChatInputView.inputTextField.text
            
            self.imageChatInputView.inputTextField.text = nil
            self.chatImageBoardSourceView?.removeFromSuperview()
            self.chatImageBoardController?.dismissViewControllerAnimated(true){
                #if DEBUG
                    print("大头贴:\(chatImage.imageType)")
                #endif
            }
            self.imageChatInputView.refreshSendButtonColor()
            let vsg = Vessage()
            vsg.isGroup = self.conversation.isGroup
            vsg.typeId = Vessage.typeFaceText
            let json = try! NSJSONSerialization.dataWithJSONObject(["textMessage":textMessage], options: NSJSONWritingOptions(rawValue: 0))
            vsg.body = String(data: json, encoding: NSUTF8StringEncoding)
            vsg.fileId = chatImage.imageId
            VessageQueue.sharedInstance.pushNewVessageTo(self.conversation.chatterId,vessage: vsg,taskSteps: SendVessageTaskSteps.normalVessageSteps)
            self.playVessageManager.sendingVessage = vsg
        }else{
            self.playToast("No Chat Image Selected")
        }
        
    }
}