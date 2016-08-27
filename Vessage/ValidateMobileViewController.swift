//
//  ValidateMobileViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

@objc
protocol ValidateMobileViewControllerDelegate {
    optional func validateMobile(sender:ValidateMobileViewController,suc:Bool)
    optional func validateMobile(sender:ValidateMobileViewController,rebindedNewUserId:String)
    optional func validateMobileCancel(sender:ValidateMobileViewController)
}

//MARK: ValidateMobileViewController
class ValidateMobileViewController: UIViewController {
    private var smsCodeSended = false
    weak var delegate:ValidateMobileViewControllerDelegate?
    private var exitButtonHandler:(()->Void)?
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var smsCodeTextFiled: UITextField!
    @IBOutlet weak var mobileTextField: UITextField!
    
    @IBAction func validateMobile(sender: AnyObject) {
        let mobile = self.mobileTextField?.text ?? ""
        let code = self.smsCodeTextFiled?.text ?? ""
        
        if mobile.isMobileNumber() && !String.isNullOrWhiteSpace(code) {
            validateMobile(self.mobileTextField.text!, zone: "86", code: smsCodeTextFiled.text!)
        }else if mobile.isMobileNumber(){
            sendSMS()
        }
    }
    
    @IBAction func mobileValueChanged(sender: AnyObject) {
        updateButton()
    }
    
    @IBAction func codeValueChanged(sender: AnyObject) {
        updateButton()
    }
    
    
    
    private func updateButton(){
        let mobile = self.mobileTextField?.text ?? ""
        let code = self.smsCodeTextFiled?.text ?? ""
        validateButton.enabled = true
        if mobile.isMobileNumber() && !String.isNullOrWhiteSpace(code) {
            validateButton.setImage(UIImage(named: "check")!, forState: .Normal)
        }else if mobile.isMobileNumber(){
            validateButton.setImage(UIImage(named: "nextRound")!, forState: .Normal)
        }else{
            validateButton.setImage(UIImage(named: "nextRound")!, forState: .Normal)
            validateButton.enabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validateButton.setImage(UIImage(named: "nextRound")!, forState: .Normal)
        validateButton.enabled = false
    }
    
    private func sendSMS(){
        #if DEBUG
            self.smsCodeSended = true
            self.smsCodeTextFiled.becomeFirstResponder()
        #else
            let hud = self.showAnimationHud()
            SMSSDK.getVerificationCodeByMethod(SMSGetCodeMethodSMS, phoneNumber: mobileTextField.text!, zone: "86", customIdentifier: nil) { (error) in
                hud.hide(true)
                if error == nil{
                    self.smsCodeSended = true
                    self.smsCodeTextFiled.becomeFirstResponder()
                }else{
                    self.playCrossMark("GET_SMS_CODE_ERROR".localizedString())
                }
            }
        #endif
    }
    
    private func validateMobile(phoneNo:String,zone:String,code:String){
        let hud = self.showAnimationHud()
        ServiceContainer.getUserService().validateMobile(VessageConfig.bahamutConfig.smsSDKAppkey,mobile: phoneNo, zone: zone, code: code, callback: { (suc,newUserId) -> Void in
            hud.hideAsync(false)
            if let newId = newUserId{
                self.dismissViewControllerAnimated(true){
                    self.delegate?.validateMobile?(self, rebindedNewUserId: newId)
                }
                MobClick.event("Vege_FinishValidateMobile")
            }else if suc{
                self.dismissViewControllerAnimated(true){
                    self.delegate?.validateMobile?(self, suc: true)
                }
                MobClick.event("Vege_FinishValidateMobile")
            }else{
                self.playToast("VALIDATE_MOBILE_CODE_ERROR".localizedString())
            }
        })
    }
    
    @IBAction func logout(sender: AnyObject) {
        self.dismissViewControllerAnimated(true){
        }
        self.delegate?.validateMobileCancel?(self)
    }
    
    static func showValidateMobileViewController(vc:UIViewController,delegate:ValidateMobileViewControllerDelegate?)
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "ValidateMobileViewController") as! ValidateMobileViewController
        controller.delegate = delegate
        vc.presentViewController(controller, animated: true) { () -> Void in
            
        }
    }
}
