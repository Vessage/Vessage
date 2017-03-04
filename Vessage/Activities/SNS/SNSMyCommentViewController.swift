//
//  SNSMyCommentViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/17.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import ImageSlideshow

@objc protocol SNSMyCommentCellDelegate {
    optional func snsMyCommentCellDidClickContent(sender:UIView,cell:SNSMyCommentCell,comment:SNSPostComment?)
    optional func snsMyCommentCellDidClickImage(sender:UIView,cell:SNSMyCommentCell,comment:SNSPostComment?)
    optional func snsMyCommentCellDidClickPoster(sender:UIView,cell:SNSMyCommentCell,comment:SNSPostComment?)
}

class SNSMyCommentCell: UITableViewCell {
    static let reuseId = "SNSMyCommentCell"
    @IBOutlet weak var commentContentLabel: UILabel!{
        didSet{
            commentContentLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var commentInfoLabel: UILabel!
    @IBOutlet weak var commentPosterNickLabel: UILabel!{
        didSet{
            commentPosterNickLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var postImageView: UIImageView!{
        didSet{
            postImageView.contentMode = .ScaleAspectFill
            postImageView.clipsToBounds = true
            postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentCell.onTapViews(_:))))
        }
    }
    weak var comment:SNSPostComment?
    weak var delegate:SNSMyCommentCellDelegate?
    func updateCell() {
        if let cmt = comment{
            commentContentLabel.text = cmt.cmt
            commentPosterNickLabel.text = cmt.psterNk
            let atNick = String.isNullOrWhiteSpace(cmt.atNick) ? "" : "@\(cmt.atNick) "
            let txtClip = String.isNullOrWhiteSpace(cmt.txt) ? "" : "  \(cmt.txt!)"
            commentInfoLabel.text = "\(atNick)\(cmt.getPostDateFriendString())\(txtClip)"
            ServiceContainer.getFileService().setImage(self.postImageView, iconFileId: cmt.img, defaultImage: UIImage(named:"SNS_post_img_bcg"), callback: nil)
        }
    }
    
    func onTapViews(ges:UITapGestureRecognizer) {
        if ges.view == commentContentLabel {
            delegate?.snsMyCommentCellDidClickContent?(ges.view!, cell: self, comment: comment)
        }else if ges.view == commentPosterNickLabel{
            delegate?.snsMyCommentCellDidClickPoster?(ges.view!, cell: self, comment: comment)
        }else if ges.view == postImageView{
            delegate?.snsMyCommentCellDidClickImage?(ges.view!, cell: self, comment: comment)
        }
    }
}

class SNSMyCommentViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var responseTextField = UITextField(frame:CGRectZero)
    private var commentInputView = SNSCommentInputView.instanceFromXib()
    private var userService = ServiceContainer.getUserService()
    private var comments = [[SNSPostComment]]()
    private var initCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor(hexString: "#f6f6f6")
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(SNSMyCommentViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(SNSMyCommentViewController.mjFooterRefresh(_:)))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(responseTextField)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentViewController.onTapView(_:))))
        responseTextField.hidden = true
        responseTextField.inputAccessoryView = commentInputView
        commentInputView.delegate = self
    }
    
    func onTapView(ges:UITapGestureRecognizer) {
        hideCommentInputView()
    }
    
    func hideCommentInputView() {
        self.responseTextField.endEditing(true)
        self.commentInputView.inputTextField?.endEditing(true)
        self.hideKeyBoard()
    }
    
    func showNewCommentInputView(model:AnyObject?,atUserNick:String?) {
        commentInputView.showInputView(responseTextField, model: model, atUserNick: atUserNick)
    }
    
    func loadInitComments(cnt:Int) {
        initCount = cnt
        comments.removeAll()
        let hud = self.showActivityHud()
        SNSPostManager.instance.getMyComments(DateHelper.UnixTimeSpanTotalMilliseconds, cnt: cnt) { (comments) in
            hud.hideAnimated(true)
            if let cmts = comments{
                self.comments.append(cmts)
                self.tableView.reloadData()
            }
        }
    }
    
    func mjFooterRefresh(a:AnyObject?) {
        if let last = comments.last?.last{
            SNSPostManager.instance.getMyComments(last.ts, cnt: 20, callback: { (comments) in
                if let cmts = comments{
                    self.comments.append(cmts)
                    self.tableView.reloadData()
                    if cmts.count < 20{
                        self.tableView.mj_footer.endRefreshingWithNoMoreData()
                    }else{
                        self.tableView.mj_footer.endRefreshing()
                    }
                }
            })
        }else{
            tableView.mj_footer.endRefreshingWithNoMoreData()
        }
    }
    
    func mjHeaderRefresh(a:AnyObject?) {
        tableView.mj_header.endRefreshing()
        if self.comments.count == 0 {
            loadInitComments(initCount)
        }
    }
    
    static func instanceFromStoryBoard() -> SNSMyCommentViewController{
        let ctr = instanceFromStoryBoard("SNS", identifier: "SNSMyCommentViewController") as! SNSMyCommentViewController
        return ctr
    }
}

//MARK:SNSMyCommentCellDelegate
extension SNSMyCommentViewController:SNSMyCommentCellDelegate{
    func snsMyCommentCellDidClickImage(sender: UIView, cell: SNSMyCommentCell, comment: SNSPostComment?) {
        if let imgV = cell.postImageView {
            imgV.slideShowFullScreen(self)
        }
    }
    
    func snsMyCommentCellDidClickPoster(sender: UIView, cell: SNSMyCommentCell, comment: SNSPostComment?) {
        if let poster = comment?.pster{
            let delegate = UserProfileViewControllerDelegateOpenConversation()
            UserProfileViewController.showUserProfileViewController(self, userId: poster,delegate: delegate){ controller in
                controller.accountIdHidden = true
                controller.snsButtonEnabled = false
            }
        }
    }
    
    func snsMyCommentCellDidClickContent(sender: UIView, cell: SNSMyCommentCell, comment: SNSPostComment?) {
        if let cmt = comment {
            showNewCommentInputView(cmt, atUserNick: comment?.psterNk)
        }
        
    }
}

//MARK:SNSCommentInputViewDelegate
extension SNSMyCommentViewController:SNSCommentInputViewDelegate{
    func commentInputViewDidClickSend(sender: SNSCommentInputView, textField: UITextField) {
        let cmt = textField.text
        if !String.isNullOrWhiteSpace(cmt) {
            textField.text = nil
            sender.hideInputView()
            let model = sender.model as! SNSPostComment
            let myNick = ServiceContainer.getUserService().myProfile.nickName
            let hud = self.showActivityHud()
            SNSPostManager.instance.newPostComment(model.postId, comment: cmt!,senderNick: myNick,atUser: model.pster,atUserNick: model.psterNk, callback: { (posted,msg) in
                hud.hideAnimated(true)
                if posted{
                    let ncomment = SNSPostComment()
                    ncomment.cmt = cmt
                    ncomment.pster = UserSetting.userId
                    ncomment.psterNk = "ME".localizedString()
                    ncomment.ts = DateHelper.UnixTimeSpanTotalMilliseconds
                    ncomment.atNick = model.psterNk
                    ncomment.img = model.img
                    ncomment.postId = model.postId
                    self.comments.insert([ncomment], atIndex: 0)
                    self.tableView.reloadData()
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

//MARK:TableView Delegate
extension SNSMyCommentViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments[section].count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? SNSMyCommentCell{
            c.updateCell()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SNSMyCommentCell.reuseId, forIndexPath: indexPath) as! SNSMyCommentCell
        let cmt = comments[indexPath.section][indexPath.row]
        
        if let noteName = userService.getUserNotedNameIfExists(cmt.pster) {
            cmt.psterNk = noteName
        }
        
        cell.comment = cmt
        cell.delegate = self
        return cell
    }
}
