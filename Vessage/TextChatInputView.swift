//
//  TextChatInputView.swift
//  Vessage
//
//  Created by AlexChow on 16/7/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

@objc protocol TextChatInputViewDelegate {
    optional func textChatInputViewDidClickSend(sender:AnyObject?,textField:UITextView)
    optional func textChatInputViewDidClickChatImage(sender:AnyObject?)
    optional func textChatInputViewDidEndEditing(textField: UITextView)
    optional func textChatInputViewChanged(textField: UITextView)
    optional func textChatInputViewDidBeginEditing(textField: UITextView)
    optional func textChatInputViewDidPasteboardImageChanged(newImage:UIImage)
}

class TextChatInputView: UIView,UITextViewDelegate {
    @IBOutlet weak var inputTextField: BahamutTextView!{
        didSet{
            inputTextField.delegate = self
            inputTextField.placeHolder = "TEXT_MESSAGE_HOLDER".localizedString()
        }
    }
    private var defaultSendButtonColor:UIColor = UIColor(hexString: "#00BFFF")
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate:TextChatInputViewDelegate?
    
    private var pasteboardImageDesc:String?
    
    @IBAction func onClickSendButton(sender: AnyObject) {
        if let handler = delegate?.textChatInputViewDidClickSend{
            dispatch_async(dispatch_get_main_queue(), {
                handler(sender,textField: self.inputTextField)
                self.refreshSendButtonColor()
            })
        }
    }
    
    @IBAction func onClickChatImageButton(sender: AnyObject) {
        self.delegate?.textChatInputViewDidClickChatImage?(sender)
    }
    
    //MARK:UITextFieldDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        refreshSendButtonColor()
        if let image = UIPasteboard.generalPasteboard().image{
            image.description
        }
        delegate?.textChatInputViewDidBeginEditing?(textView)
    }
    
    func textViewDidChange(textView: UITextView) {
        self.delegate?.textChatInputViewChanged?(textView)
        refreshSendButtonColor()
    }
    
    func refreshSendButtonColor(){
        let enable = !String.isNullOrEmpty(inputTextField.text)
        sendButton.enabled = enable
        sendButton.backgroundColor = enable ? defaultSendButtonColor : UIColor.lightGrayColor()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        delegate?.textChatInputViewDidEndEditing?(textView)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let handler = delegate?.textChatInputViewDidClickSend{
                handler(textView,textField: textView)
                self.refreshSendButtonColor()
            }
            return false
        }
        return true
    }

    static func instanceFromXib() -> TextChatInputView{
        let view = NSBundle.mainBundle().loadNibNamed("TextChatInputView", owner: nil, options: nil)![0] as! TextChatInputView
        view.backgroundColor = UIColor.clearColor()
        return view
    }
}
