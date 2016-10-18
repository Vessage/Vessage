//
//  NFCMyCommentViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/17.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import ImageSlideshow

@objc protocol NFCMyCommentCellDelegate {
    optional func nfcMyCommentCellDidClickContent(sender:UIView,cell:NFCMyCommentCell,comment:NFCPostComment?)
    optional func nfcMyCommentCellDidClickImage(sender:UIView,cell:NFCMyCommentCell,comment:NFCPostComment?)
    optional func nfcMyCommentCellDidClickPoster(sender:UIView,cell:NFCMyCommentCell,comment:NFCPostComment?)
}

class NFCMyCommentCell: UITableViewCell {
    static let reuseId = "NFCMyCommentCell"
    @IBOutlet weak var commentContentLabel: UILabel!{
        didSet{
            commentContentLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCMyCommentCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var commentInfoLabel: UILabel!
    @IBOutlet weak var commentPosterNickLabel: UILabel!{
        didSet{
            commentPosterNickLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCMyCommentCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var postImageView: UIImageView!{
        didSet{
            postImageView.contentMode = .ScaleAspectFill
            postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCMyCommentCell.onTapViews(_:))))
        }
    }
    weak var comment:NFCPostComment?
    weak var delegate:NFCMyCommentCellDelegate?
    func updateCell() {
        if let cmt = comment{
            commentContentLabel.text = cmt.cmt
            commentPosterNickLabel.text = cmt.psterNk
            let atNick = String.isNullOrWhiteSpace(cmt.atNick) ? "" : "@\(cmt.atNick) "
            commentInfoLabel.text = "\(atNick)\(cmt.getPostDateFriendString())"
            ServiceContainer.getFileService().setImage(self.postImageView, iconFileId: cmt.img, defaultImage: UIImage(named:"nfc_post_img_bcg"), callback: nil)
        }
    }
    
    func onTapViews(ges:UITapGestureRecognizer) {
        if ges.view == commentContentLabel {
            delegate?.nfcMyCommentCellDidClickContent?(ges.view!, cell: self, comment: comment)
        }else if ges.view == commentPosterNickLabel{
            delegate?.nfcMyCommentCellDidClickPoster?(ges.view!, cell: self, comment: comment)
        }else if ges.view == postImageView{
            delegate?.nfcMyCommentCellDidClickImage?(ges.view!, cell: self, comment: comment)
        }
    }
}

class NFCMyCommentViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var responseTextField = UITextField(frame:CGRectZero)
    private var commentInputView = NFCCommentInputView.instanceFromXib()
    
    private var comments = [[NFCPostComment]]()
    private var initCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor(hexString: "#f6f6f6")
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(NFCMyCommentViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(NFCMyCommentViewController.mjFooterRefresh(_:)))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(responseTextField)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCMyCommentViewController.onTapView(_:))))
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
        NFCPostManager.instance.getMyComments(DateHelper.UnixTimeSpanTotalMilliseconds, cnt: cnt) { (comments) in
            hud.hideAnimated(true)
            if let cmts = comments{
                self.comments.append(cmts)
                self.tableView.reloadData()
            }
        }
    }
    
    func mjFooterRefresh(a:AnyObject?) {
        if let last = comments.last?.last{
            NFCPostManager.instance.getMyComments(last.ts, cnt: 20, callback: { (comments) in
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
    
    static func instanceFromStoryBoard() -> NFCMyCommentViewController{
        let ctr = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCMyCommentViewController") as! NFCMyCommentViewController
        return ctr
    }
}

//MARK:NFCMyCommentCellDelegate
extension NFCMyCommentViewController:NFCMyCommentCellDelegate{
    func nfcMyCommentCellDidClickImage(sender: UIView, cell: NFCMyCommentCell, comment: NFCPostComment?) {
        if let imgV = cell.postImageView {
            imgV.slideShowFullScreen(self)
        }
    }
    
    func nfcMyCommentCellDidClickPoster(sender: UIView, cell: NFCMyCommentCell, comment: NFCPostComment?) {
        if let poster = comment?.pster{
            NFCMemberCardAlert.showNFCMemberCardAlert(self, memberId: poster)
        }
    }
    
    func nfcMyCommentCellDidClickContent(sender: UIView, cell: NFCMyCommentCell, comment: NFCPostComment?) {
        if let cmt = comment {
            showNewCommentInputView(cmt, atUserNick: comment?.psterNk)
        }
        
    }
}

//MARK:NFCCommentInputViewDelegate
extension NFCMyCommentViewController:NFCCommentInputViewDelegate{
    func commentInputViewDidClickSend(sender: NFCCommentInputView, textField: UITextField) {
        let cmt = textField.text
        if !String.isNullOrWhiteSpace(cmt) {
            textField.text = nil
            sender.hideInputView()
            let model = sender.model as! NFCPostComment
            let hud = self.showActivityHud()
            NFCPostManager.instance.newPostComment(model.postId, comment: cmt!,atMember: model.pster,atUserNick: model.psterNk, callback: { (posted,msg) in
                hud.hideAnimated(true)
                if posted{
                    let ncomment = NFCPostComment()
                    ncomment.cmt = cmt
                    ncomment.pster = NiceFaceClubManager.instance.myNiceFaceProfile.mbId
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
            self.playToast("INPUT_COMMENT_CONTENT".niceFaceClubString)
        }
    }
    
    func commentInputViewDidEndEditing(sender: NFCCommentInputView, textField: UITextField) {
        responseTextField.resignFirstResponder()
    }
}

//MARK:TableView Delegate
extension NFCMyCommentViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments[section].count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? NFCMyCommentCell{
            c.updateCell()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NFCMyCommentCell.reuseId, forIndexPath: indexPath) as! NFCMyCommentCell
        let cmt = comments[indexPath.section][indexPath.row]
        cell.comment = cmt
        cell.delegate = self
        return cell
    }
}
