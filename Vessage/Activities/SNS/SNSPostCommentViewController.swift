//
//  SNSPostCommentViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import MBProgressHUD
import TTTAttributedLabel

@objc protocol SNSPostCommentCellDelegate {
    @objc optional func snsPostCommentCellDidClickComment(_ sender:UILabel,cell:SNSPostCommentCell,comment:SNSPostComment?)
    @objc optional func snsPostCommentCellDidClick(_ sender:UIView,cell:SNSPostCommentCell,comment:SNSPostComment?)
    @objc optional func snsPostCommentCellDidClickPostInfo(_ sender:UILabel,cell:SNSPostCommentCell,comment:SNSPostComment?)
    func snsPostCommentCellRootController(_ sender:SNSPostCommentCell) -> UIViewController?
}

protocol SNSCommentViewControllerDelegate {
    func snsCommentController(_ sender:SNSPostCommentViewController, didPostNewComment newComment:SNSPostComment,post:SNSPost)
}

class SNSPostCommentCell: UITableViewCell,TTTAttributedLabelDelegate {
    
    static let reuseId = "SNSPostCommentCell"
    
    weak var delegate:SNSPostCommentCellDelegate?
    
    weak var comment:SNSPostComment!{
        didSet{
            if comment != nil{
                initCell()
            }
            updateCell()
        }
    }
    fileprivate var inited = false
    @IBOutlet weak var atNickLabel: UILabel!
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var commentLabel: TTTAttributedLabel!{
        didSet{
            commentLabel.delegate = self
            commentLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        }
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let c = delegate?.snsPostCommentCellRootController(self){
            SimpleBrowser.openUrl(c, url: url.absoluteString, title: nil)
        }
        for ges in (label.gestureRecognizers?.filter{$0 is UITapGestureRecognizer} ?? []){
            ges.cancelsTouchesInView = true
        }
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        attributedLabel(label, didSelectLinkWith: url)
    }
    
    fileprivate func initCell() {
        if inited == false {
            let cmtGes = UITapGestureRecognizer(target: self, action: #selector(SNSPostCommentCell.onTapCellView(_:)))
            let pstGes = UITapGestureRecognizer(target: self, action: #selector(SNSPostCommentCell.onTapCellView(_:)))
            let cellGes = UITapGestureRecognizer(target: self, action: #selector(SNSPostCommentCell.onTapCellView(_:)))
            cellGes.require(toFail: cmtGes)
            cellGes.require(toFail: pstGes)
            self.commentLabel.addGestureRecognizer(cmtGes)
            self.postInfoLabel.addGestureRecognizer(pstGes)
            self.contentView.addGestureRecognizer(cellGes)
            atNickLabel.isUserInteractionEnabled = true
            postInfoLabel.isUserInteractionEnabled = true
            commentLabel.isUserInteractionEnabled = true
            inited = true
        }
    }
    
    func onTapCellView(_ a:UITapGestureRecognizer) {
        if comment.st < 0 {
            return
        }
        if a.view == self.postInfoLabel {
            delegate?.snsPostCommentCellDidClickPostInfo?(a.view as! UILabel,cell: self, comment: comment)
        }else if a.view == self.commentLabel{
            let p = a.location(in: self.commentLabel)
            if self.commentLabel.containslink(at: p){
                a.cancelsTouchesInView = false
            }else{
                delegate?.snsPostCommentCellDidClickComment?(a.view as! UILabel,cell: self, comment: comment)
            }
        }else if a.view == self.contentView{
            delegate?.snsPostCommentCellDidClick?(a.view!,cell: self, comment: comment)
        }
    }
    
    func updateCell() {
        if let cmt = comment{
            commentLabel?.setTextAndSimplifyUrl(text: cmt.getOutputContent())
            postInfoLabel?.text = "By \(cmt.psterNk ?? "")"
            if let atnick = cmt.atNick {
                atNickLabel?.text = "@\(atnick)"
                atNickLabel?.isHidden = false
            }else{
                atNickLabel?.text = nil
                atNickLabel?.isHidden = true
            }
        }
    }
}

class SNSPostCommentViewController: UIViewController {
    var delegate:SNSCommentViewControllerDelegate?
    
    fileprivate var post:SNSPost!
    
    fileprivate var comments = [[SNSPostComment]](){
        didSet{
            self.tableView?.reloadData()
        }
    }
    
    fileprivate var responseTextField = UITextField(frame:CGRect.zero)
    fileprivate var commentInputView = SNSCommentInputView.instanceFromXib()
    
    fileprivate var userService = ServiceContainer.getUserService()
    
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor(hexString: "#f6f6f6")
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(SNSPostCommentViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(SNSPostCommentViewController.mjFooterRefresh(_:)))
        self.view.addSubview(responseTextField)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSPostCommentViewController.onTapView(_:))))
        responseTextField.isHidden = true
        responseTextField.inputAccessoryView = commentInputView
        commentInputView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshPostComments(){
            if self.comments.count == 0{
                self.showNewCommentInputView(nil, atUserNick: nil)
            }
        }
    }
    
    func onTapView(_ ges:UITapGestureRecognizer) {
        hideCommentInputView()
    }
    
    func hideCommentInputView() {
        self.responseTextField.endEditing(true)
        self.commentInputView.inputTextField?.endEditing(true)
        self.hideKeyBoard()
    }
    
    @IBAction func onNewCommentClick(_ sender: AnyObject) {
        showNewCommentInputView(nil,atUserNick: nil)
    }
    
    func showNewCommentInputView(_ model:AnyObject?,atUserNick:String?) {
        commentInputView.showInputView(responseTextField, model: model, atUserNick: atUserNick)
    }
    
    func mjFooterRefresh(_ a:AnyObject?) {
        refreshPostComments()
    }
    
    func mjHeaderRefresh(_ a:AnyObject?) {
        if self.comments.count > 0 {
            tableView.mj_header.endRefreshing()
        }else{
            refreshPostComments()
        }
    }

    func refreshPostComments(_ callback:(()->Void)? = nil) {
        let ts:Int64 = self.comments.last?.last?.ts ?? 0
        let hud:MBProgressHUD? = ts == 0 ? self.showActivityHud() : nil
        
        SNSPostManager.instance.getPostComment(self.post.pid, ts: ts) { (comments) in
            hud?.hide(animated: true)
            if hud == nil{
                self.tableView?.mj_footer?.endRefreshing()
            }else{
                self.tableView?.mj_header?.endRefreshing()
            }
            if let cmts = comments{
                if cmts.count > 0{
                    self.comments.append(cmts)
                }else{
                    self.tableView?.mj_footer?.endRefreshingWithNoMoreData()
                }
            }
            callback?()
        }
    }
    
    static func showPostCommentViewController(_ vc:UINavigationController, post:SNSPost) -> SNSPostCommentViewController{
        let controller = instanceFromStoryBoard("SNS", identifier: "SNSPostCommentViewController") as! SNSPostCommentViewController
        controller.post = post
        vc.pushViewController(controller, animated: true)
        return controller
    }
}

//MARK: SNSCommentInputViewDelegate
extension SNSPostCommentViewController:SNSCommentInputViewDelegate{
    func commentInputViewDidClickSend(_ sender: SNSCommentInputView, textField: UITextField) {
        let cmt = textField.text
        if !String.isNullOrWhiteSpace(cmt) {
            textField.text = nil
            sender.hideInputView()
            let myNick = ServiceContainer.getUserService().myProfile.nickName
            let cmtObj = sender.model as? SNSPostComment
            let hud = self.showActivityHud()
            if let uid = self.post?.usrId{
                ServiceContainer.getConversationService().expireConversation(uid)
            }
            SNSPostManager.instance.newPostComment(self.post.pid, comment: cmt!,senderNick: myNick,atUser: cmtObj?.pster,atUserNick: cmtObj?.psterNk, callback: { (posted,msg) in
                hud.hide(animated: true)
                if let id = posted{
                    let ncomment = SNSPostComment()
                    ncomment.id = id
                    ncomment.cmt = cmt
                    ncomment.pster = UserSetting.userId
                    ncomment.psterNk = "ME".localizedString()
                    ncomment.ts = DateHelper.UnixTimeSpanTotalMilliseconds
                    ncomment.atNick = cmtObj?.psterNk
                    ncomment.img = self.post.img
                    ncomment.postId = self.post.pid
                    
                    self.post.cmtCnt += 1
                    self.comments.append([ncomment])
                    self.delegate?.snsCommentController(self, didPostNewComment: ncomment,post: self.post)
                    self.playCheckMark()
                }else{
                    self.playCrossMark(msg)
                }
            })
        }else{
            self.playToast("INPUT_COMMENT_CONTENT".SNSString)
        }
    }
    
    func commentInputViewDidEndEditing(_ sender: SNSCommentInputView, textField: UITextField) {
        responseTextField.resignFirstResponder()
    }
}

//MARK:UITableViewDelegate
extension SNSPostCommentViewController:UITableViewDataSource,UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SNSPostCommentCell.reuseId, for: indexPath) as! SNSPostCommentCell
        let cmt = comments[indexPath.section][indexPath.row]
        
        if let noteName = userService.getUserNotedNameIfExists(cmt.pster) {
            cmt.psterNk = noteName
        }
        
        cell.comment = cmt
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cmt = comments[indexPath.section][indexPath.row]
        return cmt.st >= 0 && (cmt.pster == UserSetting.userId || post.usrId == UserSetting.userId)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layoutSubviews()
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cmt = comments[indexPath.section][indexPath.row]
        let isCmtOwner = cmt.pster == UserSetting.userId
        
        if isCmtOwner || post.usrId == UserSetting.userId {
            let ac = UITableViewRowAction(style: .normal, title: "RM_PST_CMT".SNSString) { (a, index) in
                
                let deleteAction = UIAlertAction(title: "CONFIRM".localizedString(), style: .default, handler: { (yes) in
                    let hud = self.showActivityHud()
                    SNSPostManager.instance.deletePostComment(cmt.postId, cmtId: cmt.id, isCmtOwner: isCmtOwner, callback: { (suc) in
                        hud.hide(animated: true)
                        if suc{
                            self.comments[indexPath.section][indexPath.row].st = -1
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }else{
                            self.playCrossMark()
                        }
                    })
                })
                
                self.showAlert("DT_CMT_CONFIRM_ALERT_TITLE".SNSString, msg: "DT_CMT_CONFIRM_ALERT_MSG".SNSString, actions: [deleteAction,ALERT_ACTION_CANCEL])
                
                
            }
            return [ac]
        }else{
            return nil
        }
    }
}

//MARK:SNSPostCommentCellDelegate
extension SNSPostCommentViewController:SNSPostCommentCellDelegate{
    func snsPostCommentCellRootController(_ sender: SNSPostCommentCell) -> UIViewController? {
        return self
    }
    
    func snsPostCommentCellDidClick(_ sender: UIView, cell: SNSPostCommentCell, comment: SNSPostComment?) {
        if self.commentInputView.inputTextField.isEditing {
            hideCommentInputView()
        }else if let cmt = comment{
            showNewCommentInputView(cmt, atUserNick: cmt.psterNk)
        }
    }
    
    func snsPostCommentCellDidClickComment(_ sender: UILabel, cell: SNSPostCommentCell, comment: SNSPostComment?) {
        snsPostCommentCellDidClick(sender, cell: cell, comment: comment)
    }
    
    func snsPostCommentCellDidClickPostInfo(_ sender: UILabel, cell: SNSPostCommentCell, comment: SNSPostComment?) {
        sender.animationMaxToMin(0.2, maxScale: 1.2) { 
            if let pster = comment?.pster{
                let delegate = UserProfileViewControllerDelegateOpenConversation()
                delegate.createActivityId = SNSPostManager.activityId
                UserProfileViewController.showUserProfileViewController(self, userId: pster,delegate: delegate){ controller in
                    controller.accountIdHidden = true
                    controller.snsButtonEnabled = false
                }
            }
        }
    }
}
