//
//  EntryNavigationController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: EntryNavigationController
class EntryNavigationController: UINavigationController,HandleBahamutCmdDelegate {

    var launchScr:UIView!
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        setWaitingScreen()
        
        //MARK: Chicago
//        ChicagoClient.sharedInstance.addObserver(self, selector: "onAppTokenInvalid:", name: AppTokenInvalided, object: nil)
//        ChicagoClient.sharedInstance.addObserver(self, selector: "onOtherDeviceLogin:", name: OtherDeviceLoginChicagoServer, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        go()
    }
    
    func deInitController(){
        ServiceContainer.instance.removeObserver(self)
        
        //MARK: Chicago
        //ChicagoClient.sharedInstance.removeObserver(self)
    }

    private func setWaitingScreen() {
        self.view.backgroundColor = UIColor.whiteColor()
        launchScr = LaunchScreen.getInstanceFromStroyboard()
        launchScr.frame = self.view.bounds
        self.view.addSubview(launchScr)
    }
    
    func allServicesReady(_:AnyObject)
    {
        ServiceContainer.instance.removeObserver(self)
        VessageQueue.sharedInstance.initObservers()
        if let _ = self.presentedViewController
        {
            EntryNavigationController.start()
        }else
        {
            allServiceReadyGo()
        }
    }
    
    private func allServiceReadyGo(){
        if ServiceContainer.getService(UserService).isUserMobileValidated
        {
            if ServiceContainer.getService(UserService).isUserChatBackgroundIsSeted{
                showMainView()
            }else{
                SetupChatBcgImageController.showSetupViewController(self)
            }
        }else{
            ValidateMobileViewController.showValidateMobileViewController(self)
        }
    }
    
    func onOtherDeviceLogin(_:AnyObject)
    {
        let alert = UIAlertController(title: nil, message: "OTHER_DEVICE_HAD_LOGIN".localizedString() , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Default, handler: { (action) -> Void in
            ServiceContainer.instance.userLogout()
            EntryNavigationController.start()
        }))
        self.showAlert(alert)
    }
    
    func onAppTokenInvalid(_:AnyObject)
    {
        let alert = UIAlertController(title: nil, message: "USER_APP_TOKEN_TIMEOUT".localizedString() , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Default, handler: { (action) -> Void in
            ServiceContainer.instance.userLogout()
            EntryNavigationController.start()
        }))
        self.showAlert(alert)
    }
    
    private func go()
    {
        ServiceContainer.instance.addObserver(self, selector: #selector(EntryNavigationController.allServicesReady(_:)), name: ServiceContainer.OnAllServicesReady, object: nil)
        if UserSetting.isUserLogined
        {
            if ServiceContainer.isAllServiceReady
            {
                ServiceContainer.instance.removeObserver(self)
                allServiceReadyGo()
            }else
            {
                ServiceContainer.instance.userLogin(UserSetting.userId)
            }
        }else
        {
            showSignView()
        }
    }
    
    let screenWaitTimeInterval = 0.3
    private func showSignView()
    {
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: #selector(EntryNavigationController.waitTimeShowSignView(_:)), userInfo: nil, repeats: false)
    }
    
    func waitTimeShowSignView(_:AnyObject?)
    {
        SignInViewController.showSignInViewController(self)
    }
    
    private func showMainView()
    {
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: #selector(EntryNavigationController.waitTimeShowMainView(_:)), userInfo: nil, repeats: false)
    }
    
    func waitTimeShowMainView(_:AnyObject?)
    {
        BahamutCmdManager.sharedInstance.registHandler(self)
        MainTabBarController.showMainController(self)
        if self.launchScr != nil
        {
            self.launchScr.removeFromSuperview()
        }
        
    }

    //MARK: handle Bahamut Cmd
    func handleBahamutCmd(method: String, args: [String], object: AnyObject?) {
        
    }
    
    static func start()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let mnc = UIApplication.sharedApplication().delegate?.window!?.rootViewController as? EntryNavigationController{
                mnc.deInitController()
            }
            UIApplication.sharedApplication().delegate?.window!?.rootViewController = instanceFromStoryBoard("Main", identifier: "EntryNavigationController")
        })
    }
}
