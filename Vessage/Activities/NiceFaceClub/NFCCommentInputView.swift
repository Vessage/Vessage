
//
//  NFCCommentInputView.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

@objc protocol NFCCommentInputViewDelegate {
    optional func commentInputViewDidClickSend(sender:NFCCommentInputView,textField:UITextField)
}

class NFCCommentInputView: UIView,UITextFieldDelegate {
    @IBOutlet weak var inputTextField: UITextField!{
        didSet{
            inputTextField.delegate = self
        }
    }
    
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate:NFCCommentInputViewDelegate?
    
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
    
    static func instanceFromXib() -> NFCCommentInputView{
        let view = NSBundle.mainBundle().loadNibNamed("NFCCommentInputView", owner: nil, options: nil)![0] as! NFCCommentInputView
        view.backgroundColor = UIColor.clearColor()
        return view
    }
}
