//
//  LittlePaperMainController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class LittlePaperMainController: UIViewController {

    @IBOutlet weak var newPaperButton: UIButton!
    @IBOutlet weak var receivedPaperButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LittlePaperManager.initManager()
        LittlePaperManager.instance.getPaperMessages { (suc) in
            
        }
        
        LittlePaperManager.instance.refreshPaperMessage { (updated) in
            
        }
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
