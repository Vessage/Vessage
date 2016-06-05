//
//  HelpTogetherMainController.swift
//  Vessage
//
//  Created by AlexChow on 16/6/4.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class HelpTogetherSquareCell: UITableViewCell {
    static let reuseId = "HelpTogetherSquareCell"
    @IBOutlet weak var messageLabel: UILabel!
}

class HelpTogetherItemCell: UITableViewCell {
    static let reuseId = "HelpTogetherItemCell"
    @IBOutlet weak var subLine: UILabel!
    @IBOutlet weak var headLine: UILabel!
}

class HelpTogetherMainController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        HelpTogetherManager.initManager()
        tableView.estimatedRowHeight = 69
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        HelpTogetherManager.instance.refreshMyHelpItems { 
            self.tableView.reloadSections(NSIndexSet(index:1), withRowAnimation: .Automatic)
        }
        
        HelpTogetherManager.instance.getSquareHelpItems { 
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return 10;
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = nil
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier(HelpTogetherSquareCell.reuseId, forIndexPath: indexPath)
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier(HelpTogetherItemCell.reuseId, forIndexPath: indexPath)
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 10
        }
        return 0
    }

    @IBAction func postNewHelp(sender: AnyObject) {
        
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

}
