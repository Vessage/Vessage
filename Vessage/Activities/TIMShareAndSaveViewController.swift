//
//  TIMShareAndSaveViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/18.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class TIMShareAndSaveViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClickDone(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func shareToSNS(sender: AnyObject) {
        
    }

    @IBAction func shareToWXSession(sender: AnyObject) {
    }
    
    @IBAction func saveImage(sender: AnyObject) {
        
    }
}
