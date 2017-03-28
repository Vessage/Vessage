
//
//  SNSCommentInputView.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

@objc protocol SNSCommentInputViewDelegate {
    @objc optional func commentInputViewDidClickSend(_ sender:SNSCommentInputView,textField:UITextField)
    @objc optional func commentInputViewDidEndEditing(_ sender:SNSCommentInputView,textField:UITextField)
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
    
    fileprivate var responseView:UIView?
    
    
    func showInputView(_ responseView:UIView?,model:AnyObject?,atUserNick:String?) {
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
    
    @IBAction func onClickSend(_ sender: AnyObject) {
        if let handler = delegate?.commentInputViewDidClickSend{
            DispatchQueue.main.async(execute: {
                handler(self,self.inputTextField)
            })
        }
    }
    
    //MARK:UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            onClickSend(sendButton)
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.commentInputViewDidEndEditing?(self, textField: textField)
    }
    
    static func instanceFromXib() -> SNSCommentInputView{
        let view = Bundle.main.loadNibNamed("SNSCommentInputView", owner: nil, options: nil)![0] as! SNSCommentInputView
        view.backgroundColor = UIColor.white
        return view
    }
}
