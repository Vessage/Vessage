//
//  MYQMainController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import LTMorphingLabel

extension String{
    var MYQLocalizedString:String{
        return LocalizedString(self, tableName: "MYQ", bundle: NSBundle.mainBundle())
    }
}

class MYQPostCell: UITableViewCell {
    static let resuseId = "MYQPostCell"
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var nickLabel: UILabel!
}

private let noChatConversationLeftTimeSpan:Int64 = 1 * 3600 * 1000

class MYQMainController: UIViewController {
    
    static let activityId = "1006"
    static let questionPattern = "^.{6,160}[?？❓]$"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myContentButton: UIBarButtonItem!{
        didSet{
            myContentButton.enabled = mainInfo != nil
        }
    }
    
    private var userService = ServiceContainer.getUserService()
    
    static private let MYQNotificationName = "MYQNotify"
    
    private var userQuestions = [MYQInfo](){
        didSet{
            tableView?.reloadData()
        }
    }
    
    private var mainInfo:MYQMainInfo!{
        didSet{
            userQuestions.removeAll()
            if let u = mainInfo?.usrQues{
                userQuestions.appendContentsOf(u)
            }
            myContentButton.enabled = mainInfo != nil
        }
    }
}

extension MYQMainController{
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.hidden = true
        let tableViewMJHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(MYQMainController.onPullTableViewHeader(_:)))
        tableView.mj_header = tableViewMJHeader
        tableView.delegate = self
        tableView.dataSource = self
        ServiceContainer.getActivityService().clearActivityAllBadge(MYQMainController.activityId)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getMainInfoData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func onPullTableViewHeader(_:AnyObject?) {
        mainInfo = nil
        getMainInfoData()
    }
    
    @IBAction func onBackItemClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true
            , completion: nil)
    }
    
    @IBAction func onMyContentClicked(sender: AnyObject) {
        let property = UIEditTextPropertySet()
        property.illegalValueMessage = "QUES_CONTENT_LIMIT".MYQLocalizedString
        property.isOneLineValue = false
        property.propertyValue = mainInfo.ques
        property.valueNullable = true
        property.propertyIdentifier = "QUES_CONTENT"
        property.valueTextViewHolder = "MY_QUESTION_HOLDER".MYQLocalizedString
        property.propertyLabel = "EDIT_MY_QUESTION_TITLE".MYQLocalizedString
        property.valueRegex = MYQMainController.questionPattern
        let controller = UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertySet: property, controllerTitle: "UPDATE_MY_QUESTION".MYQLocalizedString, delegate: self)
        controller.propertyValueTextView?.placeHolderLabel?.numberOfLines = 0
    }
}

extension MYQMainController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userQuestions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MYQPostCell.resuseId, forIndexPath: indexPath) as! MYQPostCell
        let ques = userQuestions[indexPath.row]
        cell.contentLabel.text = ques.ques
        cell.nickLabel.text = userService.getUserNotedNameIfExists(ques.userId) ?? ques.nick
        return  cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        let user = userQuestions[indexPath.row]
        if user.userId == UserSetting.userId {
            onMyContentClicked(self.myContentButton)
            return
        }
        let delegate = UserProfileViewControllerDelegateOpenConversation()
        delegate.beforeRemoveTimeSpan = noChatConversationLeftTimeSpan
        delegate.initMessage = ["input_text":"MYQ_HELLO".MYQLocalizedString]
        delegate.createActivityId = MYQMainController.activityId
        delegate.operateTitle = "LET_ME_ANSWER".MYQLocalizedString
        UserProfileViewController.showUserProfileViewController(self, userId: user.userId, delegate: delegate){ controller in
            controller.accountIdHidden = true
            controller.snsButtonEnabled = false
        }
    }
}


extension MYQMainController:UIEditTextPropertyViewControllerDelegate{
    
    func editPropertySave(sender: UIEditTextPropertyViewController, propertyIdentifier: String!, newValue: String!, userInfo: [String : AnyObject?]?) {
        if propertyIdentifier == "QUES_CONTENT" {
            let hud = self.showActivityHud()
            let req = UpdateMYQuestionRequest()
            req.question = newValue
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MYQMainInfo>) in
                hud.hideAnimated(true)
                if result.isSuccess{
                    let myUserId = UserSetting.userId!
                    self.mainInfo.usrQues?.removeElement{myUserId == $0.userId}
                    self.mainInfo.ques = newValue
                    if !String.isNullOrEmpty(newValue){
                        let myQuestion = MYQInfo()
                        myQuestion.aTs = DateHelper.UnixTimeSpanTotalMilliseconds
                        myQuestion.avatar = self.userService.myProfile.avatar
                        myQuestion.nick = "ME".localizedString()
                        myQuestion.ques = newValue
                        myQuestion.userId = UserSetting.userId
                        if self.mainInfo.usrQues == nil{
                            self.mainInfo.usrQues = []
                        }
                        self.mainInfo.usrQues.insert(myQuestion, atIndex: 0)
                    }
                    self.playCheckMark()
                }else{
                    self.playCrossMark()
                }
            }
        }
    }
    
    private func getMainInfoData() {
        let hud = self.showActivityHud()
        let req = GetMYQMainInfoRequest()
        req.location = ServiceContainer.getLocationService().hereShortString
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MYQMainInfo>) in
            hud.hideAnimated(true)
            self.tableView.mj_header.endRefreshing()
            if result.isSuccess{
                self.mainInfo = result.returnObject
                if self.mainInfo.newer{
                    self.showNewerAlert()
                }
            }else{
                self.playCrossMark("GET_MAIN_INFO_ERROR".MYQLocalizedString, async:false, completionHandler: nil)
            }
        }
    }
    
    private func showNewerAlert(){
        let ac = UIAlertAction(title: "POST_QUESTION".MYQLocalizedString, style: .Default) { (ac) in
            self.onMyContentClicked(self.myContentButton)
        }
        self.showAlert("MYQ".MYQLocalizedString, msg: "MYQ_NEWER_MESSAGE".MYQLocalizedString, actions: [ac])
    }
}
