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

    @IBOutlet weak var signupButton: UIButton!{
        didSet{
            let img = UIImage(named: "nextRound")!.imageWithRenderingMode(.AlwaysTemplate)
            signupButton.setImage(img, forState: .Normal)
            signupButton.tintColor = UIColor.whiteColor()
        }
    }
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
    
    private func showIndicator(){
        self.refreshingIndicator.startAnimating()
        self.refreshingIndicator.hidden = false
        self.signupButton.hidden = true
        self.view.userInteractionEnabled =  false
    }
    
    private func hideIndicator(){
        self.refreshingIndicator.stopAnimating()
        self.signupButton.hidden = false
        self.view.userInteractionEnabled = true
    }

    //MARK: actions
    @IBAction func signUp(sender: AnyObject) {
        self.hideKeyBoard()
        if checkRegistValid()
        {
            self.showIndicator()
            BahamutRFKit.sharedInstance.registBahamutAccount(VessageSetting.registAccountApi, username: userNameTextField.text!, passwordOrigin: passwordTextField.text!, phone_number: nil, email: nil) { (isSuc, errorMsg, registResult) -> Void in
                if isSuc
                {
                    let action = UIAlertAction(title: "OK".localizedString(), style:.Cancel){ action in
                        self.dismissViewControllerAnimated(false, completion: { () -> Void in
                            let userInfo = [RegistAccountIDValue:registResult.accountId,RegistAccountPasswordValue:self.passwordTextField.text!]
                            NSNotificationCenter.defaultCenter().postNotificationName(RegistAccountCompleted, object: self, userInfo: userInfo)
                        })
                    }
                    self.showAlert("REGIST_SUC_TITLE".localizedString(), msg: String(format: "REGIST_SUC_MSG".localizedString(), registResult.accountId),actions: [action])
                }else{
                    self.hideIndicator()
                    self.playToast(errorMsg.localizedString())
                }
            }
        }
    }
    
    private func checkRegistValid() -> Bool{
        if (userNameTextField.text ?? "" ).isUsername(){
            if (passwordTextField.text ?? "" ).isPassword(){
                return true
            }else{
                passwordTextField.shakeAnimationForView()
            }
        }else{
            userNameTextField.shakeAnimationForView()
        }
        SystemSoundHelper.vibrate()
        return false
    }
    
    @IBAction func showSignIn(sender: AnyObject) {
        self.dismissViewControllerAnimated(false) { () -> Void in
            
        }
    }
    
    static func showSignUpViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "SignUpViewController") as! SignUpViewController
        vc.presentViewController(controller, animated: false) { () -> Void in
            
        }
    }
}
