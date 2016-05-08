//
//  MainTabBarController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class MainTabBarController: UITabBarController {
    static func showMainController(viewController:UIViewController){
        let controller = instanceFromStoryBoard("Main", identifier: "MainTabBarController") as! MainTabBarController
        viewController.presentViewController(controller, animated: false) { () -> Void in

        }
    }
}