//
//  SetupChatBackgroundImageViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/20.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

//MARK: SetupChatBcgImageController
class SetupChatBcgImageController: UIViewController {
    
    @IBAction func openCamera(sender: AnyObject) {
        ChatBackgroundPickerController.showPickerController(self){ sender in
            MobClick.event("Vege_FinishSetupChatBcg")
            sender.dismissViewControllerAnimated(false, completion: { () -> Void in
                EntryNavigationController.start()
            })
        }
    }
    
    @IBAction func forceNext(sender: AnyObject) {
        UserSetting.enableSetting(USER_LATER_SET_CHAT_BCG_KEY)
        EntryNavigationController.start()
    }
    
    @IBAction func logout(sender: AnyObject) {
        ServiceContainer.instance.userLogout()
        EntryNavigationController.start()
    }
    
    static func showSetupViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("UserGuide", identifier: "SetupChatBcgImageController") as! SetupChatBcgImageController
        vc.presentViewController(controller, animated: false) { () -> Void in

        }
    }
}