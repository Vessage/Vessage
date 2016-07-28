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
    optional func imageChatInputViewDidEndEditing(textField: UITextView);
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
    
    //MARK:UITextFieldDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        refreshSendButtonColor()
    }
    
    func textViewDidChange(textView: UITextView) {
        refreshSendButtonColor()
    }
    
    func refreshSendButtonColor(){
        let enable = !String.isNullOrEmpty(inputTextField.text)
        sendButton.enabled = enable
        sendButton.backgroundColor = enable ? defaultSendButtonColor : UIColor.lightGrayColor()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if let handler = delegate?.imageChatInputViewDidEndEditing {
            handler(textView)
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let handler = delegate?.imageChatInputViewDidClickSend{
                dispatch_async(dispatch_get_main_queue(), {
                    handler(textView,textField: textView)
                    self.refreshSendButtonColor()
                })
            }
            return false
        }
        return true
    }

    static func instanceFromXib() -> ImageChatInputView{
        let view = NSBundle.mainBundle().loadNibNamed("ImageChatInputView", owner: nil, options: nil)[0] as! ImageChatInputView
        view.backgroundColor = UIColor.clearColor()
        return view
    }
}