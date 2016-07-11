//
//  InviteFriendsViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

let INVITED_FRIEND_GUIDE_KEY = "INVITED_FRIEND_GUIDE_KEY"

class InviteFriendsViewController: UIViewController {
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        inviteButtonClick(self)
    }
    
    @IBAction func nextButtonClick(sender: AnyObject) {
        UserSetting.enableSetting(INVITED_FRIEND_GUIDE_KEY)
        MobClick.event("Vege_FinishInviteFriends")
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            EntryNavigationController.start()
        })
    }
    
    @IBAction func inviteButtonClick(sender: AnyObject) {
        ShareHelper.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG_IV".localizedString(),title: "TELL_FRIENDS_IV".localizedString())
    }
    
    static func showInviteFriendsViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("UserGuide", identifier: "InviteFriendsViewController") as! InviteFriendsViewController
        vc.presentViewController(controller, animated: true) { () -> Void in
            
        }
    }
}
