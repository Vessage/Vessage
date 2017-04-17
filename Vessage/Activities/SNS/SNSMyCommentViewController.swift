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
import TTTAttributedLabel

@objc protocol SNSMyCommentCellDelegate {
    @objc optional func snsMyCommentCellDidClickContent(_ sender:UIView,cell:SNSMyCommentCell,comment:SNSPostComment?)
    @objc optional func snsMyCommentCellDidClickImage(_ sender:UIView,cell:SNSMyCommentCell,comment:SNSPostComment?)
    @objc optional func snsMyCommentCellDidClickPoster(_ sender:UIView,cell:SNSMyCommentCell,comment:SNSPostComment?)
    func snsMyCommentCellRootController(cell:SNSMyCommentCell) -> UIViewController?
}

class SNSMyCommentCell: UITableViewCell,TTTAttributedLabelDelegate {
    static let reuseId = "SNSMyCommentCell"
    @IBOutlet weak var commentContentLabel: TTTAttributedLabel!{
        didSet{
            commentContentLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
            commentContentLabel.delegate = self
            let ges = UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentCell.onTapViews(_:)))
            ges.delegate = self
            commentContentLabel.addGestureRecognizer(ges)
        }
    }
    @IBOutlet weak var commentInfoLabel: UILabel!
    @IBOutlet weak var commentPosterNickLabel: UILabel!{
        didSet{
            let ges = UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentCell.onTapViews(_:)))
            ges.delegate = self
            commentPosterNickLabel.addGestureRecognizer(ges)
        }
    }
    @IBOutlet weak var postImageView: UIImageView!{
        didSet{
            postImageView.contentMode = .scaleAspectFill
            postImageView.clipsToBounds = true
            let ges = UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentCell.onTapViews(_:)))
            ges.delegate = self
            postImageView.addGestureRecognizer(ges)
        }
    }
    
    weak var comment:SNSPostComment?{
        didSet{
            updateCell()
        }
    }
    
    weak var delegate:SNSMyCommentCellDelegate?
    
    fileprivate func updateCell() {
        if let cmt = comment{
            commentContentLabel?.setTextAndSimplifyUrl(text: cmt.getOutputContent())
            commentPosterNickLabel?.text = cmt.psterNk
            
            let atNick = String.isNullOrWhiteSpace(cmt.atNick) ? "" : "@\(cmt.atNick!) "
            let txtClip = String.isNullOrWhiteSpace(cmt.txt) ? "" : "  \(cmt.txt!)"
            commentInfoLabel?.text = "\(atNick)\(cmt.getPostDateFriendString())\(txtClip)"
            ServiceContainer.getFileService().setImage(self.postImageView, iconFileId: cmt.img, defaultImage: UIImage(named:"SNS_post_img_bcg"), callback: nil)
        }
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let c = delegate?.snsMyCommentCellRootController(cell:self){
            SimpleBrowser.openUrl(c, url: url.absoluteString, title: nil)
        }
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        attributedLabel(label, didSelectLinkWith: url)
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let label = touch.view as? TTTAttributedLabel{
            return !label.containslink(at: touch.location(in: label))
        }
        return true
    }
    
    func onTapViews(_ ges:UITapGestureRecognizer) {
        if ges.view == commentContentLabel {
            delegate?.snsMyCommentCellDidClickContent?(ges.view!, cell: self, comment: comment)
        }else if ges.view == commentPosterNickLabel{
            delegate?.snsMyCommentCellDidClickPoster?(ges.view!, cell: self, comment: comment)
        }else if ges.view == postImageView{
            delegate?.snsMyCommentCellDidClickImage?(ges.view!, cell: self, comment: comment)
        }
    }
}

class SNSMyCommentViewController: UIViewController,UIGestureRecognizerDelegate {
    @IBOutlet weak var tableView: UITableView!
    fileprivate var responseTextField = UITextField(frame:CGRect.zero)
    fileprivate var commentInputView = SNSCommentInputView.instanceFromXib()
    fileprivate var userService = ServiceContainer.getUserService()
    fileprivate var comments = [[SNSPostComment]]()
    fileprivate var initCount = 0
    
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
        let ges = UITapGestureRecognizer(target: self, action: #selector(SNSMyCommentViewController.onTapView(_:)))
        ges.delegate = self
        self.view.addGestureRecognizer(ges)
        responseTextField.isHidden = true
        responseTextField.inputAccessoryView = commentInputView
        commentInputView.delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let label = touch.view as? TTTAttributedLabel{
            return !label.containslink(at: touch.location(in: label))
        }
        return true
    }
    
    func onTapView(_ ges:UITapGestureRecognizer) {
        hideCommentInputView()
    }
    
    func hideCommentInputView() {
        self.responseTextField.endEditing(true)
        self.commentInputView.inputTextField?.endEditing(true)
        self.hideKeyBoard()
    }
    
    func showNewCommentInputView(_ model:AnyObject?,atUserNick:String?) {
        commentInputView.showInputView(responseTextField, model: model, atUserNick: atUserNick)
    }
    
    func loadInitComments(_ cnt:Int) {
        initCount = cnt
        comments.removeAll()
        let hud = self.showActivityHud()
        SNSPostManager.instance.getMyComments(DateHelper.UnixTimeSpanTotalMilliseconds, cnt: cnt) { (comments) in
            hud.hide(animated: true)
            if let cmts = comments{
                self.comments.append(cmts)
                self.tableView.reloadData()
            }
        }
    }
    
    func mjFooterRefresh(_ a:AnyObject?) {
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
    
    func mjHeaderRefresh(_ a:AnyObject?) {
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
    func snsMyCommentCellRootController(cell: SNSMyCommentCell) -> UIViewController? {
        return self
    }

    func snsMyCommentCellDidClickImage(_ sender: UIView, cell: SNSMyCommentCell, comment: SNSPostComment?) {
        if let imgV = cell.postImageView {
            imgV.slideShowFullScreen(self)
        }
    }
    
    func snsMyCommentCellDidClickPoster(_ sender: UIView, cell: SNSMyCommentCell, comment: SNSPostComment?) {
        if let poster = comment?.pster{
            let delegate = UserProfileViewControllerDelegateOpenConversation()
            UserProfileViewController.showUserProfileViewController(self, userId: poster,delegate: delegate){ controller in
                controller.accountIdHidden = true
                controller.snsButtonEnabled = false
            }
        }
    }
    
    func snsMyCommentCellDidClickContent(_ sender: UIView, cell: SNSMyCommentCell, comment: SNSPostComment?) {
        if commentInputView.inputTextField.isEditing {
            hideCommentInputView()
        }else if let cmt = comment {
            showNewCommentInputView(cmt, atUserNick: comment?.psterNk)
        }
        
    }
}

//MARK:SNSCommentInputViewDelegate
extension SNSMyCommentViewController:SNSCommentInputViewDelegate{
    func commentInputViewDidClickSend(_ sender: SNSCommentInputView, textField: UITextField) {
        let cmt = textField.text
        if !String.isNullOrWhiteSpace(cmt) {
            textField.text = nil
            sender.hideInputView()
            let model = sender.model as! SNSPostComment
            let myNick = ServiceContainer.getUserService().myProfile.nickName
            let hud = self.showActivityHud()
            SNSPostManager.instance.newPostComment(model.postId, comment: cmt!,senderNick: myNick,atUser: model.pster,atUserNick: model.psterNk, callback: { (posted,msg) in
                hud.hide(animated: true)
                if let id = posted{
                    let ncomment = SNSPostComment()
                    ncomment.id = id
                    ncomment.cmt = cmt
                    ncomment.pster = UserSetting.userId
                    ncomment.psterNk = "ME".localizedString()
                    ncomment.ts = DateHelper.UnixTimeSpanTotalMilliseconds
                    ncomment.atNick = model.psterNk
                    ncomment.img = model.img
                    ncomment.postId = model.postId
                    self.comments.insert([ncomment], at: 0)
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
    
    func commentInputViewDidEndEditing(_ sender: SNSCommentInputView, textField: UITextField) {
        responseTextField.resignFirstResponder()
    }
}

//MARK:TableView Delegate
extension SNSMyCommentViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments[section].count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layoutSubviews()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SNSMyCommentCell.reuseId, for: indexPath) as! SNSMyCommentCell
        let cmt = comments[indexPath.section][indexPath.row]
        
        if let noteName = userService.getUserNotedNameIfExists(cmt.pster) {
            cmt.psterNk = noteName
        }
        
        cell.comment = cmt
        cell.delegate = self
        return cell
    }
}
