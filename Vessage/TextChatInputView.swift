//
//  TextChatInputView.swift
//  Vessage
//
//  Created by AlexChow on 16/7/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

@objc protocol TextChatInputViewDelegate {
    @objc optional func textChatInputViewDidClickSend(_ sender:AnyObject?,textField:UITextView)
    @objc optional func textChatInputViewDidClickChatImage(_ sender:AnyObject?)
    @objc optional func textChatInputViewDidEndEditing(_ textField: UITextView)
    @objc optional func textChatInputViewChanged(_ textField: UITextView)
    @objc optional func textChatInputViewDidBeginEditing(_ textField: UITextView)
    @objc optional func textChatInputViewDidPasteboardImageChanged(_ newImage:UIImage)
}

class TextChatInputView: UIView,UITextViewDelegate {
    @IBOutlet weak var inputTextField: BahamutTextView!{
        didSet{
            inputTextField.delegate = self
            inputTextField.placeHolder = "TEXT_MESSAGE_HOLDER".localizedString()
        }
    }
    fileprivate var defaultSendButtonColor:UIColor = UIColor(hexString: "#00BFFF")
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate:TextChatInputViewDelegate?
    
    fileprivate var pasteboardImageDesc:String?
    
    @IBAction func onClickSendButton(_ sender: AnyObject) {
        if let handler = delegate?.textChatInputViewDidClickSend{
            DispatchQueue.main.async(execute: {
                handler(sender,self.inputTextField)
                self.refreshSendButtonColor()
            })
        }
    }
    
    @IBAction func onClickChatImageButton(_ sender: AnyObject) {
        self.delegate?.textChatInputViewDidClickChatImage?(sender)
    }
    
    //MARK:UITextFieldDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        refreshSendButtonColor()
        delegate?.textChatInputViewDidBeginEditing?(textView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.textChatInputViewChanged?(textView)
        refreshSendButtonColor()
    }
    
    func refreshSendButtonColor(){
        let enable = !String.isNullOrEmpty(inputTextField.text)
        sendButton.isEnabled = enable
        sendButton.backgroundColor = enable ? defaultSendButtonColor : UIColor.lightGray
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textChatInputViewDidEndEditing?(textView)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let handler = delegate?.textChatInputViewDidClickSend{
                handler(textView,textView)
                self.refreshSendButtonColor()
            }
            return false
        }
        return true
    }

    static func instanceFromXib() -> TextChatInputView{
        let view = Bundle.main.loadNibNamed("TextChatInputView", owner: nil, options: nil)![0] as! TextChatInputView
        view.backgroundColor = UIColor.clear
        return view
    }
}
