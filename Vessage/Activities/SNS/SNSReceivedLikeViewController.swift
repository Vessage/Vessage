//
//  File.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/17.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh

@objc protocol SNSLikeCellDelegate {
    @objc optional func snsLikeCellDidClickLikeInfo(_ sender:UIView,cell:SNSReceivedLikeCell,like:SNSPostLike?)
    @objc optional func snsLikeCellDidClickImage(_ sender:UIView,cell:SNSReceivedLikeCell,like:SNSPostLike?)
    @objc optional func snsLikeCellDidClickPoster(_ sender:UIView,cell:SNSReceivedLikeCell,like:SNSPostLike?)
}

class SNSReceivedLikeCell: UITableViewCell {
    static let reuseId = "SNSReceivedLikeCell"
    @IBOutlet weak var postImageView: UIImageView!{
        didSet{
            postImageView.contentMode = .scaleAspectFill
            postImageView.clipsToBounds = true
            postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSReceivedLikeCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var likeUserNickLabel: UILabel!{
        didSet{
            likeUserNickLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSReceivedLikeCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var userInfoLabel: UILabel!{
        didSet{
            userInfoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSReceivedLikeCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var likeInfoLabel: UILabel!{
        didSet{
            likeInfoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSReceivedLikeCell.onTapViews(_:))))
        }
    }
    weak var like:SNSPostLike?
    weak var delegate:SNSLikeCellDelegate?
    func updateCell() {
        if let lk = like{
            userInfoLabel.text = nil
            likeUserNickLabel.text = lk.nick
            let timeString = lk.getPostDateFriendString()
            let infoStr = String(format: "DATE_X_LIKE_YOUR_IMG".SNSString, timeString)
            let txtClip = String.isNullOrWhiteSpace(lk.txt) ? "" : "  \(lk.txt!)"
            likeInfoLabel.text = "\(infoStr)\(txtClip)"
            ServiceContainer.getFileService().setImage(self.postImageView, iconFileId: lk.img, defaultImage: UIImage(named:"SNS_post_img_bcg"), callback: nil)
        }
    }
    
    func onTapViews(_ ges:UITapGestureRecognizer) {
        if ges.view == postImageView {
            delegate?.snsLikeCellDidClickImage?(ges.view!, cell: self, like: like)
        }else if ges.view == likeUserNickLabel || ges.view == userInfoLabel{
            delegate?.snsLikeCellDidClickPoster?(ges.view!, cell: self, like: like)
        }else if ges.view == likeInfoLabel{
            delegate?.snsLikeCellDidClickLikeInfo?(ges.view!, cell: self, like: like)
        }
    }
}

class SNSReceivedLikeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    fileprivate var likes = [[SNSPostLike]]()
    fileprivate var initCount = 0
    fileprivate var userService = ServiceContainer.getUserService()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor(hexString: "#f6f6f6")
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(SNSReceivedLikeViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(SNSReceivedLikeViewController.mjFooterRefresh(_:)))
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func loadInitLikes(_ count:Int) {
        initCount = count
        likes.removeAll()
        let hud = self.showActivityHud()
        SNSPostManager.instance.getMyReceivedLikes(DateHelper.UnixTimeSpanTotalMilliseconds, cnt: count) { (likes) in
            hud.hide(animated: true)
            if let lks = likes{
                self.likes.append(lks)
                self.tableView.reloadData()
            }
        }
    }
    
    func mjFooterRefresh(_ a:AnyObject?) {
        if let last = likes.last?.last{
            SNSPostManager.instance.getMyReceivedLikes(last.ts, cnt: 20, callback: { (likes) in
                if let lks = likes{
                    self.likes.append(lks)
                    self.tableView.reloadData()
                    if lks.count < 20{
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
        if self.likes.count == 0 {
            loadInitLikes(initCount)
        }
    }
    
    static func instanceFromStoryBoard() -> SNSReceivedLikeViewController{
        let ctr = instanceFromStoryBoard("SNS", identifier: "SNSReceivedLikeViewController") as! SNSReceivedLikeViewController
        return ctr
    }
}

//MARL:SNSLikeCellDelegate
extension SNSReceivedLikeViewController:SNSLikeCellDelegate{
    func snsLikeCellDidClickImage(_ sender: UIView, cell: SNSReceivedLikeCell, like: SNSPostLike?) {
        if let imgv = sender as? UIImageView{
            imgv.slideShowFullScreen(self)
        }
    }
    
    func snsLikeCellDidClickPoster(_ sender: UIView, cell: SNSReceivedLikeCell, like: SNSPostLike?) {
        if let userId = like?.usrId{
            let delegate = UserProfileViewControllerDelegateOpenConversation()
            UserProfileViewController.showUserProfileViewController(self, userId: userId,delegate: delegate){ controller in
                controller.accountIdHidden = true
                controller.snsButtonEnabled = false
            }
        }
    }
    
    func snsLikeCellDidClickLikeInfo(_ sender: UIView, cell: SNSReceivedLikeCell, like: SNSPostLike?) {
        snsLikeCellDidClickPoster(sender, cell: cell, like: like)
    }
}

//MARK:TableView Delegate
extension SNSReceivedLikeViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return likes.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likes[section].count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let c = cell as? SNSReceivedLikeCell{
            c.updateCell()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SNSReceivedLikeCell.reuseId, for: indexPath) as! SNSReceivedLikeCell
        let like = likes[indexPath.section][indexPath.row]
        if let noteName = userService.getUserNotedNameIfExists(like.usrId) {
            like.nick = noteName
        }
        cell.like = like
        cell.delegate = self
        return cell
    }
}
