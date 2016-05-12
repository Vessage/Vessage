//
//  ActivityListController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class ActivityListCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.hidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
        }
    }
    var badgeValue:Int = 0 {
        didSet{
            if badgeLabel != nil{
                if badgeValue == 0{
                    badgeLabel.hidden = true
                }else{
                    badgeLabel.text = "\(badgeValue)"
                }
            }
        }
    }
    
    static let reuseId = "ActivityListCell"
    private var rootController:ActivityListController!
    var activityInfo:ActivityInfo!{
        didSet{
            badgeValue = 99
            nameLabel.text = activityInfo.cellTitle
            iconImageView.image = UIImage(named: activityInfo.cellIconName)
            iconImageView.clipsToBounds = true
            iconImageView.layer.cornerRadius = 3
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityListCell.onClickCell(_:))))
    }
    
    func onClickCell(gesture:UITapGestureRecognizer){
        let controller = UIViewController.instanceFromStoryBoard(activityInfo.storyBoardName, identifier: activityInfo.controllerIdentifier)
        if(activityInfo.isPushController){
            rootController.navigationController?.pushViewController(controller, animated: true)
        }else{
            rootController.presentViewController(controller, animated: true, completion: nil)
        }
    }
}

//MARK:ActivityListController
class ActivityListController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.tableView.scrollEnabled = false
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ActivityInfoList.count > 1 {
            tableView.separatorStyle = .SingleLine
        }else{
            tableView.separatorStyle = .None
        }
        return ActivityInfoList.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 18
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ActivityListCell.reuseId, forIndexPath: indexPath) as! ActivityListCell
        cell.rootController = self
        cell.activityInfo = ActivityInfoList[indexPath.row]
        return cell
    }
    
}
