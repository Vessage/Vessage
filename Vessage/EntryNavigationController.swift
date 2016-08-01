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

    var launchScr:LaunchScreen!
    let screenWaitTimeInterval = 1.0
    private static var instance:EntryNavigationController!
    
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        EntryNavigationController.instance = self
        UIApplication.sharedApplication().delegate?.window!?.rootViewController = self
        ServiceContainer.instance.initContainer("Vege", services: ServicesConfig)
        setWaitingScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.view.addSubview(launchScr.view)
        go()
    }
    
    func removeObservers(){
        BahamutRFKit.sharedInstance.removeObserver(self)
        ServiceContainer.getLocationService().removeObserver(self)
        ServiceContainer.instance.removeObserver(self)
        
    }

    private func setWaitingScreen() {
        self.view.backgroundColor = UIColor.whiteColor()
        if launchScr == nil {
            launchScr = LaunchScreen.getInstanceFromStroyboard()
        }
        self.view.addSubview(launchScr.view)
        ColorSets.themeColor = launchScr.view.backgroundColor!
        launchScr.mottoLabel.updateConstraints()
        launchScr.mottoLabel.text = "VESSAGE_MOTTO".localizedString()
        launchScr.mottoLabel.hidden = false
    }
    
    func allServicesReady(_:AnyObject)
    {
        allServiceReadyGo()
    }
    
    private func allServiceReadyGo(){
        ServiceContainer.instance.removeObserver(self)
        let userService = ServiceContainer.getUserService()
        let isUserMobileValidated = userService.isUserMobileValidated
        if isUserMobileValidated
        {
            VessageQueue.sharedInstance.initQueue(userService.myProfile.userId)
            showMainView()
        }else{
            ValidateMobileViewController.showValidateMobileViewController(self)
        }
        
        let locationService = ServiceContainer.getLocationService()
        if let hereLocation = locationService.hereLocationString{
            userService.getNearUsers(hereLocation)
        }
        locationService.addObserver(self, selector: #selector(EntryNavigationController.onHereLocationUpdated(_:)), name: LocationService.hereUpdated, object: nil)
        BahamutRFKit.sharedInstance.addObserver(self, selector: #selector(EntryNavigationController.onTokenInvalidated(_:)), name: BahamutRFKit.onTokenInvalidated, object: nil)
    }
    
    func onTokenInvalidated(_:AnyObject)
    {
        logoutWithAlert("TOKEN_TIMEOUT_PLEASE_RELOGIN".localizedString())
    }
    
    private func logoutWithAlert(msg:String){
        
        let alert = UIAlertController(title: nil, message: msg , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Default, handler: { (action) -> Void in
            self.popToRootViewControllerAnimated(false)
            ServiceContainer.instance.userLogout()
            EntryNavigationController.start()
        }))
        self.showAlert(alert)
    }
    
    func onHereLocationUpdated(_:NSNotification) {
        let locationService = ServiceContainer.getLocationService()
        if let hereLocation = locationService.hereLocationString{
            ServiceContainer.getUserService().getNearUsers(hereLocation,checkTime:true)
        }
    }
    
    func onOtherDeviceLogin(_:AnyObject)
    {
        logoutWithAlert("OTHER_DEVICE_HAD_LOGIN".localizedString())
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
        if UserSetting.isUserLogined
        {
            if ServiceContainer.isAllServiceReady
            {
                allServiceReadyGo()
            }else
            {
                ServiceContainer.instance.addObserver(self, selector: #selector(EntryNavigationController.allServicesReady(_:)), name: ServiceContainer.OnAllServicesReady, object: nil)
                ServiceContainer.instance.userLogin(UserSetting.userId)
            }
        }else
        {
            showSignView()
        }
    }
    
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
        removeObservers()
        MainTabBarController.showMainController(self){
            self.launchScr?.view?.removeFromSuperview()
        }
    }

    //MARK: handle Bahamut Cmd
    func handleBahamutCmd(method: String, args: [String], object: AnyObject?) {
        
    }
    
    static func start()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().delegate?.window!?.rootViewController = EntryNavigationController.instance
        })
    }
}
