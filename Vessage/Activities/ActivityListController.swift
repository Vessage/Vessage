//
//  ActivityListController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class ActivityListCell: UITableViewCell {
    static let reuseId = "ActivityListCell"
    private weak var rootController:ActivityListController!
    var activityInfo:ActivityInfo!{
        didSet{
            badgeValue = 0
            nameLabel.text = activityInfo.cellTitle
            iconImageView.image = UIImage(named: activityInfo.cellIconName) ?? UIImage(named: "favorite")
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
            miniBadgeView.layoutIfNeeded()
            miniBadgeView.layer.cornerRadius = miniBadgeView.frame.height / 2
            miniBadgeView.hidden = !showMiniBadge
        }
    }
    
    var badgeValue:Int = 0 {
        didSet{
            setBadgeLabelValue(badgeLabel,value: badgeValue)
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
    
    private var activities = [[ActivityInfo]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dict = [NSForegroundColorAttributeName:UIColor.themeColor]
        self.navigationController?.navigationBar.titleTextAttributes = dict
        self.navigationItem.title = "EXTRA_SERVICE_DISPLAY_NAME".localizedString()
        self.activityService = ServiceContainer.getActivityService()
        self.tableView.tableFooterView = UIView()
        self.tableView.scrollEnabled = false
        self.tableView.allowsSelection = true
        self.tableView.allowsMultipleSelection = false
        self.activityService.addObserver(self, selector: #selector(ActivityListController.onActivityBadgeUpdated(_:)), name: ActivityService.onEnabledActivityBadgeUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(ActivityListController.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        activities.appendContentsOf(activityService.getEnabledActivities())
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setNavigationBadges()
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    private func setNavigationBadges() {
        let appService = ServiceContainer.getAppService()
        if appService.inviteBadge {
            navigationItem.rightBarButtonItem?.showMiniBadge()
        }else{
            navigationItem.rightBarButtonItem?.hideMiniBadge()
        }
    }
    
    @IBAction func tellFriends(sender: AnyObject) {
        ServiceContainer.getAppService().inviteBadge = false
        setNavigationBadges()
        ShareHelper.instance.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString(),copyLink: true)
    }
    
    func onServicesWillLogout(a:NSNotification) {
        ServiceContainer.instance.removeObserver(self)
        self.activityService.removeObserver(self)
    }

    func onActivityBadgeUpdated(a:NSNotification){
        for cell in self.tableView.visibleCells{
            if let c = cell as? ActivityListCell{
                if let id = a.userInfo?[UpdatedActivityIdValue] as? String{
                    if id == c.activityInfo.activityId{
                        c.refreshCellBadge()
                    }
                }
            }
        }
    }
    
    //MARK: Table View Delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return activities.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ActivityInfoList.count > 1 {
            tableView.separatorStyle = .SingleLine
        }else{
            tableView.separatorStyle = .None
        }
        return activities[section].count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 11
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        openActivity(indexPath)
    }
    
    private func openActivity(indexPath:NSIndexPath){
        let activityInfo = activities[indexPath.section][indexPath.row]
        let controller = UIViewController.instanceFromStoryBoard(activityInfo.storyBoardName, identifier: activityInfo.controllerIdentifier)
        if(activityInfo.isPushController){
            controller.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(controller, animated: true)
        }else{
            self.presentViewController(controller, animated: true, completion: nil)
        }
        if activityInfo.autoClearBadge {
            ServiceContainer.getActivityService().clearActivityAllBadge(activityInfo.activityId)
        }
        MobClick.event("Vege_OpenActivity_\(activityInfo.activityId)")
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ActivityListCell.reuseId, forIndexPath: indexPath) as! ActivityListCell
        cell.rootController = self
        cell.activityInfo = activities[indexPath.section][indexPath.row]
        cell.setSeparatorFullWidth()
        return cell
    }
    
}
