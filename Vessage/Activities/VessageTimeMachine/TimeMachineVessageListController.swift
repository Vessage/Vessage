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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var chatterId:String!
    var timeSpan:Int64 = DateHelper.UnixTimeSpanTotalMilliseconds
    
    @IBOutlet var noVessagesTipsLabel:UILabel!
    
    var items = [[VessageTimeMachineItem]](){
        didSet{
            updateTipsLabel()
            tableView?.isScrollEnabled = items.count > 0
            tableView?.reloadData()
            if let item = items.first {
                if item.count > 0 {
                    let animated = items.count == 1
                    let path = IndexPath(row: item.count - 1,section:0)
                    DispatchQueue.main.afterMS(200, handler: { 
                        self.tableView.scrollToRow(at: path, at: .bottom, animated: animated)
                    })
                }
            }
        }
    }
    
    fileprivate func updateTipsLabel() {
        noVessagesTipsLabel.isHidden = items.count > 0
        titleLabel.isHidden = items.count == 0
    }
}

//MARK: Life Circle
extension TimeMachineVessageListController{
    override func viewDidLoad() {
        super.viewDidLoad()
        let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(TimeMachineVessageListController.onPullTableView(_:)))
        header?.lastUpdatedTimeLabel.isHidden = true
        header?.stateLabel.isHidden = true
        tableView.isScrollEnabled = false
        tableView.mj_header = header
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
    }
    fileprivate func firstLoadData(){
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstLoadData()
    }
    
    static func instanceOfController(_ chatterId:String,ts:Int64) -> TimeMachineVessageListController{
        let controller = instanceFromStoryBoard("VessageTimeMachine", identifier: "TimeMachineVessageListController") as! TimeMachineVessageListController
        controller.chatterId = chatterId
        controller.timeSpan = ts
        return controller
    }
}

//MARK: Actions
extension TimeMachineVessageListController{
    func onPullTableView(_ sender:AnyObject) {
        if let ts = items.first?.first?.vessage?.ts {
            let item = VessageTimeMachine.instance.getVessageBefore(chatterId, ts: ts)
            items.insert(item, at: 0)
        }
        tableView.mj_header.endRefreshing()
    }
}

//MARK:UITableViewDelegate
extension TimeMachineVessageListController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TimeMachineVessageCell.reuseId, for: indexPath) as! TimeMachineVessageCell
        let item = items[indexPath.section][indexPath.row]
        cell.headLine.text = item.getVessageTimeMachineTitle()
        cell.subline.text = item.getSubline()
        return cell
    }
}
