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
        return LocalizedString(self, tableName: "MNS", bundle: Bundle.main)
    }
}

class MNSPostCell: UITableViewCell {
    static let resuseId = "MNSPostCell"
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var nickLabel: UILabel!
}

private let noChatConversationLeftTimeSpan:Int64 = 1 * 3600 * 1000

private let openTimeInterval:TimeInterval = 7.5 * 3600
private var todayOpenTime:Date{
    let now = Date()
    return DateHelper.generateDate(now.yearOfDate, month: now.monthOfDate, day: now.dayOfDate, hour: 22, minute: 30, second: 0)
}

private var todayCloseTime:Date{
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
            myContentButton.isEnabled = mainInfo != nil
        }
    }
    @IBOutlet weak var notificationButton: UIButton!
    
    fileprivate var userService = ServiceContainer.getUserService()
    
    fileprivate var isOpenTime:Bool{
        let now = Date()
        let previousOpenTime = todayOpenTime.addDays(-1)
        let previousEndTime = previousOpenTime.addSeconds(openTimeInterval)
        if previousOpenTime.timeIntervalSince1970 <= now.timeIntervalSince1970 && now.timeIntervalSince1970 < previousEndTime.timeIntervalSince1970 {
            return true
        }
        return todayOpenTime.timeIntervalSince1970 <= now.timeIntervalSince1970 && now.timeIntervalSince1970 < todayCloseTime.timeIntervalSince1970
    }
    fileprivate var timer:Timer!
    fileprivate var nextOpenTime:Date{
        let now = Date()
        let tdot = todayOpenTime
        if now.timeIntervalSince1970 < tdot.timeIntervalSince1970 {
            return todayOpenTime
        }
        return tdot.addDays(1)
    }
    
    static fileprivate let mnsNotificationName = "MNSNotify"
    
    fileprivate var notificationScheduled:Bool{
        if let notifications = UIApplication.shared.scheduledLocalNotifications{
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
    
    fileprivate var users = [MNSUser](){
        didSet{
            tableView?.reloadData()
        }
    }
    
    fileprivate var mainInfo:MNSMainInfo!{
        didSet{
            users.removeAll()
            if let u = mainInfo?.acUsers{
                #if DEBUG
                if u.count == 0 {
                    if let conversation = (ServiceContainer.getConversationService().conversations.filter{$0.type == Conversation.typeSingleChat}).first{
                        let a = MNSUser()
                        a.annc = "f111"
                        a.aTs = DateHelper.UnixTimeSpanTotalMilliseconds
                        a.nick = "A"
                        a.userId = conversation.chatterId
                        users.append(contentsOf: [a,a,a])
                    }
                }
                #endif
                users.append(contentsOf: u)
            }
            myContentButton.isEnabled = mainInfo != nil
        }
    }
}

extension MNSMainController{
    override func viewDidLoad() {
        super.viewDidLoad()
        tipsLabel0.morphingEffect = .pixelate
        tipsLabel1.morphingEffect = .pixelate
        blockTipsLabel.morphingEffect = .evaporate
        notificationButton.isHidden = true
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.isHidden = true
        let tableViewMJHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(MNSMainController.onPullTableViewHeader(_:)))
        tableView.mj_header = tableViewMJHeader
        tableView.delegate = self
        tableView.dataSource = self
        refreshHiddenViews()
        ServiceContainer.getActivityService().clearActivityAllBadge(MNSMainController.activityId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MNSMainController.onTimeTick(_:)), userInfo: nil, repeats: true)
        getMainInfoData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    func refreshHiddenViews() {
        let isOpen = isOpenTime
        tableView.isHidden = !isOpen
        bcgImageView.isHidden = !isOpen
        blockTipsLabel.isHidden = isOpen
        notificationButton.setTitle((notificationScheduled ? "CLOSE_NOTIFY" : "OPEN_NOTIFY").mnsLocalizedString, for: UIControlState())
        if !String.isNullOrEmpty(blockTipsLabel.text) && tipsLabel0.isHidden != isOpen {
            notificationButton.isHidden = isOpen
            tipsLabel0.isHidden = isOpen
            tipsLabel1.isHidden = isOpen
            if tipsLabel0.isHidden == false {
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
    
    @IBAction func onClickNotificationButton(_ sender: AnyObject) {
        if notificationScheduled {
            UIApplication.shared.scheduledLocalNotifications?.removeElement({ (item) -> Bool in
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
            notification.timeZone = TimeZone.current
            notification.repeatInterval = .day
            MobClick.event("MNS_OpenNotify")
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
    
    @IBAction func onBackItemClicked(_ sender: AnyObject) {
        self.dismiss(animated: true
            , completion: nil)
    }
    
    @IBAction func onMyContentClicked(_ sender: AnyObject) {
        let property = UIEditTextPropertySet()
        property.illegalValueMessage = "ANNC_CONTENT_LIMIT".mnsLocalizedString
        property.isOneLineValue = false
        property.valueNullable = true
        property.propertyValue = String.isNullOrWhiteSpace(mainInfo?.annc) ? "DEFAULT_ANNC".mnsLocalizedString : mainInfo.annc
        property.propertyIdentifier = "ANNC_CONTENT"
        property.valueTextViewHolder = "ANNC_HOLDER".mnsLocalizedString
        property.propertyLabel = "EDIT_MID_NIGHT_ANNC_TITLE".mnsLocalizedString
        property.valueRegex = MNSMainController.midNightAnncRegex
        let controller = UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertySet: property, controllerTitle: "UPDATE_MY_MID_NIGHT_ANNC".mnsLocalizedString, delegate: self)
        controller.view.backgroundColor = UIColor.darkGray
        controller.propertyValueTextField.textColor = UIColor.lightGray
        controller.propertyValueTextView.textColor = UIColor.lightGray
    }
    
    func onTimeTick(_:AnyObject?) {
        let now = Date()
        refreshHiddenViews()
        if isOpenTime {
            if users.count == 0 {
                blockTipsLabel?.isHidden = false
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return isOpenTime ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MNSPostCell.resuseId, for: indexPath) as! MNSPostCell
        let user = users[indexPath.row]
        cell.contentLabel.text = String.isNullOrWhiteSpace(user.annc) ? "DEFAULT_ANNC".mnsLocalizedString : user.annc
        cell.nickLabel.text = userService.getUserNotedNameIfExists(user.userId) ?? user.nick
        return  cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        let user = users[indexPath.row]
        let delegate = UserProfileViewControllerDelegateOpenConversation()
        delegate.beforeRemoveTimeSpan = noChatConversationLeftTimeSpan
        delegate.createActivityId = MNSMainController.activityId
        delegate.initMessage = ["input_text":"MNS_HELLO".mnsLocalizedString as AnyObject]
        UserProfileViewController.showUserProfileViewController(self, userId: user.userId, delegate: delegate){ controller in
            controller.accountIdHidden = true
            controller.snsButtonEnabled = false
        }
    }
}


extension MNSMainController:UIEditTextPropertyViewControllerDelegate{
    
    func editPropertySave(_ sender: UIEditTextPropertyViewController, propertyIdentifier: String!, newValue: String!, userInfo: [String : AnyObject?]?) {
        if propertyIdentifier == "ANNC_CONTENT" {
            let hud = self.showActivityHud()
            let req = UpdateMNSAnnounceRequest()
            req.midNightAnnounce = newValue
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MNSMainInfo>) in
                hud.hide(animated: true)
                if result.isSuccess{
                    self.mainInfo.annc = newValue
                    self.playCheckMark()
                }else{
                    self.playCrossMark()
                }
            }
        }
    }
    
    fileprivate func getMainInfoData() {
        if isOpenTime == false || mainInfo != nil {
            return
        }
        let hud = self.showActivityHud()
        let req = GetMNSMainInfoRequest()
        req.location = ServiceContainer.getLocationService().hereShortString
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MNSMainInfo>) in
            hud.hide(animated: true)
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
    
    fileprivate func showNewerAlert(){
        let ac = UIAlertAction(title: "POST_ANNC".mnsLocalizedString, style: .default) { (ac) in
            self.onMyContentClicked(self.myContentButton)
        }
        self.showAlert("MNS".mnsLocalizedString, msg: "MNS_NEWER_MESSAGE".mnsLocalizedString, actions: [ac])
    }
}
