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
    private var loginedResult:LoginResult!
    
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
    
    //MARK: OnRegistAccountCompleted
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
    
    //MARK: actions
    @IBAction func login(sender: AnyObject) {
        let hud = self.showActivityHudWithMessage(nil, message: "LOGINING".localizedString())
        BahamutRFKit.sharedInstance.loginBahamutAccount(VessageConfig.bahamutConfig.accountLoginApiUrl, accountInfo: loginInfoTextField.text!, passwordOrigin: passwordTextField.text!) { (isSuc, errorMsg, loginResult) -> Void in
            hud.hide(true)
            
            if isSuc
            {
                self.loginedResult = loginResult
                self.validateToken(self.loginedResult.AppServiceUrl, accountId: self.loginedResult.AccountID, accessToken: self.loginedResult.AccessToken)
            }else
            {
                self.playToast(errorMsg.localizedString())
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
    
    private var refreshingHud:MBProgressHUD!
    private func validateToken(serverUrl:String, accountId:String, accessToken: String)
    {
        let accountService = ServiceContainer.getService(AccountService)
        let hud = self.showActivityHudWithMessage("",message: "LOGINING".localizedString() )
        accountService.validateAccessToken(serverUrl, accountId: accountId, accessToken: accessToken, callback: { (loginSuccess, message) -> Void in
            hud.hideAsync(true)
            if loginSuccess{
                self.refreshingHud = self.showActivityHudWithMessage("",message:"REFRESHING".localizedString())
            }else{
                self.playToast( message)
            }
            
            }) { (registApiServer) -> Void in
                self.registNewUser(accountId,registApi: registApiServer,accessToken:accessToken)
        }
    }
    
    private var refreshHud:MBProgressHUD!
    private func registNewUser(accountId:String,registApi:String,accessToken:String)
    {
        let registModel = RegistNewUserModel()
        registModel.accessToken = accessToken
        registModel.registUserServer = registApi
        registModel.accountId = accountId
        registModel.region = VessageSetting.contry.lowercaseString
        
        let newUser = VessageUser()
        newUser.motto = "Vessage Is Video Message"
        newUser.nickName = loginedResult.AccountName ?? accountId
        
        let hud = self.showActivityHudWithMessage("",message:"REGISTING".localizedString())
        ServiceContainer.getService(AccountService).registNewUser(registModel, newUser: newUser){ isSuc,msg,validateResult in
            hud.hideAsync(true)
            if isSuc
            {
                self.refreshHud = self.showActivityHudWithMessage("",message:"REFRESHING".localizedString())
            }else
            {
                self.playToast(msg)
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
