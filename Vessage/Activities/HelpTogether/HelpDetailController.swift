//
//  HelpDetailController.swift
//  Vessage
//
//  Created by AlexChow on 16/6/6.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class HelpDetailController: UIViewController {
    
    var help:Help!{
        didSet{
            
        }
    }
    
    
    static func showHelpDetail(nvc:UINavigationController,help:Help) {
        let controller = instanceFromStoryBoard("HelpTogether", identifier: "HelpDetailController") as! HelpDetailController
        controller.help = help
        nvc.pushViewController(controller, animated: true)
    }
}
