//
//  ValidateMobileViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ValidateMobileViewController: UIViewController {
    
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var smsTextField: UITextField!
    @IBOutlet weak var sendSMSButton: UIButton!
    
    @IBAction func sendSMS(sender: AnyObject) {
        ServiceContainer.getService(UserService).sendValidateMobilSMS { (suc) -> Void in
            if suc{
                self.playToast("SEND_SMS_KEY_SUCCESS".localizedString())
            }else{
                self.playToast("SEND_SMS_KEY_FAILED".localizedString())
            }
        }
    }
    
    @IBAction func validateMobile(sender: AnyObject) {
        ServiceContainer.getService(UserService).validateMobile(mobileTextField.text!, smsKey: smsTextField.text!) { (suc) -> Void in
            if suc{
                EntryNavigationController.start()
            }else{
                self.playToast("SMS_KEY_NOT_CORRECT".localizedString())
            }
        }
    }
    
    static func showValidateMobileViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "ValidateMobileViewController")
        vc.presentViewController(controller, animated: true) { () -> Void in
            
        }
    }
}
