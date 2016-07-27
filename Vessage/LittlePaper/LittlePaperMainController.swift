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
    @IBOutlet weak var returnBoxButton: UIButton!
    private var firstAppear = true
    override func viewDidLoad() {
        super.viewDidLoad()
        LittlePaperManager.initManager()
        
        MobClick.event("LittlePaper_Launch")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if firstAppear {
            firstAppear = false
            fetchServerData()
            ServiceContainer.getActivityService().addObserver(self, selector: #selector(LittlePaperMainController.onActivityUpdated(_:)), name: ActivityService.onEnabledActivityBadgeUpdated, object: nil)
        }else{
            self.refreshPaperBoxBadge()
            self.refreshReturnBox()
        }
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    func onActivityUpdated(a:NSNotification) {
        if let id = a.userInfo?[UpdatedActivityIdValue] as? String{
            if id == LittlePaperManager.ACTIVITY_ID{
                fetchServerData()
            }
        }
    }
    
    private func fetchServerData(){
        LittlePaperManager.instance.getPaperMessages { (suc) in
            self.refreshPaperBoxBadge()
        }
        
        LittlePaperManager.instance.refreshPaperMessage { (updated) in
            self.refreshPaperBoxBadge()
        }
        
        LittlePaperManager.instance.getReadPaperResponses(){
            self.refreshReturnBox()
        }
    }
    
    private func refreshReturnBox(){
        let cnt = LittlePaperManager.instance.notReadResponseCount
        returnBoxButton.badgeValue = intToBadgeString(cnt)
    }
    
    private func refreshPaperBoxBadge(){
        let cnt = LittlePaperManager.instance.totalBadgeCount
        paperBoxButton.badgeValue = intToBadgeString(cnt)
    }
    
    @IBAction func tellFriends(sender: AnyObject) {
        ShareHelper.showTellVegeToFriendsAlert(self,message: "TELL_FRIENDS_LITTLE_PAPER".littlePaperString,alertMsg: "TELL_FRIENDS_LITTLE_PAPER_ALERT_MSG".littlePaperString)
    }
    
    @IBAction func onClickNewPaperButton(sender: AnyObject) {
        WritePaperMessageViewController.showWritePaperMessageViewController(self)
    }
    
    @IBAction func onClickReceivedButton(sender: AnyObject) {
        LittlePaperMessageListController.showLittlePaperMessageListController(self)
    }

    @IBAction func onClickReturnBox() {
        LittlePaperResponseViewController.showLittlePaperResponseViewController(self)
    }
    
    @IBAction func onClickCloseButton() {
        ServiceContainer.getActivityService().removeObserver(self)
        LittlePaperManager.releaseManager()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
