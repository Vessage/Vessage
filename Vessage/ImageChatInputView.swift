//
//  ImageChatInputView.swift
//  Vessage
//
//  Created by AlexChow on 16/7/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

@objc protocol ImageChatInputViewDelegate {
    optional func imageChatInputViewDidClickSend(sender:AnyObject?,textField:UITextView);
    optional func imageChatInputViewDidClickChatImage(sender:AnyObject?);
    optional func imageChatInputViewDidEndEditing(textField: UITextView);
    optional func imageChatInputViewChanged(textField: UITextView);
    optional func imageChatInputViewDidBeginEditing(textField: UITextView);
}

class ImageChatInputView: UIView,UITextViewDelegate {
    @IBOutlet weak var inputTextField: UITextView!{
        didSet{
            inputTextField.delegate = self
        }
    }
    private var defaultSendButtonColor:UIColor = UIColor(hexString: "#00BFFF")
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate:ImageChatInputViewDelegate?
    
    @IBAction func onClickSendButton(sender: AnyObject) {
        if let handler = delegate?.imageChatInputViewDidClickSend{
            dispatch_async(dispatch_get_main_queue(), {
                handler(sender,textField: self.inputTextField)
                self.refreshSendButtonColor()
            })
        }
    }
    
    @IBAction func onClickChatImageButton(sender: AnyObject) {
        self.delegate?.imageChatInputViewDidClickChatImage?(sender)
    }
    
    //MARK:UITextFieldDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        refreshSendButtonColor()
        delegate?.imageChatInputViewDidBeginEditing?(textView)
    }
    
    func textViewDidChange(textView: UITextView) {
        self.delegate?.imageChatInputViewChanged?(textView)
        refreshSendButtonColor()
    }
    
    func refreshSendButtonColor(){
        let enable = !String.isNullOrEmpty(inputTextField.text)
        sendButton.enabled = enable
        sendButton.backgroundColor = enable ? defaultSendButtonColor : UIColor.lightGrayColor()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        delegate?.imageChatInputViewDidEndEditing?(textView)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let handler = delegate?.imageChatInputViewDidClickSend{
                handler(textView,textField: textView)
                self.refreshSendButtonColor()
            }
            return false
        }
        return true
    }

    static func instanceFromXib() -> ImageChatInputView{
        let view = NSBundle.mainBundle().loadNibNamed("ImageChatInputView", owner: nil, options: nil)![0] as! ImageChatInputView
        view.backgroundColor = UIColor.clearColor()
        return view
    }
}
