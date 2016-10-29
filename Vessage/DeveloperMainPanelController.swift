//
//  DeveloperMainPanelController.swift
//
//  Created by AlexChow on 16/1/29.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class DeveloperMainPanelController: UIViewController
{
    
    @IBOutlet weak var godModeSwitch: UISwitch!{
        didSet{
            godModeSwitch.on = UserSetting.godMode
        }
    }
    @IBOutlet weak var deviceTokenLabel: UILabel!{
        didSet{
            deviceTokenLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(DeveloperMainPanelController.onTapDeviceTokenLabel(_:))))
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        deviceTokenLabel.text = "DeviceToken:\(VessageSetting.deviceToken)"
    }
    
    func onTapDeviceTokenLabel(sender:AnyObject) {
        UIPasteboard.generalPasteboard().setValue(VessageSetting.deviceToken, forPasteboardType: "public.utf8-plain-text")
        self.playToast("Device Token Copied")
    }
    
    @IBAction func clearAllData(sender: AnyObject)
    {
        PersistentManager.sharedInstance.clearCache()
        PersistentManager.sharedInstance.clearRootDir()
    }
    
    @IBAction func use168Server(sender: AnyObject)
    {
        VessageSetting.loginApi = "http://192.168.1.168:8086/Account/AjaxLogin"
        VessageSetting.registAccountApi = "http://192.168.1.168:8086/Account/AjaxRegist"
        self.playToast("Change to 168")
    }
    
    @IBAction func use67Server(sender: AnyObject)
    {
        VessageSetting.loginApi = "http://192.168.1.67:8086/Account/AjaxLogin"
        VessageSetting.registAccountApi = "http://192.168.1.67:8086/Account/AjaxRegist"
        self.playToast("Change to 67")
    }
    
    @IBAction func closePanel(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(false) { () -> Void in
            
        }
    }
    
    @IBAction func godModeChanged(sender: AnyObject) {
        UserSetting.godMode = godModeSwitch.on
    }
    
    @IBAction func useRemoteServer(sender: AnyObject)
    {
        VessageSetting.loginApi = "http://auth.bahamut.cn:8086/Account/AjaxLogin"
        VessageSetting.registAccountApi = "http://auth.bahamut.cn:8086/Account/AjaxRegist"
        self.playToast("Change to remote")
    }
    
    static func isShowDeveloperPanel(controller:UIViewController,id:String,psw: String) -> Bool{
        if "\(id)\(psw)".sha256 == VessageConfig.bahamutConfig.godModeCode
        {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                UserSetting.isAppstoreReviewing = false
                DeveloperMainPanelController.showDeveloperMainPanel(controller)
            }
            return true
        }else
        {
            return false
        }
    }
    
    private static func showDeveloperMainPanel(viewController:UIViewController)
    {
        let controller = instanceFromStoryBoard("DeveloperPanel", identifier: "DeveloperMainPanelController")
        let navController = UINavigationController(rootViewController: controller)
        viewController.presentViewController(navController, animated: true) { () -> Void in
            
        }
    }
    
}

class GodModeManager {
    static func checkGodCode(vc:UIViewController,code:String) -> Bool{
        let testModeStrs = code.split(">")
        if testModeStrs.count == 2 {
            if DeveloperMainPanelController.isShowDeveloperPanel(vc, id: testModeStrs[0], psw: testModeStrs[1]){
                return true
            }
        }
        
        if UserSetting.isAppstoreReviewing && code.md5 == "1ecb0d59240781171ce96454f60f09db"{
            UserSetting.godMode = true
            vc.showAlert("Manager Mode", msg: "Request Manager Mode Successful")
            return true
        }
        
        if UserSetting.godMode == false {
            return false
        }
        
        #if DEBUG
            if code == "autorefreshoff" {
                vc.showAlert("God Mode", msg: "Auto Refresh Off")
                ConversationListController.autoRefreshData = false
                return true
            }else if code == "autorefreshon"{
                vc.showAlert("God Mode", msg: "Auto Refresh On")
                ConversationListController.autoRefreshData = true
                return true
            }
        #endif
        
        
        return false
    }
}
