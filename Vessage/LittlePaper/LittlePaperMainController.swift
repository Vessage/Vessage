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

        // Do any additional setup after loading the view.
    }

    @IBAction func onClickNewPaperButton(sender: AnyObject) {
    }
    
    @IBAction func onClickReceivedButton(sender: AnyObject) {
    }

    @IBAction func onClickCloseButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
