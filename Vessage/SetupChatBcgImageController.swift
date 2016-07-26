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
class SetupChatBcgImageController: UIViewController,ChatBackgroundPickerControllerDelegate {
    
    @IBAction func openCamera(sender: AnyObject) {
        ChatBackgroundPickerController.showPickerController(self,delegate: self)
    }
    
    @IBAction func forceNext(sender: AnyObject) {
        UserSetting.enableSetting(USER_LATER_SET_CHAT_BCG_KEY)
        InviteFriendsViewController.showInviteFriendsViewController(self.navigationController!)
    }
    
    func chatBackgroundPickerSetImageCancel(sender: ChatBackgroundPickerController) {
        
    }
    
    func chatBackgroundPickerSetedImage(sender: ChatBackgroundPickerController) {
        sender.dismissViewControllerAnimated(true) {             
            MobClick.event("Vege_FinishSetupChatBcg")
            InviteFriendsViewController.showInviteFriendsViewController(self.navigationController!)
        }
    }
    
    static func showSetupViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("UserGuide", identifier: "SetupChatBcgImageController") as! SetupChatBcgImageController
        let nvc = UINavigationController(rootViewController: controller)
        nvc.navigationBarHidden = true
        vc.presentViewController(nvc, animated: true) { () -> Void in
            
        }
    }
}