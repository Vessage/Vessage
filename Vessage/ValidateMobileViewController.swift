//
//  ValidateMobileViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: ValidateMobileViewController
class ValidateMobileViewController: UIViewController {
    
    @IBAction func validateMobile(sender: AnyObject) {
        #if RELEASE
            SMSSDKUI.showVerificationCodeViewWithMetohd(SMSGetCodeMethodSMS) { (responseState, phoneNo, zone,code, error) -> Void in
                if responseState == SMSUIResponseStateSelfVerify{
                    self.validateMobile(phoneNo, zone: zone, code: code)
                }
            }
        #else
            let title = "输入手机号"
            let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
            alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
                textfield.placeholder = "手机号"
                textfield.borderStyle = .None
            })
            
            let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
                let phoneNo = alertController.textFields?[0].text ?? ""
                if String.isNullOrEmpty(phoneNo)
                {
                    self.playToast("手机号不能为空")
                }else{
                    self.validateMobile(phoneNo, zone: "86", code: "1234")
                }
            })
            let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
            alertController.addAction(no)
            alertController.addAction(yes)
            self.showAlert(alertController)
        #endif
    }
    
    private func validateMobile(phoneNo:String,zone:String,code:String){
        let hud = self.showActivityHud()
        ServiceContainer.getUserService().validateMobile(VessageConfig.bahamutConfig.smsSDKAppkey,mobile: phoneNo, zone: zone, code: code, callback: { (suc,newUserId) -> Void in
            hud.hideAsync(false)
            if let newId = newUserId{
                ServiceContainer.getAccountService().reBindUserId(newId)
                EntryNavigationController.start()
            }else if suc{
                SetupChatBcgImageController.showSetupViewController(self)
                MobClick.event("Vege_FinishValidateMobile")
            }
        })
    }
    
    @IBAction func logout(sender: AnyObject) {
        ServiceContainer.instance.userLogout()
        EntryNavigationController.start()
    }
    
    static func showValidateMobileViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("UserGuide", identifier: "ValidateMobileViewController") as! ValidateMobileViewController
        vc.presentViewController(controller, animated: false) { () -> Void in
            controller.validateMobile(vc)
        }
    }
}
