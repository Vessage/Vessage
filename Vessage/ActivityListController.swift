//
//  ActivityListController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class ActivityListCell: UITableViewCell {
    static let reuseId = "ActivityListCell"
    private var rootController:ActivityListController!
    var activityInfo:ActivityInfo!{
        didSet{
            badgeValue = 99
            nameLabel.text = activityInfo.cellTitle
            iconImageView.image = UIImage(named: activityInfo.cellIconName)
            refreshCellBadge()
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!{
        didSet{
            iconImageView.clipsToBounds = true
            iconImageView.layer.cornerRadius = 3
        }
    }
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.hidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
        }
    }
    
    @IBOutlet weak var miniBadgeView: UIView!{
        didSet{
            miniBadgeView.clipsToBounds = true
            miniBadgeView.layer.cornerRadius = 3
            miniBadgeView.hidden = !showMiniBadge
        }
    }
    
    var badgeValue:Int = 0 {
        didSet{
            if badgeLabel != nil{
                if badgeValue == 0{
                    badgeLabel.hidden = true
                }else{
                    badgeLabel.text = "\(badgeValue)"
                    badgeLabel.hidden = false
                    badgeLabel.animationMaxToMin()
                }
            }
        }
    }
    
    var showMiniBadge = false{
        didSet{
            if miniBadgeView != nil{
                miniBadgeView.hidden = !showMiniBadge
            }
        }
    }
    
    func refreshCellBadge() {
        badgeValue = rootController.activityService.getActivityBadge(activityInfo.activityId)
        showMiniBadge = rootController.activityService.isActivityShowMiniBadge(activityInfo.activityId)
    }
}

//MARK:ActivityListController
class ActivityListController: UITableViewController {
    
    private(set) var activityService:ActivityService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityService = ServiceContainer.getActivityService()
        self.tableView.tableFooterView = UIView()
        self.tableView.scrollEnabled = false
        self.tableView.allowsSelection = true
        self.tableView.allowsMultipleSelection = false
        self.activityService.addObserver(self, selector: #selector(MainTabBarController.onActivitiesBadgeUpdated(_:)), name: ActivityService.onEnabledActivitiesBadgeUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(MainTabBarController.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
    }
    
    func onServicesWillLogout(a:NSNotification) {
        ServiceContainer.instance.removeObserver(self)
        self.activityService.removeObserver(self)
    }

    func onActivitiesBadgeUpdated(a:NSNotification){
        for cell in self.tableView.visibleCells{
            if let c = cell as? ActivityListCell{
                c.refreshCellBadge()
            }
        }
    }
    
    //MARK: Table View Delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ActivityInfoList.count > 1 {
            tableView.separatorStyle = .SingleLine
        }else{
            tableView.separatorStyle = .None
        }
        return activityService.getEnabledActivities().count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 18
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        openActivity(indexPath)
    }
    
    private func openActivity(indexPath:NSIndexPath){
        let activityInfo = activityService.getEnabledActivities()[indexPath.row]
        let controller = UIViewController.instanceFromStoryBoard(activityInfo.storyBoardName, identifier: activityInfo.controllerIdentifier)
        if(activityInfo.isPushController){
            self.navigationController?.pushViewController(controller, animated: true)
        }else{
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ActivityListCell.reuseId, forIndexPath: indexPath) as! ActivityListCell
        cell.rootController = self
        cell.activityInfo = activityService.getEnabledActivities()[indexPath.row]
        return cell
    }
    
}
