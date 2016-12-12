//
//  NFCPostCommentViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import MBProgressHUD

@objc protocol NFCPostCommentCellDelegate {
    optional func nfcPostCommentCellDidClickComment(sender:UILabel,cell:NFCPostCommentCell,comment:NFCPostComment?)
    optional func nfcPostCommentCellDidClick(sender:UIView,cell:NFCPostCommentCell,comment:NFCPostComment?)
    optional func nfcPostCommentCellDidClickPostInfo(sender:UILabel,cell:NFCPostCommentCell,comment:NFCPostComment?)
}

protocol NFCCommentViewControllerDelegate {
    func nfcCommentController(sender:NFCPostCommentViewController, didPostNewComment newComment:NFCPostComment,post:NFCPost)
}

class NFCPostCommentCell: UITableViewCell {
    
    static let reuseId = "NFCPostCommentCell"
    
    weak var delegate:NFCPostCommentCellDelegate?
    
    weak var comment:NFCPostComment!{
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
            let cmtGes = UITapGestureRecognizer(target: self, action: #selector(NFCPostCommentCell.onTapCellView(_:)))
            let pstGes = UITapGestureRecognizer(target: self, action: #selector(NFCPostCommentCell.onTapCellView(_:)))
            let cellGes = UITapGestureRecognizer(target: self, action: #selector(NFCPostCommentCell.onTapCellView(_:)))
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
            delegate?.nfcPostCommentCellDidClickPostInfo?(a.view as! UILabel,cell: self, comment: comment)
        }else if a.view == self.commentLabel{
            delegate?.nfcPostCommentCellDidClickComment?(a.view as! UILabel,cell: self, comment: comment)
        }else if a.view == self.contentView{
            delegate?.nfcPostCommentCellDidClick?(a.view!,cell: self, comment: comment)
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

class NFCPostCommentViewController: UIViewController {
    var delegate:NFCCommentViewControllerDelegate?
    private var post:NFCPost!
    private var userService = ServiceContainer.getUserService()
    private var comments = [[NFCPostComment]](){
        didSet{
            self.tableView?.reloadData()
        }
    }
    
    private var responseTextField = UITextField(frame:CGRectZero)
    private var commentInputView = NFCCommentInputView.instanceFromXib()
    
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
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(NFCPostCommentViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(NFCPostCommentViewController.mjFooterRefresh(_:)))
        self.view.addSubview(responseTextField)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCPostCommentViewController.onTapView(_:))))
        responseTextField.hidden = true
        responseTextField.inputAccessoryView = commentInputView
        commentInputView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.comments.count == 0 {
            refreshPostComments(){
                if self.comments.count == 0{
                    self.showNewCommentInputView(nil, atUserNick: nil,validateFailTips: false)
                }
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
    
    func showNewCommentInputView(model:AnyObject?,atUserNick:String?,validateFailTips:Bool = true) {
        if NiceFaceClubManager.instance.isValidatedMember {
            commentInputView.showInputView(responseTextField, model: model, atUserNick: atUserNick)
        }else if validateFailTips{
            self.showAlert("NFC".niceFaceClubString, msg: "NFC_ANONYMOUS_TIPS".niceFaceClubString,actions: [ALERT_ACTION_I_SEE])
        }
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
        
        NFCPostManager.instance.getPostComment(self.post.pid, ts: ts) { (comments) in
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
            callback?()
        }
    }
    
    static func showPostCommentViewController(vc:UINavigationController, post:NFCPost) -> NFCPostCommentViewController{
        let controller = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCPostCommentViewController") as! NFCPostCommentViewController
        controller.post = post
        vc.pushViewController(controller, animated: true)
        return controller
    }
}

//MARK: NFCCommentInputViewDelegate
extension NFCPostCommentViewController:NFCCommentInputViewDelegate{
    func commentInputViewDidClickSend(sender: NFCCommentInputView, textField: UITextField) {
        let cmt = textField.text
        if !String.isNullOrWhiteSpace(cmt) {
            textField.text = nil
            sender.hideInputView()
            let cmtObj = sender.model as? NFCPostComment
            let hud = self.showActivityHud()
            NFCPostManager.instance.newPostComment(self.post.pid, comment: cmt!,atMember: cmtObj?.pster,atUserNick: cmtObj?.psterNk, callback: { (posted,msg) in
                hud.hideAnimated(true)
                if posted{
                    let ncomment = NFCPostComment()
                    ncomment.cmt = cmt
                    ncomment.pster = NiceFaceClubManager.instance.myNiceFaceProfile.mbId
                    ncomment.psterNk = "ME".localizedString()
                    ncomment.ts = DateHelper.UnixTimeSpanTotalMilliseconds
                    ncomment.atNick = cmtObj?.psterNk
                    ncomment.img = self.post.img
                    ncomment.postId = self.post.pid
                    
                    self.post.cmtCnt += 1
                    self.comments.append([ncomment])
                    self.delegate?.nfcCommentController(self, didPostNewComment: ncomment,post: self.post)
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

//MARK:UITableViewDelegate
extension NFCPostCommentViewController:UITableViewDataSource,UITableViewDelegate{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NFCPostCommentCell.reuseId, forIndexPath: indexPath) as! NFCPostCommentCell
        let cmt = comments[indexPath.section][indexPath.row]
        if let mbId = NiceFaceClubManager.instance.myNiceFaceProfile?.mbId{
            if mbId == cmt.pster{
                cmt.psterNk = "ME".localizedString()
            }
        }
        cell.comment = cmt
        cell.delegate = self
        return cell
    }
}

//MARK:NFCPostCommentCellDelegate
extension NFCPostCommentViewController:NFCPostCommentCellDelegate{
    
    func nfcPostCommentCellDidClick(sender: UIView, cell: NFCPostCommentCell, comment: NFCPostComment?) {
        hideCommentInputView()
    }
    
    func nfcPostCommentCellDidClickComment(sender: UILabel, cell: NFCPostCommentCell, comment: NFCPostComment?) {
        if let cmt = comment{
            showNewCommentInputView(cmt, atUserNick: cmt.psterNk)
        }
    }
    
    func nfcPostCommentCellDidClickPostInfo(sender: UILabel, cell: NFCPostCommentCell, comment: NFCPostComment?) {
        sender.animationMaxToMin(0.2, maxScale: 1.2) { 
            if let pster = comment?.pster{
                NFCMemberCardAlert.showNFCMemberCardAlert(self, memberId: pster)
            }
        }
    }
}
