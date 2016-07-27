//
//  ChatImageMgrViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ChatImageMgrViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        let dict = [NSForegroundColorAttributeName:UIColor.themeColor]
        self.navigationController?.navigationBar.titleTextAttributes = dict
        
    }
    
    @IBAction func done(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatImageCell", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.height
    }

    static func showChatImageMgrVeiwController(vc:UIViewController){
        let controller = instanceFromStoryBoard("User", identifier: "ChatImageMgrViewController") as! ChatImageMgrViewController
        let nvc = UINavigationController(rootViewController: controller)
        vc.presentViewController(nvc, animated: true, completion: nil)
    }
}
