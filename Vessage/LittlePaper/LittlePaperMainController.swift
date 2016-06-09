//
//  LittlePaperMainController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

extension String{
    var littlePaperString:String{
        return LocalizedString(self, tableName: "LittlePaper", bundle: NSBundle.mainBundle())
    }
}

class LittlePaperMainController: UIViewController {

    @IBOutlet weak var newPaperButton: UIButton!
    @IBOutlet weak var paperBoxButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LittlePaperManager.initManager()
        MobClick.event("LittlePaper_Launch")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        LittlePaperManager.instance.getPaperMessages { (suc) in
            self.refreshPaperBoxBadge()
        }
        
        LittlePaperManager.instance.refreshPaperMessage { (updated) in
            self.refreshPaperBoxBadge()
        }
    }
    
    private func refreshPaperBoxBadge(){
        let cnt = LittlePaperManager.instance.totalBadgeCount
        paperBoxButton.badgeValue = cnt > 0 ? "\(cnt)" : ""
    }
    
    @IBAction func tellFriends(sender: AnyObject) {
        ShareHelper.showTellVegeToFriendsAlert(self,message: "TELL_FRIENDS_LITTLE_PAPER".littlePaperString)
    }
    
    @IBAction func onClickNewPaperButton(sender: AnyObject) {
        WritePaperMessageViewController.showWritePaperMessageViewController(self)
    }
    
    @IBAction func onClickReceivedButton(sender: AnyObject) {
        LittlePaperMessageListController.showLittlePaperMessageListController(self)
    }

    @IBAction func onClickCloseButton() {
        LittlePaperManager.releaseManager()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
