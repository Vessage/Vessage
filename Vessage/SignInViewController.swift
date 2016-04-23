//
//  SignInViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import MBProgressHUD

//MARK: SignInViewController
class SignInViewController: UIViewController {
    
    @IBOutlet weak var refreshingIndicator: UIActivityIndicatorView!{
        didSet{
            refreshingIndicator.hidesWhenStopped = true
            refreshingIndicator.stopAnimating()
        }
    }
    @IBOutlet weak var loginButton: UIButton!{
        didSet{
            let img = UIImage(named: "check")!.imageWithRenderingMode(.AlwaysTemplate)
            loginButton.setImage(img, forState: .Normal)
            loginButton.tintColor = UIColor.whiteColor()
        }
    }
    @IBOutlet weak var loginInfoTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.instance.addObserver(self, selector: "onInitServiceFailed:", name: ServiceContainer.ServiceInitFailed, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onRegistAccountCompleted:", name: RegistAccountCompleted, object: nil)
        self.loginInfoTextField.text = UserSetting.lastLoginAccountId
        self.passwordTextField.text = nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.instance.removeObserver(self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if UserSetting.isSettingEnable("FirstLogined") == false{
            UserSetting.setSetting("FirstLogined", enable: true)
            if String.isNullOrWhiteSpace(UserSetting.lastLoginAccountId){
                showSignUp(self)
            }
        }
    }
    
    //MARK: notifications
    func onRegistAccountCompleted(a:NSNotification)
    {
        if let accountId = a.userInfo?[RegistAccountIDValue] as? String{
            if let password = a.userInfo?[RegistAccountPasswordValue] as? String{
                self.loginInfoTextField.text = accountId
                self.passwordTextField.text = password
                
                let action = UIAlertAction(title: "OK".localizedString(), style:.Cancel){ action in
                    self.login(self)
                }
                self.showAlert("REGIST_SUC_TITLE".localizedString(), msg: String(format: "REGIST_SUC_MSG".localizedString(), accountId),actions: [action])
                
            }
        }
    }
    
    func onInitServiceFailed(a:NSNotification){
        hideIndicator()
        if let reason = a.userInfo?[InitServiceFailedReason] as? String{
            self.playToast(reason.localizedString())
        }
    }
    
    //MARK: actions
    private func loginWith(userInfo:String,psw:String){
        if DeveloperMainPanelController.isShowDeveloperPanel(self,id:userInfo,psw:psw){
            return
        }
        
        self.hideKeyBoard()
        self.showIndicator()
        BahamutRFKit.sharedInstance.loginBahamutAccount(VessageSetting.loginApi, accountInfo: userInfo, passwordOrigin: psw) { (isSuc, errorMsg, loginResult) -> Void in
            if isSuc
            {
                self.validateToken(loginResult)
            }else
            {
                self.hideIndicator()
                self.playToast(errorMsg.localizedString())
            }
        }
    }
    
    @IBAction func login(sender: AnyObject) {
        if (loginInfoTextField.text ?? "" ).isUsername(){
            if (passwordTextField.text ?? "" ).isPassword(){
                self.loginWith(loginInfoTextField.text!, psw: passwordTextField.text!)
            }else{
                passwordTextField.shakeAnimationForView()
                SystemSoundHelper.vibrate()
            }
        }else{
            loginInfoTextField.shakeAnimationForView()
            SystemSoundHelper.vibrate()
        }
        
    }
    
    private func showIndicator(){
        self.refreshingIndicator.startAnimating()
        self.refreshingIndicator.hidden = false
        self.loginButton.hidden = true
        self.view.userInteractionEnabled = false
    }
    
    private func hideIndicator(){
        self.refreshingIndicator.stopAnimating()
        self.loginButton.hidden = false
        self.view.userInteractionEnabled = true
    }
    
    private func validateToken(loginedResult:LoginResult)
    {
        let accountService = ServiceContainer.getService(AccountService)
        self.showIndicator()
        accountService.validateAccessToken(loginedResult.AppServiceUrl, accountId: loginedResult.AccountID, accessToken: loginedResult.AccessToken, callback: { (loginSuccess, message) -> Void in
            if loginSuccess{
                self.showIndicator()
            }else{
                self.hideIndicator()
                self.playToast( message)
            }
            
            }) { (registValidateResult) -> Void in
                self.registNewUser(loginedResult,registValidateResult:registValidateResult)
        }
    }
    
    private func registNewUser(loginedResult:LoginResult, registValidateResult:ValidateResult)
    {
        let registModel = RegistNewUserModel()
        registModel.accessToken = loginedResult.AccessToken
        registModel.registUserServer = registValidateResult.RegistAPIServer
        registModel.accountId = loginedResult.AccountID
        registModel.region = VessageSetting.contry.lowercaseString
        
        let newUser = VessageUser()
        newUser.motto = "Vessage Is Video Message"
        newUser.nickName = loginedResult.AccountName ?? loginedResult.AccountID
        
        self.showIndicator()
        ServiceContainer.getService(AccountService).registNewUser(registModel, newUser: newUser){ isSuc,msg,validateResult in
            if isSuc
            {
                self.showIndicator()
            }else
            {
                self.hideIndicator()
                self.showAlert(nil, msg: msg)
            }
        }
    }

    @IBAction func showSignUp(sender: AnyObject) {
        SignUpViewController.showSignUpViewController(self)
    }
    
    static func showSignInViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "SignInViewController") as! SignInViewController
        vc.presentViewController(controller, animated: false) { () -> Void in
            
        }
    }
}
