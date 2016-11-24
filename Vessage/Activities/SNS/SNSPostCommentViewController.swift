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

@objc protocol SNSPostCommentCellDelegate {
    optional func snsPostCommentCellDidClickComment(sender:UILabel,cell:SNSPostCommentCell,comment:SNSPostComment?)
    optional func snsPostCommentCellDidClick(sender:UIView,cell:SNSPostCommentCell,comment:SNSPostComment?)
    optional func snsPostCommentCellDidClickPostInfo(sender:UILabel,cell:SNSPostCommentCell,comment:SNSPostComment?)
}

class SNSPostCommentCell: UITableViewCell {
    
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
    private var inited = false
    @IBOutlet weak var atNickLabel: UILabel!
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    private func initCell() {
        if inited == false {
            let cmtGes = UITapGestureRecognizer(target: self, action: #selector(SNSPostCommentCell.onTapCellView(_:)))
            let pstGes = UITapGestureRecognizer(target: self, action: #selector(SNSPostCommentCell.onTapCellView(_:)))
            let cellGes = UITapGestureRecognizer(target: self, action: #selector(SNSPostCommentCell.onTapCellView(_:)))
            cellGes.requireGestureRecognizerToFail(cmtGes)
            cellGes.requireGestureRecognizerToFail(pstGes)
            self.commentLabel.addGestureRecognizer(cmtGes)
            self.postInfoLabel.addGestureRecognizer(pstGes)
            self.contentView.addGestureRecognizer(cellGes)
            atNickLabel.userInteractionEnabled = true
            postInfoLabel.userInteractionEnabled = true
            commentLabel.userInteractionEnabled = true
            inited = true
        }
    }
    
    func onTapCellView(a:UITapGestureRecognizer) {
        if a.view == self.postInfoLabel {
            delegate?.snsPostCommentCellDidClickPostInfo?(a.view as! UILabel,cell: self, comment: comment)
        }else if a.view == self.commentLabel{
            delegate?.snsPostCommentCellDidClickComment?(a.view as! UILabel,cell: self, comment: comment)
        }else if a.view == self.contentView{
            delegate?.snsPostCommentCellDidClick?(a.view!,cell: self, comment: comment)
        }
    }
    
    func updateCell() {
        if let cmt = comment{
            commentLabel?.text = cmt.cmt
            postInfoLabel?.text = "By \(cmt.psterNk)"
            if let atnick = cmt.atNick {
                atNickLabel?.text = "@\(atnick)"
                atNickLabel?.hidden = false
            }else{
                atNickLabel?.text = nil
                atNickLabel?.hidden = true
            }
        }
    }
}

class SNSPostCommentViewController: UIViewController {
    
    private var post:SNSPost!
    
    private var comments = [[SNSPostComment]](){
        didSet{
            self.tableView?.reloadData()
        }
    }
    
    private var responseTextField = UITextField(frame:CGRectZero)
    private var commentInputView = SNSCommentInputView.instanceFromXib()
    
    private var userService = ServiceContainer.getUserService()
    
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
        responseTextField.hidden = true
        responseTextField.inputAccessoryView = commentInputView
        commentInputView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        refreshPostComments(){
            if self.comments.count == 0{
                self.showNewCommentInputView(nil, atUserNick: nil)
            }
        }
    }
    
    func onTapView(ges:UITapGestureRecognizer) {
        hideCommentInputView()
    }
    
    func hideCommentInputView() {
        self.responseTextField.endEditing(true)
        self.commentInputView.inputTextField?.endEditing(true)
        self.hideKeyBoard()
    }
    
    @IBAction func onNewCommentClick(sender: AnyObject) {
        showNewCommentInputView(nil,atUserNick: nil)
    }
    
    func showNewCommentInputView(model:AnyObject?,atUserNick:String?) {
        commentInputView.showInputView(responseTextField, model: model, atUserNick: atUserNick)
    }
    
    func mjFooterRefresh(a:AnyObject?) {
        refreshPostComments()
    }
    
    func mjHeaderRefresh(a:AnyObject?) {
        if self.comments.count > 0 {
            tableView.mj_header.endRefreshing()
        }else{
            refreshPostComments()
        }
    }

    func refreshPostComments(callback:(()->Void)? = nil) {
        let ts:Int64 = self.comments.last?.last?.ts ?? 0
        let hud:MBProgressHUD? = ts == 0 ? self.showActivityHud() : nil
        
        SNSPostManager.instance.getPostComment(self.post.pid, ts: ts) { (comments) in
            hud?.hideAnimated(true)
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
        }
    }
    
    static func showPostCommentViewController(vc:UINavigationController, post:SNSPost) -> SNSPostCommentViewController{
        let controller = instanceFromStoryBoard("SNS", identifier: "SNSPostCommentViewController") as! SNSPostCommentViewController
        controller.post = post
        vc.pushViewController(controller, animated: true)
        return controller
    }
}

//MARK: SNSCommentInputViewDelegate
extension SNSPostCommentViewController:SNSCommentInputViewDelegate{
    func commentInputViewDidClickSend(sender: SNSCommentInputView, textField: UITextField) {
        let cmt = textField.text
        if !String.isNullOrWhiteSpace(cmt) {
            textField.text = nil
            sender.hideInputView()
            let myNick = ServiceContainer.getUserService().myProfile.nickName
            let cmtObj = sender.model as? SNSPostComment
            let hud = self.showActivityHud()
            SNSPostManager.instance.newPostComment(self.post.pid, comment: cmt!,senderNick: myNick,atUser: cmtObj?.pster,atUserNick: cmtObj?.psterNk, callback: { (posted,msg) in
                hud.hideAnimated(true)
                if posted{
                    let ncomment = SNSPostComment()
                    ncomment.cmt = cmt
                    ncomment.pster = UserSetting.userId
                    ncomment.psterNk = "ME".localizedString()
                    ncomment.ts = DateHelper.UnixTimeSpanTotalMilliseconds
                    ncomment.atNick = cmtObj?.psterNk
                    ncomment.img = self.post.img
                    ncomment.postId = self.post.pid
                    
                    self.post.cmtCnt += 1
                    self.comments.append([ncomment])
                    self.playCheckMark()
                }else{
                    self.playCrossMark(msg)
                }
            })
        }else{
            self.playToast("INPUT_COMMENT_CONTENT".SNSString)
        }
    }
    
    func commentInputViewDidEndEditing(sender: SNSCommentInputView, textField: UITextField) {
        responseTextField.resignFirstResponder()
    }
}

//MARK:UITableViewDelegate
extension SNSPostCommentViewController:UITableViewDataSource,UITableViewDelegate{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SNSPostCommentCell.reuseId, forIndexPath: indexPath) as! SNSPostCommentCell
        let cmt = comments[indexPath.section][indexPath.row]
        
        if let noteName = userService.getUserNotedNameIfExists(cmt.pster) {
            cmt.psterNk = noteName
        }
        
        cell.comment = cmt
        cell.delegate = self
        return cell
    }
}

//MARK:SNSPostCommentCellDelegate
extension SNSPostCommentViewController:SNSPostCommentCellDelegate{
    
    func snsPostCommentCellDidClick(sender: UIView, cell: SNSPostCommentCell, comment: SNSPostComment?) {
        hideCommentInputView()
    }
    
    func snsPostCommentCellDidClickComment(sender: UILabel, cell: SNSPostCommentCell, comment: SNSPostComment?) {
        if let cmt = comment{
            showNewCommentInputView(cmt, atUserNick: cmt.psterNk)
        }
    }
    
    func snsPostCommentCellDidClickPostInfo(sender: UILabel, cell: SNSPostCommentCell, comment: SNSPostComment?) {
        sender.animationMaxToMin(0.2, maxScale: 1.2) { 
            if let pster = comment?.pster{
                let delegate = UserProfileViewControllerDelegateOpenConversation()
                UserProfileViewController.showUserProfileViewController(self, userId: pster,delegate: delegate)
            }
        }
    }
}
