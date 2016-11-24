//
//  File.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/17.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh

@objc protocol NFCLikeCellDelegate {
    optional func nfcLikeCellDidClickLikeInfo(sender:UIView,cell:NFCReceivedLikeCell,like:NFCPostLike?)
    optional func nfcLikeCellDidClickImage(sender:UIView,cell:NFCReceivedLikeCell,like:NFCPostLike?)
    optional func nfcLikeCellDidClickPoster(sender:UIView,cell:NFCReceivedLikeCell,like:NFCPostLike?)
}

class NFCReceivedLikeCell: UITableViewCell {
    static let reuseId = "NFCReceivedLikeCell"
    @IBOutlet weak var postImageView: UIImageView!{
        didSet{
            postImageView.contentMode = .ScaleAspectFill
            postImageView.clipsToBounds = true
            postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCReceivedLikeCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var likeUserNickLabel: UILabel!{
        didSet{
            likeUserNickLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCReceivedLikeCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var userInfoLabel: UILabel!{
        didSet{
            userInfoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCReceivedLikeCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var likeInfoLabel: UILabel!{
        didSet{
            likeInfoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCReceivedLikeCell.onTapViews(_:))))
        }
    }
    weak var like:NFCPostLike?
    weak var delegate:NFCLikeCellDelegate?
    func updateCell() {
        if let lk = like{
            userInfoLabel.text = String.isNullOrWhiteSpace(lk.mbId) ? "NFC_ANONYMOUS".niceFaceClubString : "NFC_MEMBER".niceFaceClubString
            likeUserNickLabel.text = lk.nick
            let timeString = lk.getPostDateFriendString()
            likeInfoLabel.text = String(format: "DATE_X_LIKE_YOUR_IMG".niceFaceClubString, timeString)
            ServiceContainer.getFileService().setImage(self.postImageView, iconFileId: lk.img, defaultImage: UIImage(named:"nfc_post_img_bcg"), callback: nil)
        }
    }
    
    func onTapViews(ges:UITapGestureRecognizer) {
        if ges.view == postImageView {
            delegate?.nfcLikeCellDidClickImage?(ges.view!, cell: self, like: like)
        }else if ges.view == likeUserNickLabel || ges.view == userInfoLabel{
            delegate?.nfcLikeCellDidClickPoster?(ges.view!, cell: self, like: like)
        }else if ges.view == likeInfoLabel{
            delegate?.nfcLikeCellDidClickLikeInfo?(ges.view!, cell: self, like: like)
        }
    }
}

class NFCReceivedLikeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var likes = [[NFCPostLike]]()
    private var initCount = 0
    private var userService = ServiceContainer.getUserService()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor(hexString: "#f6f6f6")
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(NFCReceivedLikeViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(NFCReceivedLikeViewController.mjFooterRefresh(_:)))
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func loadInitLikes(count:Int) {
        initCount = count
        likes.removeAll()
        let hud = self.showActivityHud()
        NFCPostManager.instance.getMyReceivedLikes(DateHelper.UnixTimeSpanTotalMilliseconds, cnt: count) { (likes) in
            hud.hideAnimated(true)
            if let lks = likes{
                self.likes.append(lks)
                self.tableView.reloadData()
            }
        }
    }
    
    func mjFooterRefresh(a:AnyObject?) {
        if let last = likes.last?.last{
            NFCPostManager.instance.getMyReceivedLikes(last.ts, cnt: 20, callback: { (likes) in
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
    
    func mjHeaderRefresh(a:AnyObject?) {
        tableView.mj_header.endRefreshing()
        if self.likes.count == 0 {
            loadInitLikes(initCount)
        }
    }
    
    static func instanceFromStoryBoard() -> NFCReceivedLikeViewController{
        let ctr = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCReceivedLikeViewController") as! NFCReceivedLikeViewController
        return ctr
    }
}

//MARL:NFCLikeCellDelegate
extension NFCReceivedLikeViewController:NFCLikeCellDelegate{
    func nfcLikeCellDidClickImage(sender: UIView, cell: NFCReceivedLikeCell, like: NFCPostLike?) {
        if let imgv = sender as? UIImageView{
            imgv.slideShowFullScreen(self)
        }
    }
    
    func nfcLikeCellDidClickPoster(sender: UIView, cell: NFCReceivedLikeCell, like: NFCPostLike?) {
        if String.isNullOrWhiteSpace(like?.mbId){
            if let userId = like?.usrId{
                let delegate = UserProfileViewControllerDelegateOpenConversation()
                UserProfileViewController.showUserProfileViewController(self, userId: userId,delegate: delegate)
            }
            
        }else{
            NFCMemberCardAlert.showNFCMemberCardAlert(self, memberId: like!.mbId)
        }
    }
    
    func nfcLikeCellDidClickLikeInfo(sender: UIView, cell: NFCReceivedLikeCell, like: NFCPostLike?) {
        nfcLikeCellDidClickPoster(sender, cell: cell, like: like)
    }
}

//MARK:TableView Delegate
extension NFCReceivedLikeViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return likes.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likes[section].count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? NFCReceivedLikeCell{
            c.updateCell()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NFCReceivedLikeCell.reuseId, forIndexPath: indexPath) as! NFCReceivedLikeCell
        let like = likes[indexPath.section][indexPath.row]
        if let noteName = userService.getUserNotedNameIfExists(like.usrId) {
            like.nick = noteName
        }
        
        cell.like = like
        cell.delegate = self
        return cell
    }
}
