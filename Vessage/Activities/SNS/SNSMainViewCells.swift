//
//  SNSMainViewCells.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/9.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import LTMorphingLabel
import EVReflection

@objc protocol SNSMainInfoCellDelegate {
    optional func snsMainInfoCellDidClickNewComment(sender:UIView,cell:SNSMainInfoCell)
    optional func snsMainInfoCellDidClickNewLikes(sender:UIView,cell:SNSMainInfoCell)
}

class SNSMainInfoCell: UITableViewCell {
    static let reuseId = "SNSMainInfoCell"
    weak var delegate:SNSMainInfoCellDelegate?

    @IBOutlet weak var announcementLabel: UILabel!
    @IBOutlet weak var newCommentImageView: UIImageView!{
        didSet{
            newCommentImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(SNSMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var newCmtLabel: LTMorphingLabel!{
        didSet{
            newCmtLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(SNSMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var likeImageView: UIImageView!{
        didSet{
            likeImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(SNSMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var newLikesLabel: LTMorphingLabel!{
        didSet{
            newLikesLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(SNSMainInfoCell.onTapViews(_:))))
        }
    }
    
    func onTapViews(a:UITapGestureRecognizer) {
        if a.view == newCmtLabel || a.view == newCommentImageView {
            delegate?.snsMainInfoCellDidClickNewComment?(a.view!,cell:self)
        }else if a.view == newLikesLabel || a.view == likeImageView{
            delegate?.snsMainInfoCellDidClickNewLikes?(a.view!,cell:self)
        }
    }
}

class SNSPostCell: UITableViewCell {
    static let reuseId = "SNSPostCell"
    
    @IBOutlet weak var godPanel: UIView!{
        didSet{
            godPanel.hidden = !UserSetting.godMode
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView?.layoutIfNeeded()
            avatarImageView?.layer.cornerRadius = avatarImageView.frame.height / 2
        }
    }
    @IBOutlet weak var textContentLabel: UILabel!
    @IBOutlet weak var likeMarkImage: UIImageView!
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var likeTipsLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var newCommentButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var imageContentView: UIImageView!{
        didSet{
            imageContentView.userInteractionEnabled = true
            imageContentView.clipsToBounds = true
            imageContentView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSPostCell.onTapImage(_:))))
        }
    }
    @IBOutlet weak var commentTipsLabel: UILabel!
    
    weak var rootController:SNSMainViewController?
    var post:SNSPost!{
        didSet{
            
        }
    }
    
    private var isSelfPost:Bool{
        return UserSetting.userId == self.post.usrId
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        if let vc = self.rootController{
            self.imageContentView.slideShowFullScreen(vc)
        }
    }
    
    func updateCell() {
        if post != nil {
            let nick = rootController?.userService.getUserNotedNameIfExists(post.usrId) ?? post.pster ?? "UNKNOW_NAME".localizedString()
            let postInfo = "\(nick)\n\(post.getPostDateFriendString())"
            postInfoLabel?.text = postInfo
            self.likeTipsLabel?.text = self.post.lc.friendString
            chatButton.hidden = isSelfPost ? true : !SNSPostManager.instance.likedInCached(post.pid)
            newCommentButton.hidden = isSelfPost ? false : chatButton.hidden
            commentTipsLabel.text = self.post.cmtCnt.friendString
            textContentLabel?.text = nil
            if let json = self.post?.body{
                let dict = EVReflection.dictionaryFromJson(json)
                if let txt = dict["txt"] as? String{
                    textContentLabel?.text = txt
                }
            }
            updateImage()
        }
    }
    
    private func updateImage() {
        
        if let usrId = self.post.usrId,let user = rootController?.userService.getCachedUserProfile(usrId){
            let defaultAvatar = user.accountId != nil ? getDefaultAvatar(user.accountId) : UIImage(named:"vg_smile")
            ServiceContainer.getFileService().setImage(avatarImageView, iconFileId: user.avatar,defaultImage: defaultAvatar)
        }else{
            avatarImageView.image = UIImage(named:"vg_smile")
        }
        
        let defaultBcg = UIImage(named:"nfc_post_img_bcg")
        imageContentView.contentMode = .Center
        if let img = post?.img {
            ServiceContainer.getFileService().setImage(imageContentView, iconFileId: img,defaultImage: defaultBcg){ suc in
                if suc{
                    self.imageContentView.contentMode = .ScaleAspectFill
                }
            }
        }else{
            imageContentView.image = defaultBcg
        }
        
    }
    
    func playLikeAnimation() {
        likeMarkImage.animationMaxToMin(0.2, maxScale: 1.6, completion: nil)
        likeTipsLabel.text = "+1"
        likeTipsLabel.animationMaxToMin(0.2, maxScale: 1.6) {
            self.likeTipsLabel?.text = self.post.lc.friendString
            if !self.isSelfPost{
                self.chatButton.hidden = false
                self.chatButton.animationMaxToMin(0.1, maxScale: 1.3){
                    self.newCommentButton.hidden = false
                    self.newCommentButton.animationMaxToMin(0.1, maxScale: 1.3){
                    }
                }
            }
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
    }
}

extension SNSPostCell{
    
    @IBAction func onClickMore(sender: AnyObject) {
        let alert = UIAlertController.create(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if isSelfPost {
            let ac = UIAlertAction(title: "DELETE_POST".SNSString, style: .Default, handler: { (ac) in
                let dtPst = UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (ac) in
                    let hud = self.rootController!.showActivityHud()
                    SNSPostManager.instance.deletePost(self.post.pid, callback: { (suc) in
                        hud.hideAnimated(true)
                        if suc{
                            self.rootController?.playCheckMark(){
                                self.rootController?.removePost(self.post.pid)
                            }
                        }else{
                            self.rootController?.playCrossMark()
                        }
                    })
                })
                self.rootController!.showAlert("DELETE_POST".SNSString, msg: "SURE_DELETE_POST".SNSString, actions: [dtPst,ALERT_ACTION_CANCEL])
                
            })
            alert.addAction(ac)
        }else{
            let ac = UIAlertAction(title: "REPORT_POST".SNSString, style: .Default, handler: { (ac) in
                
                let rpPst = UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (ac) in
                    let hud = self.rootController!.showActivityHud()
                    SNSPostManager.instance.reportObjectionablePost(self.post.pid, callback: { (suc) in
                        hud.hideAnimated(true)
                        if suc{
                            self.rootController?.playCheckMark()
                        }else{
                            self.rootController?.playCrossMark()
                        }
                        
                    })
                })
                self.rootController!.showAlert("REPORT_POST".SNSString, msg: "SURE_REPORT_POST".SNSString, actions: [rpPst,ALERT_ACTION_CANCEL])
                
            })
            alert.addAction(ac)
        }
        alert.addAction(ALERT_ACTION_CANCEL)
        self.rootController!.showAlert(alert)
    }
    
    @IBAction func onClickNewComment(sender: AnyObject) {
        SNSPostCommentViewController.showPostCommentViewController(self.rootController!.navigationController!, post: self.post).delegate = self
    }
    
    @IBAction func onClickChat(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            ConversationViewController.showConversationViewController(self.rootController!.navigationController!, userId: self.post.usrId)
        }
    }
    
    @IBAction func onClickLike(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            if SNSPostManager.instance.likedInCached(self.post.pid){
                self.likeMarkImage.animationMaxToMin(0.3, maxScale: 1.6, completion: nil)
                return;
            }
            let hud = self.rootController?.showActivityHud()
            SNSPostManager.instance.likePost(self.post.pid, callback: { (suc) in
                hud?.hideAnimated(true)
                if(suc){
                    self.post.lc += 1
                    self.playLikeAnimation()
                }else{
                    self.rootController?.playCrossMark("LIKE_POST_OP_ERROR".SNSString)
                }
            })
        }
    }
    
}

//MARK: SNSCommentViewControllerDelegate
extension SNSPostCell:SNSCommentViewControllerDelegate{
    func snsCommentController(sender: SNSPostCommentViewController, didPostNewComment newComment: SNSPostComment, post: SNSPost) {
        if post.pid == self.post.pid {
            self.commentTipsLabel.text = post.cmtCnt.friendString
        }
    }
}

//MARK: God Methods
extension SNSPostCell{
    @IBAction func godLikeClick(sender: AnyObject) {
        let hud = self.rootController?.showActivityHud()
        SNSPostManager.instance.godLikePost(post.pid){ suc in
            hud?.hideAnimated(true)
            suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
        }
    }
    
    @IBAction func godBlockMemberClick(sender: AnyObject){
        let ac = UIAlertAction(title: "Yes", style: .Default) { (a) in
            let hud = self.rootController?.showActivityHud()
            SNSPostManager.instance.godBlockMember(self.post.usrId) { suc in
                hud?.hideAnimated(true)
                suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
            }
        }
        self.rootController?.showAlert("Block Member", msg: "Block This User Forever?", actions: [ac,ALERT_ACTION_CANCEL])
        
    }
    
    @IBAction func godRmPostClick(sender: AnyObject){
        let ac = UIAlertAction(title: "Yes", style: .Default) { (a) in
            let hud = self.rootController?.showActivityHud()
            SNSPostManager.instance.godDeletePost(self.post.pid) { suc in
                hud?.hideAnimated(true)
                suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
            }
        }
        self.rootController?.showAlert("Remove Post", msg: "Remove This Post Forever?", actions: [ac,ALERT_ACTION_CANCEL])
    }
    
}
