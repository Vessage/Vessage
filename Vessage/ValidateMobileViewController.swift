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
    optional func validateMobileIsTryBindExistsUser(sender:ValidateMobileViewController) -> Bool
}

//MARK: ValidateMobileViewController
class ValidateMobileViewController: UIViewController,UITextFieldDelegate {
    private var smsCodeSended = false{
        didSet{
            self.smsCodeTextFiled?.enabled = smsCodeSended
        }
    }
    private var smsCodeSendedDate:NSDate!
    weak var delegate:ValidateMobileViewControllerDelegate?
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var smsCodeTextFiled: UITextField!{
        didSet{
            smsCodeTextFiled.enabled = false
        }
    }
    @IBOutlet weak var mobileTextField: UITextField!
    
    @IBAction func validateMobile(sender: AnyObject) {
        let mobile = self.mobileTextField?.text ?? ""
        let code = self.smsCodeTextFiled?.text ?? ""
        
        if self.mobileTextField.isFirstResponder(){
            sendSMS()
        }else if self.smsCodeTextFiled.isFirstResponder(){
            if !mobile.isMobileNumber(){
                self.playCrossMark("NOT_MOBILE_NO".localizedString())
            }else if String.isNullOrWhiteSpace(code){
                self.playCrossMark("NOT_SMS_CODE".localizedString())
            }else{
                validateMobile(mobile, zone: "86", code: code)
            }
        }else{
            if mobile.isMobileNumber() && !String.isNullOrWhiteSpace(code) {
                validateMobile(mobile, zone: "86", code: code)
            }else if mobile.isMobileNumber(){
                sendSMS()
            }else{
                self.mobileTextField.becomeFirstResponder()
            }
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        updateButton()
    }
    
    @IBAction func mobileValueChanged(sender: AnyObject) {
        updateButton()
    }
    
    @IBAction func codeValueChanged(sender: AnyObject) {
        updateButton()
    }
    
    @IBAction func onMobileTipsClick(sender: AnyObject) {
        self.showAlert("手机不可逆加密匹配", msg: "用户A手机M加密成不可逆密文P保存\n\n用户B查找手机M，M加密成P，匹配出A");
    }
    
    private func updateButton(){
        let mobile = self.mobileTextField?.text ?? ""
        let code = self.smsCodeTextFiled?.text ?? ""
        
        if self.mobileTextField.isFirstResponder() {
            validateButton.setImage(UIImage(named: "nextRound")!, forState: .Normal)
            validateButton.enabled = mobile.isMobileNumber()
        }else if self.smsCodeTextFiled.isFirstResponder(){
            validateButton.setImage(UIImage(named: "check")!, forState: .Normal)
            validateButton.enabled = mobile.isMobileNumber() && !String.isNullOrWhiteSpace(code)
        }else{
            if mobile.isMobileNumber() && !String.isNullOrWhiteSpace(code) {
                validateButton.setImage(UIImage(named: "check")!, forState: .Normal)
            }else if mobile.isMobileNumber(){
                validateButton.setImage(UIImage(named: "nextRound")!, forState: .Normal)
            }else{
                validateButton.setImage(UIImage(named: "nextRound")!, forState: .Normal)
                validateButton.enabled = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mobileTextField.delegate = self
        smsCodeTextFiled.delegate = self
        validateButton.setImage(UIImage(named: "nextRound")!, forState: .Normal)
        validateButton.enabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.mobileTextField.becomeFirstResponder()
    }
    
    private func sendSMS(){
        if self.smsCodeSended && abs(self.smsCodeSendedDate.totalSecondsSinceNow.integerValue) < 30 {
            self.playToast(String(format: "X_SEC_RESEND_SMS_CODE".localizedString(), 30 - abs(self.smsCodeSendedDate.totalSecondsSinceNow.integerValue)))
            return
        }
        #if DEBUG
            self.smsCodeSended = true
            self.smsCodeSendedDate = NSDate()
            self.smsCodeTextFiled.becomeFirstResponder()
            self.showAlert("SMS_CODE_SENDED_TITLE".localizedString(), msg: "SMS_CODE_SENDED_MSG".localizedString())
        #else
            let hud = self.showAnimationHud()
            SMSSDK.getVerificationCodeByMethod(SMSGetCodeMethodSMS, phoneNumber: mobileTextField.text!, zone: "86", customIdentifier: nil) { (error) in
                hud.hideAnimated(true)
                if error == nil{
                    self.smsCodeSended = true
                    self.smsCodeSendedDate = NSDate()
                    self.smsCodeTextFiled.becomeFirstResponder()
                    self.showAlert("SMS_CODE_SENDED_TITLE".localizedString(), msg: "SMS_CODE_SENDED_MSG".localizedString())
                }else{
                    self.playCrossMark("GET_SMS_CODE_ERROR".localizedString())
                }
            }
        #endif
    }
    
    private func validateMobile(phoneNo:String,zone:String,code:String){
        let hud = self.showAnimationHud()
        let tryBindExistsUser = delegate?.validateMobileIsTryBindExistsUser?(self) ?? false
        ServiceContainer.getUserService().validateMobile(VessageConfig.bahamutConfig.smsSDKAppkey,mobile: phoneNo, zone: zone, code: code,bindExistsAccount: tryBindExistsUser, callback: { (suc,newUserId) -> Void in
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
        self.delegate?.validateMobileCancel?(self)
    }
    
    static func showValidateMobileViewController(vc:UIViewController,delegate:ValidateMobileViewControllerDelegate?) -> ValidateMobileViewController
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "ValidateMobileViewController") as! ValidateMobileViewController
        controller.delegate = delegate
        vc.presentViewController(controller, animated: true) { () -> Void in
            
        }
        return controller
    }
}
