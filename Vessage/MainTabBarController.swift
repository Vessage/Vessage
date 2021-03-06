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
    
    fileprivate(set) static var instance:MainTabBarController?
    
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
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewControllers?[0] == viewController {
            conversationBadge = 0
        }else if viewControllers?[1] == viewController {
            activityBadge = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        self.modalTransitionStyle = .crossDissolve
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
    
    func onServicesWillLogout(_ a:Notification) {
        
        VessageQueue.sharedInstance.releaseQueue()
        BahamutTaskQueue.defaultInstance.releaseQueue()
        VessageTimeMachine.instance.releaseManager()
        BubbleVessageHandlerManager.release()
        
        ServiceContainer.instance.removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
        ServiceContainer.getActivityService().removeObserver(self)
        self.dismiss(animated: false){
            MainTabBarController.instance = nil
        }
        ServiceContainer.getUserService().removeUserDeviceTokenFromServer(VessageSetting.deviceToken)
    }
    
    func onActivitiesBadgeUpdated(_ a:Notification){
        if self.selectedIndex == 1 {
            return
        }
        var newBadge = 0
        if let count = a.userInfo?[UpdatedActivitiesBadgeValue] as? Int{
            newBadge = count
        }
        
        if (a.userInfo?[UpdatedActivityMiniBadgeValue] as? Bool) ?? false {
            newBadge += 1
        }
        
        if let ac = activityBadge{
            activityBadge = ac + newBadge
        }else{
            activityBadge = newBadge
        }
    }
    
    func onNewVessagesReceived(_ a:Notification){
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
    
    static func showMainController(_ viewController:UIViewController,completion:@escaping ()->Void){
        let controller = instanceFromStoryBoard("Main", identifier: "MainTabBarController") as! MainTabBarController
        viewController.present(controller, animated: false) { () -> Void in
            MainTabBarController.instance = controller
            completion()
            
            VessageQueue.sharedInstance.initQueue(UserSetting.userId)
            BubbleVessageHandlerManager.loadEmbededHandlers()
            BahamutTaskQueue.defaultInstance.initQueue(UserSetting.userId)
            VessageTimeMachine.instance.initWithUserId(UserSetting.userId)
            
            ServiceContainer.getActivityService().getActivitiesBoardData()
            ServiceContainer.getVessageService().newVessageFromServer(){
                ServiceContainer.getAppService().trySendFirstLaunchToServer()
            }
            #if DEBUG
                print("MainTabBarView Shown")
            #endif
        }
    }
}
