//
//  EntryNavigationController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: EntryNavigationController
class EntryNavigationController: UINavigationController,HandleBahamutCmdDelegate,ValidateMobileViewControllerDelegate {

    var launchScr:LaunchScreen!
    let screenWaitTimeInterval = 1.0
    private static var instance:EntryNavigationController!
    
    private var mainViewPresented = false
    
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
        self.mainViewPresented = false
        go()
    }
    
    func removeObservers(){
        ServiceContainer.getLocationService().removeObserver(self)
        ServiceContainer.instance.removeObserver(self)
        
    }

    private func setWaitingScreen() {
        self.view.backgroundColor = UIColor.whiteColor()
        if launchScr == nil {
            launchScr = LaunchScreen.getInstanceFromStroyboard()
        }
        self.view.addSubview(launchScr.view)
        ColorSets.themeColor = UIColor(hexString: "#00ADFF")
        launchScr.mottoLabel.updateConstraints()
        let motto = "VESSAGE_MOTTO_\(random() % 3)".localizedString()
        launchScr.mottoLabel.text = motto
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
            BahamutTaskQueue.defaultInstance.initQueue(userService.myProfile.userId)
            BahamutTaskQueue.defaultInstance.useSetChatImageHandlers()
            showMainView()
        }else{
            ValidateMobileViewController.showValidateMobileViewController(self,delegate: self)
        }
        
        let locationService = ServiceContainer.getLocationService()
        if let hereLocation = locationService.hereLocationString{
            userService.getNearUsers(hereLocation)
        }
        locationService.addObserver(self, selector: #selector(EntryNavigationController.onHereLocationUpdated(_:)), name: LocationService.hereUpdated, object: nil)
        BahamutRFKit.sharedInstance.addObserver(self, selector: #selector(EntryNavigationController.onTokenInvalidated(_:)), name: BahamutRFKit.onTokenInvalidated, object: nil)
    }
    
    //MARK:ValidateMobileViewController Delegate
    func validateMobile(sender: ValidateMobileViewController, rebindedNewUserId: String) {
        ServiceContainer.getAccountService().reBindUserId(rebindedNewUserId)
    }
    
    func validateMobileCancel(sender: ValidateMobileViewController) {
        ServiceContainer.instance.userLogout()
    }
    
    func onTokenInvalidated(_:AnyObject)
    {
        logoutWithAlert("USER_APP_TOKEN_TIMEOUT".localizedString())
    }
    
    private func logoutWithAlert(msg:String){
        BahamutRFKit.sharedInstance.removeObserver(self)
        
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
            self.mainViewPresented = true
            self.launchScr?.view?.removeFromSuperview()
        }
    }

    //MARK: handle Bahamut Cmd
    func handleBahamutCmd(method: String, args: [String], object: AnyObject?) {
        
    }
    
    static func start()
    {
        VessageQueue.sharedInstance.releaseQueue()
        BahamutTaskQueue.defaultInstance.releaseQueue()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().delegate?.window!?.rootViewController = EntryNavigationController.instance
            if !EntryNavigationController.instance.mainViewPresented{
                EntryNavigationController.instance.go()
            }
        })
    }
}
