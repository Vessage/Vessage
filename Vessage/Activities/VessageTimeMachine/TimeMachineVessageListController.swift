//
//  TimeMachineVessageListController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh

//MARK:TimeMachineVessageCell
class TimeMachineVessageCell: UITableViewCell {
    static let reuseId = "TimeMachineVessageCell"
    @IBOutlet weak var headLine: UILabel!
    @IBOutlet weak var subline: UILabel!
}

//MARK:TimeMachineVessageListController
class TimeMachineVessageListController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var chatterId:String!
    var timeSpan:Int64 = DateHelper.UnixTimeSpanTotalMilliseconds
    
    @IBOutlet var noVessagesTipsLabel:UILabel!
    
    var items = [[VessageTimeMachineItem]](){
        didSet{
            updateTipsLabel()
            tableView?.scrollEnabled = items.count > 0
            tableView?.reloadData()
        }
    }
    
    private func updateTipsLabel() {
        noVessagesTipsLabel.hidden = items.count > 0
    }
}

//MARK: Life Circle
extension TimeMachineVessageListController{
    override func viewDidLoad() {
        super.viewDidLoad()
        let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(TimeMachineVessageListController.onPullTableView(_:)))
        header.lastUpdatedTimeLabel.hidden = true
        header.stateLabel.hidden = true
        tableView.scrollEnabled = false
        tableView.mj_header = header
        tableView.tableFooterView = UIView()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if items.count == 0 {
            tableView.delegate = self
            tableView.dataSource = self
            let item = VessageTimeMachine.instance.getVessageBefore(chatterId, ts: timeSpan)
            if item.count > 0 {
                items.append(item)
                updateTipsLabel()
            }else{
                updateTipsLabel()
            }
        }
    }
    
    static func instanceOfController(chatterId:String,ts:Int64) -> TimeMachineVessageListController{
        let controller = instanceFromStoryBoard("VessageTimeMachine", identifier: "TimeMachineVessageListController") as! TimeMachineVessageListController
        controller.chatterId = chatterId
        controller.timeSpan = ts
        return controller
    }
}

//MARK: Actions
extension TimeMachineVessageListController{
    func onPullTableView(sender:AnyObject) {
        if let ts = items.first?.first?.vessage?.ts {
            let item = VessageTimeMachine.instance.getVessageBefore(chatterId, ts: ts)
            if item.count > 0 {
                items.insert(item, atIndex: 0)
                tableView.mj_header.endRefreshing()
            }else{
                tableView.mj_header.endRefreshing()
                tableView.mj_header.state = .NoMoreData
            }
        }else{
            tableView.mj_header.endRefreshing()
        }
    }
}

//MARK:UITableViewDelegate
extension TimeMachineVessageListController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TimeMachineVessageCell.reuseId, forIndexPath: indexPath) as! TimeMachineVessageCell
        let item = items[indexPath.section][indexPath.row]
        cell.headLine.text = item.getVessageTimeMachineTitle()
        cell.subline.text = item.getSubline()
        return cell
    }
}
