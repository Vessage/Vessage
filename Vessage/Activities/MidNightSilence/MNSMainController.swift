//
//  MNSMainController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import LTMorphingLabel

extension String{
    var mnsLocalizedString:String{
        return LocalizedString(self, tableName: "MNS", bundle: NSBundle.mainBundle())
    }
}

class MNSPostCell: UITableViewCell {
    static let resuseId = "MNSPostCell"
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var nickLabel: UILabel!
}

private let noChatConversationLeftTimeSpan:Int64 = 1 * 3600 * 1000

private let openTimeInterval:NSTimeInterval = 6 * 3600
private var todayOpenTime:NSDate{
    let now = NSDate()
    return DateHelper.generateDate(now.yearOfDate, month: now.monthOfDate, day: now.dayOfDate, hour: 0, minute: 1, second: 0)
}

private var todayCloseTime:NSDate{
    let openTime = todayOpenTime
    return openTime.addSeconds(openTimeInterval)
}

class MNSMainController: UIViewController {
    
    static let activityId = "1004"
    static let midNightAnncRegex = "^.{6,280}$"
    
    @IBOutlet weak var tipsLabel0: LTMorphingLabel!
    @IBOutlet weak var tipsLabel1: LTMorphingLabel!
    
    @IBOutlet weak var blockTipsLabel: LTMorphingLabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bcgImageView: UIImageView!
    @IBOutlet weak var myContentButton: UIBarButtonItem!{
        didSet{
            myContentButton.enabled = mainInfo != nil
        }
    }
    @IBOutlet weak var notificationButton: UIButton!
    
    private var userService = ServiceContainer.getUserService()
    
    private var isOpenTime:Bool{
        let now = NSDate()
        return todayOpenTime.timeIntervalSince1970 <= now.timeIntervalSince1970 && now.timeIntervalSince1970 < todayCloseTime.timeIntervalSince1970
    }
    private var timer:NSTimer!
    private var nextOpenTime:NSDate{
        let now = NSDate()
        let tdot = todayOpenTime
        if now.timeIntervalSince1970 < tdot.timeIntervalSince1970 {
            return todayOpenTime
        }
        return tdot.addDays(1)
    }
    
    static private let mnsNotificationName = "MNSNotify"
    
    private var notificationScheduled:Bool{
        if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications{
            for item in notifications {
                if let name = item.userInfo?["name"] as? String {
                    if name == MNSMainController.mnsNotificationName {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private var users = [MNSUser](){
        didSet{
            tableView?.reloadData()
        }
    }
    
    private var mainInfo:MNSMainInfo!{
        didSet{
            if mainInfo == nil{
                users.removeAll()
            }else if let u = mainInfo.acUsers{
                #if DEBUG
                if u.count == 0 {
                    if let conversation = (ServiceContainer.getConversationService().conversations.filter{$0.type == Conversation.typeSingleChat}).first{
                        let a = MNSUser()
                        a.annc = "f111"
                        a.aTs = DateHelper.UnixTimeSpanTotalMilliseconds
                        a.nick = "A"
                        a.userId = conversation.chatterId
                        users.appendContentsOf([a,a,a])
                    }
                }
                #endif
                users.appendContentsOf(u)
            }
            myContentButton.enabled = mainInfo != nil
        }
    }
}

extension MNSMainController{
    override func viewDidLoad() {
        super.viewDidLoad()
        tipsLabel0.morphingEffect = .Pixelate
        tipsLabel1.morphingEffect = .Pixelate
        blockTipsLabel.morphingEffect = .Evaporate
        notificationButton.hidden = true
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.hidden = true
        let tableViewMJHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(MNSMainController.onPullTableViewHeader(_:)))
        tableView.mj_header = tableViewMJHeader
        tableView.delegate = self
        tableView.dataSource = self
        refreshHiddenViews()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MNSMainController.onTimeTick(_:)), userInfo: nil, repeats: true)
        getMainInfoData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    func refreshHiddenViews() {
        let isOpen = isOpenTime
        tableView.hidden = !isOpen
        bcgImageView.hidden = !isOpen
        blockTipsLabel.hidden = isOpen
        notificationButton.setTitle((notificationScheduled ? "CLOSE_NOTIFY" : "OPEN_NOTIFY").mnsLocalizedString, forState: .Normal)
        if !String.isNullOrEmpty(blockTipsLabel.text) && tipsLabel0.hidden != isOpen {
            notificationButton.hidden = isOpen
            tipsLabel0.hidden = isOpen
            tipsLabel1.hidden = isOpen
            if tipsLabel0.hidden == false {
                let l0 = tipsLabel0.text
                let l1 = tipsLabel1.text
                tipsLabel0.text = nil
                tipsLabel1.text = nil
                tipsLabel0.text = l0
                tipsLabel1.text = l1
            }
        }
    }
    
    func onPullTableViewHeader(_:AnyObject?) {
        mainInfo = nil
        getMainInfoData()
    }
    
    @IBAction func onClickNotificationButton(sender: AnyObject) {
        if notificationScheduled {
            UIApplication.sharedApplication().scheduledLocalNotifications?.removeElement({ (item) -> Bool in
                if let name = item.userInfo?["name"] as? String {
                    if name == MNSMainController.mnsNotificationName {
                        return true
                    }
                }
                return false
            })
            MobClick.event("MNS_CloseNotify")
        }else{
            let notification = UILocalNotification()
            if #available(iOS 8.2, *) {
                notification.alertTitle = "NOTIFY_ALERT_TITLE".mnsLocalizedString
            } else {
                // Fallback on earlier versions
            }
            notification.alertBody = "NOTIFY_ALERT_BODY".mnsLocalizedString
            notification.applicationIconBadgeNumber = 1
            notification.userInfo = ["name":MNSMainController.mnsNotificationName]
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.fireDate = todayOpenTime
            notification.timeZone = NSTimeZone.defaultTimeZone()
            notification.repeatInterval = .Day
            MobClick.event("MNS_OpenNotify")
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
    
    @IBAction func onBackItemClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true
            , completion: nil)
    }
    
    @IBAction func onMyContentClicked(sender: AnyObject) {
        let property = UIEditTextPropertySet()
        property.illegalValueMessage = "ANNC_CONTENT_LIMIT".mnsLocalizedString
        property.isOneLineValue = false
        property.propertyValue = String.isNullOrWhiteSpace(mainInfo?.annc) ? "DEFAULT_ANNC".mnsLocalizedString : mainInfo.annc
        property.propertyIdentifier = "ANNC_CONTENT"
        property.propertyLabel = "EDIT_MID_NIGHT_ANNC_TITLE".mnsLocalizedString
        property.valueRegex = MNSMainController.midNightAnncRegex
        let controller = UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertySet: property, controllerTitle: "MY_MID_NIGHT_ACCN".mnsLocalizedString, delegate: self)
        controller.view.backgroundColor = UIColor.darkGrayColor()
        controller.propertyNameLabel.textColor = UIColor.lightGrayColor()
        controller.propertyValueTextField.textColor = UIColor.lightGrayColor()
        controller.propertyValueTextView.textColor = UIColor.lightGrayColor()
    }
    
    func onTimeTick(_:AnyObject?) {
        let now = NSDate()
        refreshHiddenViews()
        if isOpenTime {
            if users.count == 0 {
                blockTipsLabel?.hidden = false
                self.blockTipsLabel?.text = "NO_USER_TIPS".mnsLocalizedString
                if now.minuteOfDate % 3 == 0 && now.secondOfDate == 0{
                    self.getMainInfoData()
                }
            }
        }else{
            let t = nextOpenTime
            var timeString = "";
            let interval = Int(t.timeIntervalSince1970 - now.timeIntervalSince1970)
            if interval > 3600 {
                timeString = String(format: "H_HOUR_M_MIN_S_SEC".mnsLocalizedString, interval / 3600 , (interval % 3600) / 60, interval % 60)
            }else if interval > 60{
                timeString = String(format: "M_MIN_S_SEC".mnsLocalizedString, interval / 60, interval % 60)
            }else{
                timeString = String(format: "S_SEC".mnsLocalizedString,interval)
            }
            blockTipsLabel?.text = timeString
        }
    }
}

extension MNSMainController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return isOpenTime ? 1 : 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MNSPostCell.resuseId, forIndexPath: indexPath) as! MNSPostCell
        let user = users[indexPath.row]
        cell.contentLabel.text = String.isNullOrWhiteSpace(user.annc) ? "DEFAULT_ANNC".mnsLocalizedString : user.annc
        cell.nickLabel.text = userService.getUserNotedNameIfExists(user.userId) ?? user.nick
        return  cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        let user = users[indexPath.row]
        let delegate = UserProfileViewControllerDelegateOpenConversation()
        delegate.beforeRemoveTimeSpan = noChatConversationLeftTimeSpan
        delegate.createActivityId = MNSMainController.activityId
        UserProfileViewController.showUserProfileViewController(self, userId: user.userId, delegate: delegate){ controller in
            controller.accountIdHidden = true
        }
    }
}


extension MNSMainController:UIEditTextPropertyViewControllerDelegate{
    
    func editPropertySave(sender: UIEditTextPropertyViewController, propertyIdentifier: String!, newValue: String!, userInfo: [String : AnyObject?]?) {
        if propertyIdentifier == "ANNC_CONTENT" {
            if !String.isNullOrWhiteSpace(newValue) {
                let hud = self.showActivityHud()
                let req = UpdateMNSAnnounceRequest()
                req.midNightAnnounce = newValue
                BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MNSMainInfo>) in
                    hud.hideAnimated(true)
                    if result.isSuccess{
                        self.mainInfo.annc = newValue
                        self.playCheckMark()
                    }else{
                        self.playCrossMark()
                    }
                }
            }
        }
    }
    
    private func getMainInfoData() {
        if isOpenTime == false || mainInfo != nil {
            return
        }
        let hud = self.showActivityHud()
        let req = GetMNSMainInfoRequest()
        req.location = ServiceContainer.getLocationService().hereShortString
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MNSMainInfo>) in
            hud.hideAnimated(true)
            self.tableView.mj_header.endRefreshing()
            if result.isSuccess{
                self.mainInfo = result.returnObject
                if self.mainInfo.newer{
                    self.showNewerAlert()
                }
            }else{
                self.playCrossMark("GET_MAIN_INFO_ERROR".mnsLocalizedString, async:false, completionHandler: nil)
            }
        }
    }
    
    private func showNewerAlert(){
        let ac = UIAlertAction(title: "POST_ANNC".mnsLocalizedString, style: .Default) { (ac) in
            self.onMyContentClicked(self.myContentButton)
        }
        self.showAlert("MNS".mnsLocalizedString, msg: "MNS_NEWER_MESSAGE".mnsLocalizedString, actions: [ac])
    }
}
