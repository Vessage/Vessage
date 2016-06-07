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
                    let hud = self.showActivityHud()
                    
                    ServiceContainer.getUserService().validateMobile(VessageConfig.bahamutConfig.smsSDKAppkey,mobile: phoneNo, zone: zone, code: code, callback: { (suc) -> Void in
                        hud.hideAsync(false)
                        if suc{
                            SetupChatBcgImageController.showSetupViewController(self)
                            MobClick.event("FinishValidateMobile")
                        }
                    })
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
                    let hud = self.showActivityHud()
                    ServiceContainer.getUserService().validateMobile(VessageConfig.bahamutConfig.smsSDKAppkey,mobile: phoneNo, zone: "86", code: "test", callback: { (suc) -> Void in
                        hud.hideAsync(false)
                        if suc{
                            SetupChatBcgImageController.showSetupViewController(self)
                        }
                    })
                }
            })
            let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
            alertController.addAction(no)
            alertController.addAction(yes)
            self.showAlert(alertController)
        #endif
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
