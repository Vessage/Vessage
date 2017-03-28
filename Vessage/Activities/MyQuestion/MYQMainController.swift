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
        return LocalizedString(self, tableName: "MYQ", bundle: Bundle.main)
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
            myContentButton.isEnabled = mainInfo != nil
        }
    }
    
    fileprivate var userService = ServiceContainer.getUserService()
    
    static fileprivate let MYQNotificationName = "MYQNotify"
    
    fileprivate var userQuestions = [MYQInfo](){
        didSet{
            tableView?.reloadData()
        }
    }
    
    fileprivate var mainInfo:MYQMainInfo!{
        didSet{
            userQuestions.removeAll()
            if let u = mainInfo?.usrQues{
                userQuestions.append(contentsOf: u)
            }
            myContentButton.isEnabled = mainInfo != nil
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
        tableView.tableFooterView?.isHidden = true
        let tableViewMJHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(MYQMainController.onPullTableViewHeader(_:)))
        tableView.mj_header = tableViewMJHeader
        tableView.delegate = self
        tableView.dataSource = self
        ServiceContainer.getActivityService().clearActivityAllBadge(MYQMainController.activityId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMainInfoData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func onPullTableViewHeader(_:AnyObject?) {
        mainInfo = nil
        getMainInfoData()
    }
    
    @IBAction func onBackItemClicked(_ sender: AnyObject) {
        self.dismiss(animated: true
            , completion: nil)
    }
    
    @IBAction func onMyContentClicked(_ sender: AnyObject) {
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userQuestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MYQPostCell.resuseId, for: indexPath) as! MYQPostCell
        let ques = userQuestions[indexPath.row]
        cell.contentLabel.text = ques.ques
        cell.nickLabel.text = userService.getUserNotedNameIfExists(ques.userId) ?? ques.nick
        return  cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        let user = userQuestions[indexPath.row]
        if user.userId == UserSetting.userId {
            onMyContentClicked(self.myContentButton)
            return
        }
        let delegate = UserProfileViewControllerDelegateOpenConversation()
        delegate.beforeRemoveTimeSpan = noChatConversationLeftTimeSpan
        delegate.initMessage = ["input_text":"MYQ_HELLO".MYQLocalizedString as AnyObject]
        delegate.createActivityId = MYQMainController.activityId
        delegate.operateTitle = "LET_ME_ANSWER".MYQLocalizedString
        UserProfileViewController.showUserProfileViewController(self, userId: user.userId, delegate: delegate){ controller in
            controller.accountIdHidden = true
            controller.snsButtonEnabled = false
        }
    }
}


extension MYQMainController:UIEditTextPropertyViewControllerDelegate{
    
    func editPropertySave(_ sender: UIEditTextPropertyViewController, propertyIdentifier: String!, newValue: String!, userInfo: [String : AnyObject?]?) {
        if propertyIdentifier == "QUES_CONTENT" {
            let hud = self.showActivityHud()
            let req = UpdateMYQuestionRequest()
            req.question = newValue
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MYQMainInfo>) in
                hud.hide(animated: true)
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
                        self.mainInfo.usrQues.insert(myQuestion, at: 0)
                    }
                    self.playCheckMark()
                }else{
                    self.playCrossMark()
                }
            }
        }
    }
    
    fileprivate func getMainInfoData() {
        let hud = self.showActivityHud()
        let req = GetMYQMainInfoRequest()
        req.location = ServiceContainer.getLocationService().hereShortString
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MYQMainInfo>) in
            hud.hide(animated: true)
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
    
    fileprivate func showNewerAlert(){
        let ac = UIAlertAction(title: "POST_QUESTION".MYQLocalizedString, style: .default) { (ac) in
            self.onMyContentClicked(self.myContentButton)
        }
        self.showAlert("MYQ".MYQLocalizedString, msg: "MYQ_NEWER_MESSAGE".MYQLocalizedString, actions: [ac])
    }
}
