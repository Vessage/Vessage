//
//  SignUpViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MAKR: Sign Up Notification
let RegistAccountCompleted = "RegistAccountCompleted"
let RegistAccountIDValue = "RegistAccountIDValue"
let RegistAccountPasswordValue = "RegistAccountPasswordValue"

//MARK: SignUpViewController
class SignUpViewController: UIViewController {

    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var refreshingIndicator: UIActivityIndicatorView!{
        didSet{
            refreshingIndicator.hidesWhenStopped = true
            refreshingIndicator.stopAnimating()
        }
    }
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    fileprivate func showIndicator(){
        self.refreshingIndicator.startAnimating()
        self.refreshingIndicator.isHidden = false
        self.signupButton.isHidden = true
        self.view.isUserInteractionEnabled =  false
    }
    
    fileprivate func hideIndicator(){
        self.refreshingIndicator.stopAnimating()
        self.signupButton.isHidden = false
        self.view.isUserInteractionEnabled = true
    }

    //MARK: actions
    @IBAction func whatsVG(_ sender: AnyObject) {
        SimpleBrowser.openUrl(self, url: "http://bahamut.cn/whatsvg.html", title: "WHATS_VG".localizedString())
    }
    
    @IBAction func signUp(_ sender: AnyObject) {
        self.hideKeyBoard()
        if checkRegistValid()
        {
            self.showIndicator()
            BahamutRFKit.sharedInstance.registBahamutAccount(VessageSetting.registAccountApi, username: userNameTextField.text!, passwordOrigin: passwordTextField.text!, phone_number: nil, email: nil) { (isSuc, errorMsg, registResult) -> Void in
                if isSuc
                {
                    MobClick.event("Vege_RegistedNewUser")
                    self.dismiss(animated: false, completion: { () -> Void in
                        let userInfo = [RegistAccountIDValue:registResult!.accountId,RegistAccountPasswordValue:self.passwordTextField.text!]
                        NotificationCenter.default.post(name: Notification.Name(rawValue: RegistAccountCompleted), object: self, userInfo: userInfo)
                    })
                }else{
                    self.hideIndicator()
                    if let msg = errorMsg?.localizedString(){
                        self.playToast(msg)
                    }
                }
            }
        }
    }
    
    fileprivate func checkRegistValid() -> Bool{
        if let username = userNameTextField.text,username.isUsername(){
            if let psw = passwordTextField.text,psw.isPassword(){
                return true
            }else{
                passwordTextField.shakeAnimationForView()
                self.playToast("PASSWORD_TIPS".localizedString())
            }
        }else{
            userNameTextField.shakeAnimationForView()
            self.playToast("USER_NAME_TIPS".localizedString())
        }
        SystemSoundHelper.vibrate()
        return false
    }
    
    @IBAction func showSignIn(_ sender: AnyObject) {
        self.dismiss(animated: false) { () -> Void in
            
        }
    }
    
    static func showSignUpViewController(_ vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "SignUpViewController") as! SignUpViewController
        vc.present(controller, animated: false) { () -> Void in
            
        }
    }
}
