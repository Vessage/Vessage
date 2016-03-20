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
    
    @IBOutlet weak var loginInfoTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.instance.addObserver(self, selector: "onInitServiceFailed:", name: ServiceContainer.ServiceInitFailed, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onRegistAccountCompleted:", name: RegistAccountCompleted, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.instance.removeObserver(self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: notifications
    func onRegistAccountCompleted(a:NSNotification)
    {
        if let accountId = a.userInfo?[RegistAccountIDValue] as? String{
            if let password = a.userInfo?[RegistAccountPasswordValue] as? String{
                self.loginInfoTextField.text = accountId
                self.passwordTextField.text = password
                login(self)
            }
        }
    }
    
    func onInitServiceFailed(a:NSNotification){
        if let hud = refreshingHud{
            hud.hideAsync(false)
        }
        if let reason = a.userInfo?[InitServiceFailedReason] as? String{
            self.playToast(reason.localizedString())
        }
    }
    
    //MARK: actions
    private func loginWith(userInfo:String,psw:String){
        self.hideKeyBoard()
        let hud = self.showActivityHudWithMessage(nil, message: "LOGINING".localizedString())
        BahamutRFKit.sharedInstance.loginBahamutAccount(VessageConfig.bahamutConfig.accountLoginApiUrl, accountInfo: userInfo, passwordOrigin: psw) { (isSuc, errorMsg, loginResult) -> Void in
            hud.hide(true)
            
            if isSuc
            {
                self.validateToken(loginResult)
            }else
            {
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
    
    
    private var refreshingHud:MBProgressHUD!{
        didSet{
            if let old = oldValue{
                old.hideAsync(true)
            }
        }
    }
    private func validateToken(loginedResult:LoginResult)
    {
        let accountService = ServiceContainer.getService(AccountService)
        let hud = self.showActivityHudWithMessage("",message: "LOGINING".localizedString() ,async: false)
        accountService.validateAccessToken(loginedResult.AppServiceUrl, accountId: loginedResult.AccountID, accessToken: loginedResult.AccessToken, callback: { (loginSuccess, message) -> Void in
            hud.hide(false)
            if loginSuccess{
                self.refreshingHud = self.showActivityHudWithMessage("",message:"REFRESHING".localizedString())
            }else{
                self.playToast( message)
            }
            
            }) { (registValidateResult) -> Void in
                hud.hide(false)
                self.registNewUser(loginedResult,registValidateResult:registValidateResult)
        }
    }
    
    private var refreshHud:MBProgressHUD!
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
        
        let hud = self.showActivityHudWithMessage("",message:"REGISTING".localizedString(),async: false)
        ServiceContainer.getService(AccountService).registNewUser(registModel, newUser: newUser){ isSuc,msg,validateResult in
            hud.hide(false)
            if isSuc
            {
                self.refreshHud = self.showActivityHudWithMessage("",message:"REFRESHING".localizedString())
            }else
            {
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
