//
//  NFCPostCommentViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class NFCPostCommentCell: UITableViewCell {
    static let reuseId = "NFCPostCommentCell"
    
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
}

class NFCPostCommentViewController: UIViewController {
    
    private var postId:String!
    
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
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = UIColor.lightGrayColor()
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(responseTextField)
        responseTextField.hidden = true
        responseTextField.inputAccessoryView = commentInputView
        commentInputView.delegate = self
    }
    
    @IBAction func onNewCommentClick(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert() {
            return
        }
        responseTextField.becomeFirstResponder()
        commentInputView.inputTextField.becomeFirstResponder()
    }
    
    private func tryShowForbiddenAnymoursAlert() -> Bool{
        if !NiceFaceClubManager.instance.isValidatedMember {
            self.showAlert("NFC".niceFaceClubString, msg: "NFC_ANONYMOUS_TIPS".niceFaceClubString,actions: [ALERT_ACTION_I_SEE])
            return true
        }
        return false
    }
    
    static func showNFCMemberCardAlert(vc:UINavigationController, postId:String) -> NFCPostCommentViewController{
        let controller = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCPostCommentViewController") as! NFCPostCommentViewController
        controller.postId = postId
        vc.pushViewController(controller, animated: true)
        return controller
    }
}

extension NFCPostCommentViewController:NFCCommentInputViewDelegate{
    func commentInputViewDidClickSend(sender: NFCCommentInputView, textField: UITextField) {
        textField.text = nil
        commentInputView.inputTextField.resignFirstResponder()
        responseTextField.resignFirstResponder()
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
