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
    optional func SNSLikeCellDidClickLikeInfo(sender:UIView,cell:SNSReceivedLikeCell,like:SNSPostLike?)
    optional func SNSLikeCellDidClickImage(sender:UIView,cell:SNSReceivedLikeCell,like:SNSPostLike?)
    optional func SNSLikeCellDidClickPoster(sender:UIView,cell:SNSReceivedLikeCell,like:SNSPostLike?)
}

class SNSReceivedLikeCell: UITableViewCell {
    static let reuseId = "SNSReceivedLikeCell"
    @IBOutlet weak var postImageView: UIImageView!{
        didSet{
            postImageView.contentMode = .ScaleAspectFill
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
            likeInfoLabel.text = String(format: "DATE_X_LIKE_YOUR_IMG".SNSString, timeString)
            ServiceContainer.getFileService().setImage(self.postImageView, iconFileId: lk.img, defaultImage: UIImage(named:"SNS_post_img_bcg"), callback: nil)
        }
    }
    
    func onTapViews(ges:UITapGestureRecognizer) {
        if ges.view == postImageView {
            delegate?.SNSLikeCellDidClickImage?(ges.view!, cell: self, like: like)
        }else if ges.view == likeUserNickLabel || ges.view == userInfoLabel{
            delegate?.SNSLikeCellDidClickPoster?(ges.view!, cell: self, like: like)
        }else if ges.view == likeInfoLabel{
            delegate?.SNSLikeCellDidClickLikeInfo?(ges.view!, cell: self, like: like)
        }
    }
}

class SNSReceivedLikeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var likes = [[SNSPostLike]]()
    private var initCount = 0
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
    
    func loadInitLikes(count:Int) {
        initCount = count
        likes.removeAll()
        let hud = self.showActivityHud()
        SNSPostManager.instance.getMyReceivedLikes(DateHelper.UnixTimeSpanTotalMilliseconds, cnt: count) { (likes) in
            hud.hideAnimated(true)
            if let lks = likes{
                self.likes.append(lks)
                self.tableView.reloadData()
            }
        }
    }
    
    func mjFooterRefresh(a:AnyObject?) {
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
    
    func mjHeaderRefresh(a:AnyObject?) {
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
    func SNSLikeCellDidClickImage(sender: UIView, cell: SNSReceivedLikeCell, like: SNSPostLike?) {
        if let imgv = sender as? UIImageView{
            imgv.slideShowFullScreen(self)
        }
    }
    
    func SNSLikeCellDidClickPoster(sender: UIView, cell: SNSReceivedLikeCell, like: SNSPostLike?) {
        if let userId = like?.usrId{
            UserProfileViewController.showUserProfileViewController(self, userId: userId)
        }
    }
    
    func SNSLikeCellDidClickLikeInfo(sender: UIView, cell: SNSReceivedLikeCell, like: SNSPostLike?) {
        SNSLikeCellDidClickPoster(sender, cell: cell, like: like)
    }
}

//MARK:TableView Delegate
extension SNSReceivedLikeViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return likes.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likes[section].count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? SNSReceivedLikeCell{
            c.updateCell()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SNSReceivedLikeCell.reuseId, forIndexPath: indexPath) as! SNSReceivedLikeCell
        cell.like = likes[indexPath.section][indexPath.row]
        cell.delegate = self
        return cell
    }
}
