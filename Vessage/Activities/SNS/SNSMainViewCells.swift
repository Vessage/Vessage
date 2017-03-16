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
            avatarImageView?.layer.borderWidth = 0.2
            avatarImageView?.layer.borderColor = UIColor.lightGrayColor().CGColor
        }
    }
    @IBOutlet weak var textContentLabel: UILabel!
    @IBOutlet weak var likeMarkImage: UIImageView!
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var extraInfoLabel: UILabel!
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
            updateCell()
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
    
    private func updateCell() {
        if post != nil {
            let nick = rootController?.userService.getUserNotedNameIfExists(post.usrId) ?? post.pster ?? "UNKNOW_NAME".localizedString()
            postInfoLabel?.text = nick
            
            updateExtraInfo()
            
            self.likeTipsLabel?.text = self.post.lc.friendString
            chatButton.hidden = isSelfPost
            newCommentButton.hidden = false
            commentTipsLabel.text = self.post.cmtCnt.friendString
            textContentLabel?.text = nil
            if let json = self.post?.body{
                let dict = EVReflection.dictionaryFromJson(json)
                if let txt = dict["txt"] as? String{
                    textContentLabel?.text = txt
                }
            }
            measureImageContent()
        }
    }
    
    private func updateExtraInfo(){
        if post.st == SNSPost.statePrivate {
            extraInfoLabel?.text = "\(post.getPostDateFriendString()) \("PRIVATE".SNSString)"
        }else if post.atpv > 0{
            extraInfoLabel?.text = "\(post.getPostDateFriendString()) \("AT_PRIVATE".SNSString)"
        }else{
            extraInfoLabel?.text = post.getPostDateFriendString()
        }
    }
    
    private func measureImageContent() {
        let hiddenImageContent = post?.img == nil
        
        if let constraints = self.imageContentView?.constraints {
            let width = hiddenImageContent ? 0 : self.contentView.frame.width
            let height = hiddenImageContent ? 0 : width
            
            for constraint in constraints {
                if constraint.identifier == "imageHeight" {
                    constraint.constant = height
                }else if constraint.identifier == "imageWidth"{
                    constraint.constant = width
                }
            }
        }
        
        
        contentView.setNeedsUpdateConstraints()
        contentView.updateConstraintsIfNeeded()
        
        self.imageContentView?.hidden = hiddenImageContent
        
    }
    
    func updateImage() {
        
        if let usrId = self.post.usrId,let user = rootController?.userService.getCachedUserProfile(usrId){
            let defaultAvatar = user.accountId != nil ? getDefaultAvatar(user.accountId,sex: user.sex) : UIImage(named:"vg_smile")
            ServiceContainer.getFileService().setImage(avatarImageView, iconFileId: user.avatar,defaultImage: defaultAvatar)
        }else{
            avatarImageView.image = UIImage(named:"vg_smile")
        }
        
        imageContentView.contentMode = .Center
        if let img = post?.img {
            let defaultBcg = UIImage(named:"nfc_post_img_bcg")
            ServiceContainer.getFileService().setImage(imageContentView, iconFileId: img,defaultImage: defaultBcg){ suc in
                if suc{
                    self.imageContentView.contentMode = .ScaleAspectFill
                }
            }
        }else{
            imageContentView.image = nil
        }
    }
    
    func playLikeAnimation() {
        likeMarkImage.animationMaxToMin(0.2, maxScale: 1.6, completion: nil)
        likeTipsLabel.text = "+1"
        likeTipsLabel.animationMaxToMin(0.2, maxScale: 1.6) {
            self.likeTipsLabel?.text = self.post.lc.friendString
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
    }
}

extension SNSPostCell{
    
    private func updatePostState(newState:Int) {
        let hud = self.rootController!.showActivityHud()
        SNSPostManager.instance.updatePostState(self.post.pid,state: newState, callback: { (suc) in
            hud.hideAnimated(true)
            if suc{
                self.rootController?.playCheckMark(){
                    if newState < 0{
                        self.post.st = newState
                        self.rootController?.removePost(self.post.pid)
                    }else{
                        self.rootController?.updatePostState(self.post.pid,newState: newState)
                    }
                }
            }else{
                self.rootController?.playCrossMark()
            }
        })
    }
    
    @IBAction func onClickMore(sender: AnyObject) {
        let alert = UIAlertController.create(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if isSelfPost {
            
            
            let ac = UIAlertAction(title: "DELETE_POST".SNSString, style: .Default, handler: { (ac) in
                
                let dtPst = UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (ac) in
                    self.updatePostState(SNSPost.stateRemoved)
                })
                self.rootController!.showAlert("DELETE_POST".SNSString, msg: "SURE_DELETE_POST".SNSString, actions: [dtPst,ALERT_ACTION_CANCEL])
                
            })
            
            if self.post.st == SNSPost.stateNormal{
                let setPrivate = UIAlertAction(title: "SET_POST_PRIVATE".SNSString, style: .Default, handler: { (ac) in
                    self.updatePostState(SNSPost.statePrivate)
                })
                alert.addAction(setPrivate)
                
            }else if self.post.st == SNSPost.statePrivate{
                let setPublic = UIAlertAction(title: "SET_POST_PUBLIC".SNSString, style: .Default, handler: { (ac) in
                    self.updatePostState(SNSPost.stateNormal)
                })
                alert.addAction(setPublic)
            }
            
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
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            SNSPostCommentViewController.showPostCommentViewController(self.rootController!.navigationController!, post: self.post).delegate = self
        }
    }
    
    @IBAction func onClickChat(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            ConversationViewController.showConversationViewController(self.rootController!.navigationController!, userId: self.post.usrId,createByActivityId:SNSPostManager.activityId)
        }
    }
    
    @IBAction func onClickLike(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            if let uid = self.post?.usrId{
                ServiceContainer.getConversationService().expireConversation(uid)
            }
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
