//
//  MNSMainController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh

private extension String{
    var mnsLocalizedString:String{
        return LocalizedString(self, tableName: "MNS", bundle: NSBundle.mainBundle())
    }
}

class MNSPostCell: UITableViewCell {
    static let resuseId = "MNSPostCell"
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var nickLabel: UILabel!
}

class MNSMainController: UIViewController {
    
    static let activityId = "1004"
    
    @IBOutlet weak var blockTipsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var myContentButton: UIBarButtonItem!{
        didSet{
            myContentButton.enabled = mainInfo != nil
        }
    }
    private var userService = ServiceContainer.getUserService()
    
    private var isOpenTime:Bool{
        let now = NSDate()
        return now.hourOfDate == 0 ? now.minuteOfDate > 1 : (now.hourOfDate > 0 && now.hourOfDate < 6)
    }
    
    private var users = [MNSUser](){
        didSet{
            tableView?.reloadData()
        }
    }
    
    private var timer:NSTimer!
    
    
    private var mainInfo:MNSMainInfo!{
        didSet{
            if mainInfo == nil{
                users.removeAll()
            }else if let u = mainInfo.acUsers{
                users.appendContentsOf(u)
            }
            myContentButton.enabled = mainInfo != nil
        }
    }
}

extension MNSMainController{
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        let tableViewMJHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(MNSMainController.onPullTableViewHeader(_:)))
        tableView.mj_header = tableViewMJHeader
        tableView.hidden = !isOpenTime
        blockTipsLabel.hidden = isOpenTime
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
    
    func onPullTableViewHeader(_:AnyObject?) {
        mainInfo = nil
        getMainInfoData()
    }
    
    @IBAction func onBackItemClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true
            , completion: nil)
    }
    
    func onTimeTick(_:AnyObject?) {
        tableView?.hidden = !isOpenTime
        blockTipsLabel?.hidden = isOpenTime
        if !isOpenTime {
            var timeString = "";
            let now = NSDate()
            var t = now.addDays(1)
            t = DateHelper.generateDate(t.yearOfDate, month: t.monthOfDate, day: t.dayOfDate, hour: 0, minute: 1, second: 0)
            let interval = Int(t.timeIntervalSince1970 - now.timeIntervalSince1970)
            if interval > 3600 {
                timeString = String(format: "H_HOUR_M_MIN_S_SEC".mnsLocalizedString, interval / 3600 , (interval % 3600) / 60, interval % 60)
            }else if interval > 60{
                timeString = String(format: "M_MIN_S_SEC".mnsLocalizedString, interval / 60, interval % 60)
            }else{
                timeString = String(format: "S_SEC".mnsLocalizedString,interval)
            }
            
            
            blockTipsLabel?.text = String(format: "OPEN_TIPS_FORMAT".mnsLocalizedString, timeString)
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
        UserProfileViewController.showUserProfileViewController(self, userId: user.userId, delegate: delegate)
    }
}


extension MNSMainController:UIEditTextPropertyViewControllerDelegate{
    
    @IBAction func onMyContentClicked(sender: AnyObject) {
        let property = UIEditTextPropertySet()
        property.illegalValueMessage = "ANNC_CONTENT_LIMIT".mnsLocalizedString
        property.isOneLineValue = false
        property.propertyIdentifier = "ANNC_CONTENT"
        property.propertyLabel = "MID_NIGHT_ANNC".mnsLocalizedString
        property.valueRegex = "?[6,140]"
        UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertySet: property, controllerTitle: "MY_MID_NIGHT_ACCN".mnsLocalizedString, delegate: self)
    }
    
    func editPropertySave(propertyIdentifier: String!, newValue: String!) {
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
    
    func getMainInfoData() {
        if isOpenTime == false || mainInfo != nil {
            return
        }
        let hud = self.showActivityHud()
        let req = GetMNSMainInfoRequest()
        req.location = ServiceContainer.getLocationService().hereShortString
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MNSMainInfo>) in
            hud.hideAnimated(true)
            if result.isSuccess{
                self.mainInfo = result.returnObject
            }
        }
    }
}
