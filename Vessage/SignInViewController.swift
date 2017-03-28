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
class SignInViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var refreshingIndicator: UIActivityIndicatorView!{
        didSet{
            refreshingIndicator.hidesWhenStopped = true
            refreshingIndicator.stopAnimating()
        }
    }
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginInfoTextField: UITextField!{
        didSet{
            loginInfoTextField.delegate = self
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField!{
        didSet{
            passwordTextField.delegate = self
        }
    }
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.instance.addObserver(self, selector: #selector(SignInViewController.onInitServices(_:)), name: ServiceContainer.OnAllServicesReady, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(SignInViewController.onInitServiceFailed(_:)), name: ServiceContainer.OnServiceInitFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.onRegistAccountCompleted(_:)), name: NSNotification.Name(rawValue: RegistAccountCompleted), object: nil)
        self.loginInfoTextField.text = UserSetting.lastLoginAccountId
        self.passwordTextField.text = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.instance.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserSetting.isSettingEnable("FirstLogined") == false{
            UserSetting.setSetting("FirstLogined", enable: true)
            if String.isNullOrWhiteSpace(UserSetting.lastLoginAccountId){
                showSignUp(self)
            }
        }
    }
    
    //MARK: notifications
    func onRegistAccountCompleted(_ a:Notification)
    {
        if let accountId = a.userInfo?[RegistAccountIDValue] as? String{
            if let password = a.userInfo?[RegistAccountPasswordValue] as? String{
                self.loginInfoTextField.text = accountId
                self.passwordTextField.text = password
                
                let action = UIAlertAction(title: "OK".localizedString(), style:.cancel){ action in
                    self.login(self)
                }
                self.showAlert("REGIST_SUC_TITLE".localizedString(), msg: String(format: "REGIST_SUC_MSG".localizedString(), accountId),actions: [action])
                
            }
        }
    }
    
    func onInitServices(_ a:Notification){
        self.dismiss(animated: false, completion: nil)
    }
    
    func onInitServiceFailed(_ a:Notification){
        hideIndicator()
        if let reason = a.userInfo?[InitServiceFailedReason] as? String{
            self.playToast(reason.localizedString())
        }
    }
    
    //MARK: TextField Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            if textField == self.loginInfoTextField {
                self.passwordTextField.becomeFirstResponder()
            }else if textField == self.passwordTextField{
                self.login(textField)
            }
        }
        return true
    }
    
    //MARK: actions
    fileprivate func loginWith(_ userInfo:String,psw:String){
        if DeveloperMainPanelController.isShowDeveloperPanel(self,id:userInfo,psw:psw){
            return
        }
        
        self.hideKeyBoard()
        self.showIndicator()
        BahamutRFKit.sharedInstance.loginBahamutAccount(VessageSetting.loginApi, accountInfo: userInfo, passwordOrigin: psw) { (isSuc, errorMsg, loginResult) -> Void in
            if isSuc
            {
                self.validateToken(loginResult!)
            }else
            {
                self.hideIndicator()
                if let msg = errorMsg?.localizedString(){
                    self.playToast(msg)
                }
            }
        }
    }
    
    @IBAction func login(_ sender: AnyObject) {
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
    
    fileprivate func showIndicator(){
        self.refreshingIndicator.startAnimating()
        self.refreshingIndicator.isHidden = false
        self.loginButton.isHidden = true
        self.view.isUserInteractionEnabled = false
    }
    
    fileprivate func hideIndicator(){
        self.refreshingIndicator.stopAnimating()
        self.loginButton.isHidden = false
        self.view.isUserInteractionEnabled = true
    }
    
    fileprivate func validateToken(_ loginedResult:LoginResult)
    {
        let accountService = ServiceContainer.getAccountService()
        self.showIndicator()
        accountService.validateAccessToken(loginedResult.appServiceUrl, accountId: loginedResult.accountID, accessToken: loginedResult.accessToken, callback: { (loginSuccess, message) -> Void in
            if loginSuccess{
                self.showIndicator()
            }else{
                self.hideIndicator()
                self.playToast( message)
            }
            
            }) { (registValidateResult) -> Void in
                self.registNewUser(loginedResult,registValidateResult:registValidateResult!)
        }
    }
    
    fileprivate func registNewUser(_ loginedResult:LoginResult, registValidateResult:ValidateResult)
    {
        let registModel = RegistNewUserModel()
        registModel.accessToken = loginedResult.accessToken
        registModel.registUserServer = registValidateResult.registAPIServer
        registModel.accountId = loginedResult.accountID
        registModel.region = VessageSetting.contry.lowercased()
        
        let newUser = VessageUser()
        newUser.motto = "Vessage Is Video Message"
        newUser.nickName = loginedResult.accountName ?? loginedResult.accountID
        
        self.showIndicator()
        ServiceContainer.getAccountService().registNewUser(registModel, newUser: newUser){ isSuc,msg,validateResult in
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

    @IBAction func showSignUp(_ sender: AnyObject) {
        SignUpViewController.showSignUpViewController(self)
    }
    
    static func showSignInViewController(_ vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "SignInViewController") as! SignInViewController
        vc.present(controller, animated: false) { () -> Void in
            
        }
    }
}
