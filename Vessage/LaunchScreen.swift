//
//  LaunchScreenViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class LaunchScreen {
    private(set) var view:UIView!
    var mottoLabel:UILabel{
        return view.viewWithTag(1) as! UILabel
    }
    
    static func getInstanceFromStroyboard() -> LaunchScreen
    {
        let controller = UIViewController.instanceFromStoryBoard("LaunchScreen", identifier: "LaunchScreenViewController")
        let scr = LaunchScreen()
        controller.view.removeFromSuperview()
        scr.view = controller.view
        return scr
    }
    
}
