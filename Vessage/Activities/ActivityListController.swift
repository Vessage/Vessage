//
//  ActivityListController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class ActivityListCell: UITableViewCell {
    static let reuseId = "ActivityListCell"
    fileprivate weak var rootController:ActivityListController!
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
            badgeLabel.isHidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
        }
    }
    
    @IBOutlet weak var miniBadgeView: UIView!{
        didSet{
            miniBadgeView.clipsToBounds = true
            miniBadgeView.layoutIfNeeded()
            miniBadgeView.layer.cornerRadius = miniBadgeView.frame.height / 2
            miniBadgeView.isHidden = !showMiniBadge
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
                miniBadgeView.isHidden = !showMiniBadge
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
    
    fileprivate(set) var activityService:ActivityService!
    
    fileprivate var activities = [[ActivityInfo]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dict = [NSForegroundColorAttributeName:UIColor.themeColor]
        self.navigationController?.navigationBar.titleTextAttributes = dict
        self.navigationItem.title = "EXTRA_SERVICE_DISPLAY_NAME".localizedString()
        self.activityService = ServiceContainer.getActivityService()
        self.tableView.tableFooterView = UIView()
        self.tableView.isScrollEnabled = false
        self.tableView.allowsSelection = true
        self.tableView.allowsMultipleSelection = false
        self.activityService.addObserver(self, selector: #selector(ActivityListController.onActivityBadgeUpdated(_:)), name: ActivityService.onEnabledActivityBadgeUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(ActivityListController.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        activities.append(contentsOf: activityService.getEnabledActivities())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNavigationBadges()
        MainTabBarController.instance?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MainTabBarController.instance?.tabBar.isHidden = true
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    fileprivate func setNavigationBadges() {
        let appService = ServiceContainer.getAppService()
        if appService.inviteBadge {
            navigationItem.rightBarButtonItem?.showMiniBadge()
        }else{
            navigationItem.rightBarButtonItem?.hideMiniBadge()
        }
    }
    
    @IBAction func tellFriends(_ sender: AnyObject) {
        ServiceContainer.getAppService().inviteBadge = false
        setNavigationBadges()
        ShareHelper.instance.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString(),copyLink: true)
    }
    
    func onServicesWillLogout(_ a:Notification) {
        ServiceContainer.instance.removeObserver(self)
        self.activityService.removeObserver(self)
    }

    func onActivityBadgeUpdated(_ a:Notification){
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return activities.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ActivityInfoList.count > 1 {
            tableView.separatorStyle = .singleLine
        }else{
            tableView.separatorStyle = .none
        }
        return activities[section].count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 11
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openActivity(indexPath)
    }
    
    fileprivate func openActivity(_ indexPath:IndexPath){
        let activityInfo = activities[indexPath.section][indexPath.row]
        let controller = UIViewController.instanceFromStoryBoard(activityInfo.storyBoardName, identifier: activityInfo.controllerIdentifier)
        if(activityInfo.isPushController){
            controller.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(controller, animated: true)
        }else{
            self.present(controller, animated: true, completion: nil)
        }
        if activityInfo.autoClearBadge {
            ServiceContainer.getActivityService().clearActivityAllBadge(activityInfo.activityId)
        }
        MobClick.event("Vege_OpenActivity_\(activityInfo.activityId!)")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActivityListCell.reuseId, for: indexPath) as! ActivityListCell
        cell.rootController = self
        cell.activityInfo = activities[indexPath.section][indexPath.row]
        cell.setSeparatorFullWidth()
        return cell
    }
    
}
