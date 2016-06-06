//
//  HelpSquareController.swift
//  Vessage
//
//  Created by AlexChow on 16/6/6.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class HelpSquareItemCell: UITableViewCell {
    static let reuseId = "HelpSquareItemCell"
    var help:Help!{
        didSet{
            let nick = help.requestorNick
            headLine?.text = String(format: "X_NEED_HELP".HelpTogetherString, nick)
            subLine?.text = String(format: "HELP_REQ_TITLE_FORMAT".HelpTogetherString, help.category,help.title)
        }
    }
    @IBOutlet weak var headLine: UILabel!
    @IBOutlet weak var subLine: UILabel!
}

class HelpSquareController: UITableViewController {
    
    var helps:[[Help]] = [[Help]]()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 69
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        HelpTogetherManager.instance.getSquareHelpItems()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        HelpTogetherManager.instance.removeObserver(self)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return helps.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return helps[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(HelpSquareItemCell.reuseId, forIndexPath: indexPath) as! HelpSquareItemCell
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let help = helps[indexPath.section][indexPath.row]
        HelpDetailController.showHelpDetail(self.navigationController!, help: help)
    }
    
    static func showHelpSquare(nvc:UINavigationController) {
        let controller = instanceFromStoryBoard("HelpTogether", identifier: "HelpSquareController")
        nvc.pushViewController(controller, animated: true)
    }
}
