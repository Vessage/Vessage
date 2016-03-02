//
//  RecordMessageController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: RecordMessageController
class RecordMessageController: UIViewController {

    private var recording = false
    
    @IBOutlet weak var smileFaceImageView: UIImageView!
    
    //MARK: actions
    @IBAction func cancelRecord(sender: AnyObject) {
        self.dismissViewControllerAnimated(false) { () -> Void in
            
        }
    }
    
    @IBAction func recordButtonClicked(sender: AnyObject) {
    }
    
    private func startRecord()
    {
        
    }
    
    private func stopRecord()
    {
        
    }
    
    private func sendRecord()
    {
        
    }
    
    static func showRecordMessageController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("Main", identifier: "RecordMessageController")
        vc.presentViewController(controller, animated: false) { () -> Void in
            
        }
    }
}
