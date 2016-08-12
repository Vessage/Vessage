//
//  MainTabBarController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK:MainTabBarController
class MainTabBarController: UITabBarController,UITabBarControllerDelegate {
    
    var conversationBadge:Int!{
        didSet{
            if let value = conversationBadge {
                UserSetting.setUserIntValue("ConversationListBadge", value: value)
                
            }
            self.viewControllers?[0].tabBarItem?.badgeValue = intToBadgeString(conversationBadge)
        }
    }
    
    var activityBadge:Int!{
        didSet{
            if let value = activityBadge {
                UserSetting.setUserIntValue("ActivityListBadge", value: value)
                
            }
            self.viewControllers?[1].tabBarItem?.badgeValue = intToBadgeString(activityBadge)
        }
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewControllers?[0] == viewController {
            conversationBadge = 0
        }else if viewControllers?[1] == viewController {
            activityBadge = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        conversationBadge = UserSetting.getUserIntValue("ConversationListBadge")
        activityBadge = UserSetting.getUserIntValue("ActivityListBadge")
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(MainTabBarController.onNewVessagesReceived(_:)), name: VessageService.onNewVessagesReceived, object: nil)
        ServiceContainer.getActivityService().addObserver(self, selector: #selector(MainTabBarController.onActivitiesBadgeUpdated(_:)), name: ActivityService.onEnabledActivitiesBadgeUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(MainTabBarController.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        tabBar.tintColor = UIColor.themeColor
    }
    
    deinit{
        self.viewControllers = nil
        
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    func onServicesWillLogout(a:NSNotification) {
        ServiceContainer.instance.removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
        ServiceContainer.getActivityService().removeObserver(self)
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func onActivitiesBadgeUpdated(a:NSNotification){
        if self.selectedIndex == 1 {
            return
        }
        if let count = a.userInfo?[UpdatedActivitiesBadgeValue] as? Int{
            if let ac = activityBadge{
                activityBadge = ac + count
            }else{
                activityBadge = count
            }
        }
    }
    
    func onNewVessagesReceived(a:NSNotification){
        if self.selectedIndex == 0{
            return
        }
        if let vsgs = a.userInfo?[VessageServiceNotificationValues] as? [Vessage]{
            if let badge = conversationBadge{
                conversationBadge = badge + vsgs.count
            }else{
                conversationBadge = vsgs.count
            }
        }
    }
    
    static func showMainController(viewController:UIViewController,completion:()->Void){
        let controller = instanceFromStoryBoard("Main", identifier: "MainTabBarController") as! MainTabBarController
        viewController.presentViewController(controller, animated: false) { () -> Void in
            completion()
            ServiceContainer.getActivityService().getActivitiesBoardData()
            ServiceContainer.getAppService().trySendFirstLaunchToServer()
            ServiceContainer.getVessageService().newVessageFromServer()
            #if DEBUG
                print("MainTabBarView Shown")
            #endif
        }
    }
}