//
//  LaunchScreenViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class LaunchScreen: UIView {
    
    static func getInstanceFromStroyboard() -> LaunchScreen
    {
        let controller = UIViewController.instanceFromStoryBoard("LaunchScreen", identifier: "LaunchScreenViewController")
        return controller.view as! LaunchScreen
    }
    
}
