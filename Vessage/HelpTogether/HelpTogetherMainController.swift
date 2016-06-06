//
//  HelpTogetherMainController.swift
//  Vessage
//
//  Created by AlexChow on 16/6/4.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

extension String{
    var HelpTogetherString:String{
        return LocalizedString(self, tableName: "HelpTogether", bundle: NSBundle.mainBundle())
    }
}

class HelpTogetherSquareCell: UITableViewCell {
    static let reuseId = "HelpTogetherSquareCell"
    @IBOutlet weak var messageLabel: UILabel!
}

class HelpTogetherItemCell: UITableViewCell {
    static let reuseId = "HelpTogetherItemCell"
    var rootController:HelpTogetherMainController!
    
    var help:Help!{
        didSet{
            var nick = help.requestorNick
            if let noteName = rootController.userService.getUserNotedNameIfExists(help.requestor){
                nick = noteName
            }
            headLine?.text = String(format: "X_SEND_A_HELP_REQ_TO_U".HelpTogetherString, nick)
            subLine?.text = String(format: "HELP_REQ_TITLE_FORMAT".HelpTogetherString, help.category,help.title)
        }
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var subLine: UILabel!
    @IBOutlet weak var headLine: UILabel!
}

class HelpTogetherMainController: UITableViewController {

    private(set) var userService:UserService!
    override func viewDidLoad() {
        super.viewDidLoad()
        userService = ServiceContainer.getService(UserService)
        HelpTogetherManager.initManager(userService.myProfile)
        tableView.estimatedRowHeight = 69
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        HelpTogetherManager.instance.refreshMyHelpItems()
        HelpTogetherManager.instance.getSquareHelpItems()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        HelpTogetherManager.instance.addObserver(self, selector: #selector(HelpTogetherMainController.onMyHelpItemsUpdated(_:)), name: HelpTogetherManager.onMyHelpItemsUpdated, object: nil)
        refreshMyHelpItems()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        HelpTogetherManager.instance.removeObserver(self)
    }

    func onMyHelpItemsUpdated(_:NSNotification) {
        refreshMyHelpItems()
    }
    
    private func refreshMyHelpItems(){
        tableView.reloadSections(NSIndexSet(indexesInRange: NSRange(location: 1, length: 2)), withRowAnimation: .Automatic)
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 + 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else if section == 1{
            return HelpTogetherManager.instance.receivedHelps.count
        }else{
            return HelpTogetherManager.instance.sendedHelps.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            return tableView.dequeueReusableCellWithIdentifier(HelpTogetherSquareCell.reuseId, forIndexPath: indexPath)
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier(HelpTogetherItemCell.reuseId, forIndexPath: indexPath) as! HelpTogetherItemCell
            let help = HelpTogetherManager.instance.getTypedHelps(indexPath.section, index: indexPath.row)
            cell.rootController = self
            cell.help = help
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 48
        }
        return UITableViewAutomaticDimension
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cellOfIndex = tableView.cellForRowAtIndexPath(indexPath)
        if indexPath.section == 0{
            HelpSquareController.showHelpSquare(self.navigationController!)
        }else {
            let cell = cellOfIndex as! HelpTogetherItemCell
            HelpDetailController.showHelpDetail(self.navigationController!, help: cell.help)
        }
        cellOfIndex?.selected = false
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 && HelpTogetherManager.instance.receivedHelps.count > 0 {
            return "RECEIVED_HELPS".HelpTogetherString
        }else if section == 2 && HelpTogetherManager.instance.sendedHelps.count > 0 {
            return "SENDED_HELPS".HelpTogetherString
        }else{
            return nil
        }
    }
}
