//
//  PaperAirplaneBoxViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/13.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import UIKit

class PaperAirplaneBoxCell: UITableViewCell {
    static let reuseId = "PaperAirplaneBoxCell"
    
    @IBOutlet weak var sublineLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var extraLabel: UILabel!
}

class PaperAirplaneBoxViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var tipsLabel:FlashTipsLabel = {
        return FlashTipsLabel()
    }()
    
    var planes:[[PaperAirplane]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if planes == nil || planes.count == 0{
            planes = [[PaperAirplane]]()
            refreshMyPlanes()
        }
    }
    
    private func refreshMyPlanes() {
        
        let req = GetMyPaperAirplanesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[PaperAirplane]>) in
            
            if let arr = result.returnObject{
                if arr.count > 0{
                    self.planes.append(arr)
                    self.tableView.reloadData()
                    return
                }
            }
            self.tipsLabel.flashTips(self.view, msg: "NO_PLANES_IN_BOX".PaperAirplaneString, center: nil)
        }
    }

}

extension PaperAirplaneBoxViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return planes == nil ? 0 : planes.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return planes[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PaperAirplaneBoxCell.reuseId, forIndexPath: indexPath) as! PaperAirplaneBoxCell
        let plane = planes[indexPath.section][indexPath.row]
        let msg = plane.msgs.first!
        cell.titleLabel.text = String(format: "X_POST_A_PLANE".PaperAirplaneString, msg.nick)
        cell.sublineLabel.text = msg.msg
        cell.extraLabel?.hidden = plane.msgs.count == 0
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath){
            cell.selected = false
        }
        let plane = planes[indexPath.section][indexPath.row]
        PaperAirplaneDetailViewController.showDetailViewController(self.navigationController!, plane: plane, delegate: self)
    }
}

extension PaperAirplaneBoxViewController:PaperAirplaneDetailViewControllerDelegate{
    func paperAirplaneDetailViewController(sender: PaperAirplaneDetailViewController, plane: PaperAirplane, isFlyOut: Bool) {
        
    }
}
