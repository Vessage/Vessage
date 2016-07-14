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
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        ServiceContainer.instance.initContainer("Vege", services: ServicesConfig)
        setWaitingScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        go()
    }
    
    func deInitController(){
        ServiceContainer.getLocationService().removeObserver(self)
        ServiceContainer.instance.removeObserver(self)
        
    }

    private func setWaitingScreen() {
        self.view.backgroundColor = UIColor.whiteColor()
        launchScr = LaunchScreen.getInstanceFromStroyboard()
        self.view.addSubview(launchScr.view)
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
            VessageQueue.sharedInstance.initObservers()
            showMainView()
        }else{
            ValidateMobileViewController.showValidateMobileViewController(self)
        }
        
        let locationService = ServiceContainer.getLocationService()
        if let hereLocation = locationService.hereLocationString{
            userService.getNearUsers(hereLocation)
        }
        locationService.addObserver(self, selector: #selector(EntryNavigationController.onHereLocationUpdated(_:)), name: LocationService.hereUpdated, object: nil)
    }
    
    func onHereLocationUpdated(_:NSNotification) {
        let locationService = ServiceContainer.getLocationService()
        if let hereLocation = locationService.hereLocationString{
            ServiceContainer.getUserService().getNearUsers(hereLocation,checkTime:true)
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
    
    let screenWaitTimeInterval = 1.2
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
            self.launchScr.view.removeFromSuperview()
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
                mnc.dismissViewControllerAnimated(false, completion: nil)
            }
            UIApplication.sharedApplication().delegate?.window!?.rootViewController = instanceFromStoryBoard("Main", identifier: "EntryNavigationController")
        })
    }
}
