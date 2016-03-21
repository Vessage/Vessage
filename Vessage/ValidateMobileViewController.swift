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
        SMSSDKUI.showVerificationCodeViewWithMetohd(SMSGetCodeMethodSMS) { (responseState, phoneNo, zone,code, error) -> Void in
            if responseState == SMSUIResponseStateSelfVerify{
                let hud = self.showActivityHud()
                ServiceContainer.getService(UserService).validateMobile(phoneNo, zone: zone, code: code, callback: { (suc) -> Void in
                    hud.hideAsync(false)
                    if suc{
                        SetupChatBcgImageController.showSetupViewController(self)
                        MobClick.event("FinishValidateMobile")
                    }
                })
            }
        }
    }
    
    static func showValidateMobileViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("UserGuide", identifier: "ValidateMobileViewController") as! ValidateMobileViewController
        vc.presentViewController(controller, animated: false) { () -> Void in
            controller.validateMobile(vc)
        }
    }
}
