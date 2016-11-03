
//
//  SNSCommentInputView.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

@objc protocol SNSCommentInputViewDelegate {
    optional func commentInputViewDidClickSend(sender:SNSCommentInputView,textField:UITextField)
    optional func commentInputViewDidEndEditing(sender:SNSCommentInputView,textField:UITextField)
}

class SNSCommentInputView: UIView,UITextFieldDelegate {
    var atUserNick:String!{
        didSet{
            if let at = atUserNick {
                inputTextField.placeholder = "@\(at)"
            }else{
                inputTextField.placeholder = "SNS_POST_COMMENT_NAME".SNSString
            }
            if oldValue != nil && atUserNick != nil && oldValue != atUserNick {
                inputTextField.text = nil
            }
        }
    }
    
    var model:AnyObject?
    
    private var responseView:UIView?
    
    
    func showInputView(responseView:UIView?,model:AnyObject?,atUserNick:String?) {
        self.model = model
        self.atUserNick = atUserNick
        self.responseView = responseView
        responseView?.becomeFirstResponder()
        inputTextField.becomeFirstResponder()
    }
    
    func hideInputView() {
        inputTextField.resignFirstResponder()
        responseView?.resignFirstResponder()
    }
    
    @IBOutlet weak var inputTextField: UITextField!{
        didSet{
            inputTextField.delegate = self
        }
    }
    
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate:SNSCommentInputViewDelegate?
    
    @IBAction func onClickSend(sender: AnyObject) {
        if let handler = delegate?.commentInputViewDidClickSend{
            dispatch_async(dispatch_get_main_queue(), {
                handler(self,textField: self.inputTextField)
            })
        }
    }
    
    //MARK:UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            onClickSend(sendButton)
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        delegate?.commentInputViewDidEndEditing?(self, textField: textField)
    }
    
    static func instanceFromXib() -> SNSCommentInputView{
        let view = NSBundle.mainBundle().loadNibNamed("SNSCommentInputView", owner: nil, options: nil)![0] as! SNSCommentInputView
        view.backgroundColor = UIColor.clearColor()
        return view
    }
}
