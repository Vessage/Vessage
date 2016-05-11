//
//  ChangePasswordViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/27.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
class ChangePasswordViewController: UIViewController,UITextFieldDelegate
{
    
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBAction func changePassword(sender: AnyObject) {
        let newPsw = newPasswordTextField.text ?? ""
        let oldPsw = oldPasswordTextField.text ?? ""
        if String.isNullOrWhiteSpace(oldPsw)
        {
            self.showAlert("OLD_PSW_NULL".localizedString(), msg: nil)
            return
        }else if oldPsw == newPsw
        {
            showAlert("OLD_NEW_PSW_SAME".localizedString(), msg: nil, actions: [ALERT_ACTION_I_SEE])
        }
        else if newPsw =~ "^[A-Za-z0-9_\\@\\!\\#\\$\\%\\^\\&\\*\\.\\~]{6,23}$"
        {
            showAlert("CONFIRM_PSW".localizedString(), msg: newPsw, actions: [
                UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (action) -> Void in
                    let hud = self.showActivityHud()
                    ServiceContainer.getAccountService().changePassword(oldPsw, newPsw: newPsw) { (isSuc,msg) -> Void in
                        hud.hideAsync(true)
                        if isSuc
                        {
                            self.showAlert(msg?.localizedString() ?? "CHANGE_PASSWORD_SUCCESS".localizedString(), msg: nil)
                            self.navigationController?.popViewControllerAnimated(true)
                        }else
                        {
                            self.showAlert(msg?.localizedString() ?? "CHANGE_PASSWORD_ERROR".localizedString(), msg: nil)
                        }
                    }
                }),
                UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: nil)
                ])
            
        }else
        {
            self.showAlert("WRONG_PSW_FORMAT".localizedString(), msg: "PSW_FORMAT".localizedString())
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    static func instanceFromStoryBoard()->ChangePasswordViewController{
        return instanceFromStoryBoard("User", identifier: "ChangePasswordViewController") as! ChangePasswordViewController
    }

}