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
    let screenWaitTimeInterval = 1.2
    let mottoCount = 1
    fileprivate static var instance:EntryNavigationController!
    
    fileprivate var mainViewPresented = false
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        EntryNavigationController.instance = self
        UIApplication.shared.delegate?.window!?.rootViewController = self
        ServiceContainer.instance.initContainer("Vege", services: ServicesConfig)
        setWaitingScreen()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setRandomMotto()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.addSubview(launchScr.view)
        self.mainViewPresented = false
        go()
    }
    
    func removeObservers(){
        ServiceContainer.getLocationService().removeObserver(self)
        ServiceContainer.instance.removeObserver(self)
    }

    fileprivate func setWaitingScreen() {
        self.view.backgroundColor = UIColor.white
        if launchScr == nil {
            launchScr = LaunchScreen.getInstanceFromStroyboard()
        }
        self.view.addSubview(launchScr.view)
        ColorSets.themeColor = UIColor(hexString: "#00ADFF")
        launchScr.mottoLabel.updateConstraints()
        launchScr.mottoLabel.isHidden = false
        setRandomMotto()
    }
    
    fileprivate func setRandomMotto(){
        let motto = "VESSAGE_MOTTO_\(random() % mottoCount)".localizedString()
        launchScr.mottoLabel.text = motto
    }
    
    func allServicesReady(_:AnyObject)
    {
        allServiceReadyGo()
    }
    
    fileprivate func allServiceReadyGo(){
        ServiceContainer.instance.removeObserver(self)
        let userService = ServiceContainer.getUserService()
        let isUserMobileValidated = userService.isUserMobileValidated
        if isUserMobileValidated
        {
            showMainView()
        }else{
            ValidateMobileViewController.showValidateMobileViewController(self,delegate: self)
        }
        
        let locationService = ServiceContainer.getLocationService()
        if let hereLocation = locationService.hereLocationString{
            userService.getNearUsers(hereLocation,checkTime: false)
        }
        locationService.addObserver(self, selector: #selector(EntryNavigationController.onHereLocationUpdated(_:)), name: LocationService.hereUpdated, object: nil)
        BahamutRFKit.sharedInstance.addObserver(self, selector: #selector(EntryNavigationController.onTokenInvalidated(_:)), name: BahamutRFKit.onTokenInvalidated, object: nil)
    }
    
    func onTokenInvalidated(_:AnyObject)
    {
        logoutWithAlert("USER_APP_TOKEN_TIMEOUT".localizedString())
    }
    
    fileprivate func logoutWithAlert(_ msg:String){
        BahamutRFKit.sharedInstance.removeObserver(self)
        
        let alert = UIAlertController(title: nil, message: msg , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .default, handler: { (action) -> Void in
            self.popToRootViewController(animated: false)
            ServiceContainer.instance.userLogout()
            EntryNavigationController.start()
        }))
        self.showAlert(alert)
    }
    
    func onHereLocationUpdated(_:Notification) {
        let locationService = ServiceContainer.getLocationService()
        if let hereLocation = locationService.hereLocationString{
            ServiceContainer.getUserService().getNearUsers(hereLocation,checkTime:true)
        }
    }
    
    func onOtherDeviceLogin(_:AnyObject)
    {
        logoutWithAlert("OTHER_DEVICE_HAD_LOGIN".localizedString())
    }
    
    fileprivate func go()
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
    
    fileprivate func showSignView()
    {
        Timer.scheduledTimer(timeInterval: screenWaitTimeInterval, target: self, selector: #selector(EntryNavigationController.waitTimeShowSignView(_:)), userInfo: nil, repeats: false)
    }
    
    func waitTimeShowSignView(_:AnyObject?)
    {
        SignInViewController.showSignInViewController(self)
    }
    
    fileprivate func showMainView()
    {
        let chattingUserIds = ServiceContainer.getConversationService().getChattingUserIds()
        let removedUsers = ServiceContainer.getUserService().clearTempUsers(chattingUserIds)
        debugLog("Removed Temp Users:\(removedUsers.count)")
        Timer.scheduledTimer(timeInterval: screenWaitTimeInterval, target: self, selector: #selector(EntryNavigationController.waitTimeShowMainView(_:)), userInfo: nil, repeats: false)
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
    func handleBahamutCmd(_ method: String, args: [String], object: AnyObject?) {
        
    }
    
    static func start()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.delegate?.window!?.rootViewController = EntryNavigationController.instance
            if !EntryNavigationController.instance.mainViewPresented{
                EntryNavigationController.instance.go()
            }
        })
    }
}

//MARK:ValidateMobileViewController Delegate
extension EntryNavigationController{
    func validateMobile(_ sender: ValidateMobileViewController, rebindedNewUserId: String) {
        ServiceContainer.getAccountService().reBindUserId(rebindedNewUserId)
    }
    
    func validateMobileCancel(_ sender: ValidateMobileViewController) {
        let ignore = UIAlertAction(title: "IGNORE_SETUP_MOBILE".localizedString(), style: .default) { (ac) in
            ServiceContainer.getUserService().useTempMobile()
            sender.dismiss(animated: true, completion: nil)
        }
        let resume = UIAlertAction(title: "CONTINUE_SETUP_MOBILE".localizedString(), style: .cancel) { (ac) in
            
        }
        self.showAlert("CANCEL_SETUP_MOBILE_TITLE".localizedString(), msg: "CANCEL_SETUP_MOBILE_MSG".localizedString(), actions: [resume,ignore])
        
    }
    
    func validateMobileIsTryBindExistsUser(_ sender: ValidateMobileViewController) -> Bool {
        return true
    }
    
    func validateMobile(_ sender: ValidateMobileViewController, suc: Bool) {
        
    }
    
}
