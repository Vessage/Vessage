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
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        go()
    }
    
    func deInitController(){
        ChicagoClient.sharedInstance.removeObserver(self)
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
        showAlert(self,alertController: alert)
    }
    
    func onAppTokenInvalid(_:AnyObject)
    {
        let alert = UIAlertController(title: nil, message: "USER_APP_TOKEN_TIMEOUT".localizedString() , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Default, handler: { (action) -> Void in
            ServiceContainer.instance.userLogout()
            EntryNavigationController.start()
        }))
        showAlert(self,alertController: alert)
    }
    
    private func go()
    {
        ServiceContainer.instance.addObserver(self, selector: "allServicesReady:", name: ServiceContainer.AllServicesReady, object: nil)
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
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: "waitTimeShowSignView:", userInfo: nil, repeats: false)
    }
    
    func waitTimeShowSignView(_:AnyObject?)
    {
        SignInViewController.showSignInViewController(self)
    }
    
    private func showMainView()
    {
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: "waitTimeShowMainView:", userInfo: nil, repeats: false)
    }
    
    func waitTimeShowMainView(_:AnyObject?)
    {
        BahamutCmdManager.sharedInstance.registHandler(self)
        ConversationListController.showConversationListController(self)
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
