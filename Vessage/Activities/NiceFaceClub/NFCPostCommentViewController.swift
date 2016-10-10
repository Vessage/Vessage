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

class NFCPostCommentCell: UITableViewCell {
    static let reuseId = "NFCPostCommentCell"
    
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
}

class NFCPostCommentViewController: UIViewController {
    
    private var post:NFCPost!
    
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
        self.view.addSubview(responseTextField)
        responseTextField.hidden = true
        responseTextField.inputAccessoryView = commentInputView
        commentInputView.delegate = self
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(NFCPostCommentViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(NFCPostCommentViewController.mjFooterRefresh(_:)))
        tableView.dataSource = self
        tableView.delegate = self
        refreshPostComments()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCPostCommentViewController.onTapView(_:))))
    }
    
    func onTapView(ges:UITapGestureRecognizer) {
        self.responseTextField.endEditing(true)
        self.commentInputView.inputTextField?.endEditing(true)
        self.hideKeyBoard()
    }
    
    @IBAction func onNewCommentClick(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert() {
            return
        }
        responseTextField.becomeFirstResponder()
        commentInputView.inputTextField.becomeFirstResponder()
    }
    
    func tryShowForbiddenAnymoursAlert() -> Bool{
        if !NiceFaceClubManager.instance.isValidatedMember {
            self.showAlert("NFC".niceFaceClubString, msg: "NFC_ANONYMOUS_TIPS".niceFaceClubString,actions: [ALERT_ACTION_I_SEE])
            return true
        }
        return false
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

    func refreshPostComments() {
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
        }
    }
    
    static func showNFCMemberCardAlert(vc:UINavigationController, post:NFCPost) -> NFCPostCommentViewController{
        let controller = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCPostCommentViewController") as! NFCPostCommentViewController
        controller.post = post
        vc.pushViewController(controller, animated: true)
        return controller
    }
}

extension NFCPostCommentViewController:NFCCommentInputViewDelegate{
    func commentInputViewDidClickSend(sender: NFCCommentInputView, textField: UITextField) {
        let cmt = textField.text
        if !String.isNullOrWhiteSpace(cmt) {
            textField.text = nil
            commentInputView.inputTextField.resignFirstResponder()
            responseTextField.resignFirstResponder()
            let hud = self.showActivityHud()
            NFCPostManager.instance.newPostComment(self.post.pid, comment: cmt!, callback: { (posted,msg) in
                hud.hideAnimated(true)
                if posted{
                    self.playCheckMark(){
                        let ncomment = NFCPostComment()
                        ncomment.cmt = cmt
                        ncomment.pster = ServiceContainer.getUserService().myProfile.userId
                        ncomment.psterNk = "ME".localizedString()
                        ncomment.ts = Int64(NSDate().timeIntervalSince1970)
                        self.post.cmtCnt += 1
                        self.comments.append([ncomment])
                    }
                }else{
                    self.playCrossMark(msg)
                }
            })
        }else{
            self.playToast("INPUT_COMMENT_CONTENT".niceFaceClubString)
        }
        
    }
}

extension NFCPostCommentViewController:UITableViewDataSource,UITableViewDelegate{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NFCPostCommentCell.reuseId, forIndexPath: indexPath) as! NFCPostCommentCell
        let cmd = comments[indexPath.section][indexPath.row]
        cell.commentLabel.text = cmd.cmt
        cell.postInfoLabel.text = "By \(cmd.psterNk)"
        return cell
    }
}
