//
//  NFCMainViewCells.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/9.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import LTMorphingLabel
import EVReflection

@objc protocol NFCMainInfoCellDelegate {
    optional func nfcMainInfoCellDidClickNewComment(sender:UIView,cell:NFCMainInfoCell)
    optional func nfcMainInfoCellDidClickNewLikes(sender:UIView,cell:NFCMainInfoCell)
    optional func nfcMainInfoCellDidClickMyPosts(sender:UIView,cell:NFCMainInfoCell)
}

class NFCMainInfoCell: UITableViewCell {
    static let reuseId = "NFCMainInfoCell"
    weak var delegate:NFCMainInfoCellDelegate?
    @IBOutlet weak var nextTipsLabel: UILabel!{
        didSet{
            nextTipsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var nextImageView: UIImageView!{
        didSet{
            nextImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var announcementLabel: UILabel!
    @IBOutlet weak var newCommentImageView: UIImageView!{
        didSet{
            newCommentImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var newCmtLabel: LTMorphingLabel!{
        didSet{
            newCmtLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var likeImageView: UIImageView!{
        didSet{
            likeImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMainInfoCell.onTapViews(_:))))
        }
    }
    @IBOutlet weak var newLikesLabel: LTMorphingLabel!{
        didSet{
            newLikesLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMainInfoCell.onTapViews(_:))))
        }
    }
    
    func onTapViews(a:UITapGestureRecognizer) {
        if a.view == newCmtLabel || a.view == newCommentImageView {
            delegate?.nfcMainInfoCellDidClickNewComment?(a.view!,cell:self)
        }else if a.view == newLikesLabel || a.view == likeImageView{
            delegate?.nfcMainInfoCellDidClickNewLikes?(a.view!,cell:self)
        }else if a.view == nextTipsLabel || a.view == nextImageView{
            delegate?.nfcMainInfoCellDidClickMyPosts?(a.view!,cell:self)
        }
    }
}

class NFCPostCell: UITableViewCell {
    static let reuseId = "NFCPostCell"
    
    @IBOutlet weak var godPanel: UIView!{
        didSet{
            godPanel.hidden = !UserSetting.godMode
        }
    }
    
    @IBOutlet weak var textContentLabel: UILabel!
    @IBOutlet weak var memberCardButton: UIButton!
    @IBOutlet weak var likeMarkImage: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView?.layoutIfNeeded()
            avatarImageView?.layer.cornerRadius = avatarImageView.frame.height / 2
        }
    }
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var likeTipsLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var newCommentButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var imageContentView: UIImageView!{
        didSet{
            imageContentView.layer.borderWidth = 0.6
            imageContentView.layer.borderColor = UIColor.lightGrayColor().CGColor
            imageContentView.userInteractionEnabled = true
            imageContentView.clipsToBounds = true
            imageContentView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCPostCell.onTapImage(_:))))
        }
    }
    @IBOutlet weak var commentTipsLabel: UILabel!
    
    weak var rootController:NFCMainViewController?
    var post:NFCPost!
    
    private var isSelfPost:Bool{
        if let selfMbId = self.rootController?.profile?.mbId {
            return selfMbId == self.post.mbId
        }
        return false
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        if let vc = self.rootController{
            self.imageContentView.slideShowFullScreen(vc)
        }
    }
    
    func updateCell() {
        if post != nil {
            let postInfo = "\(post.pster)\n\(post.getPostDateFriendString())"
            postInfoLabel?.text = postInfo
            self.likeTipsLabel?.text = self.post.lc.friendString
            chatButton.hidden = isSelfPost ? true : !NFCPostManager.instance.likedInCached(post.pid)
            newCommentButton.hidden = isSelfPost ? false : chatButton.hidden
            commentTipsLabel.text = self.post.cmtCnt.friendString
            memberCardButton.hidden = chatButton.hidden
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
        
        let defaultAvatar = UIImage(named:"vg_smile")
        if let avatar = post?.avatar{
            ServiceContainer.getFileService().setImage(avatarImageView, iconFileId: avatar,defaultImage: defaultAvatar)
        }else{
            avatarImageView.image = defaultAvatar
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
                    self.memberCardButton.hidden = false
                    self.memberCardButton.animationMaxToMin(0.1, maxScale: 1.3, completion: { 
                        self.newCommentButton.hidden = false
                        self.newCommentButton.animationMaxToMin(0.1, maxScale: 1.3){
                        }
                    })
                }
            }
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
    }
}

extension NFCPostCell{
    
    @IBAction func onClickMore(sender: AnyObject) {
        let alert = UIAlertController.create(title: nil, message: nil, preferredStyle: .ActionSheet)
        var isPoster = false
        
        if let mbId = NiceFaceClubManager.instance.myNiceFaceProfile.mbId {
            if mbId == post.mbId {
                isPoster = true
            }
        }
        
        if isPoster {
            let ac = UIAlertAction(title: "DELETE_POST".niceFaceClubString, style: .Default, handler: { (ac) in
                let dtPst = UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (ac) in
                    let hud = self.rootController!.showActivityHud()
                    NFCPostManager.instance.deletePost(self.post.pid, callback: { (suc) in
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
                self.rootController!.showAlert("DELETE_POST".niceFaceClubString, msg: "SURE_DELETE_POST".niceFaceClubString, actions: [dtPst,ALERT_ACTION_CANCEL])
                
            })
            alert.addAction(ac)
        }else{
            let ac = UIAlertAction(title: "REPORT_POST".niceFaceClubString, style: .Default, handler: { (ac) in
                
                let rpPst = UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (ac) in
                    let hud = self.rootController!.showActivityHud()
                    NFCPostManager.instance.reportObjectionablePost(self.post.pid, callback: { (suc) in
                        hud.hideAnimated(true)
                        if suc{
                            self.rootController?.playCheckMark()
                        }else{
                            self.rootController?.playCrossMark()
                        }
                        
                    })
                })
                self.rootController!.showAlert("REPORT_POST".niceFaceClubString, msg: "SURE_REPORT_POST".niceFaceClubString, actions: [rpPst,ALERT_ACTION_CANCEL])
                
            })
            alert.addAction(ac)
        }
        alert.addAction(ALERT_ACTION_CANCEL)
        self.rootController!.showAlert(alert)
    }
    
    @IBAction func onClickNewComment(sender: AnyObject) {
        NFCPostCommentViewController.showPostCommentViewController(self.rootController!.navigationController!, post: self.post).delegate = self
    }
    
    @IBAction func onClickChat(sender: AnyObject) {
        if rootController?.tryShowForbiddenAnymoursAlert() ?? true{
            return
        }
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            let hud = self.rootController?.showActivityHud()
            NFCPostManager.instance.chatMember(self.post.mbId, callback: { (userId) in
                hud?.hideAnimated(true)
                if String.isNullOrWhiteSpace(userId){
                    self.rootController?.playCrossMark("NO_MEMBER_USERID_FOUND".niceFaceClubString)
                }else{
                    
                    let msg:[String:AnyObject]? = ServiceContainer.getConversationService().existsConversationOfUserId(userId!) ? nil : ["input_text":"NFC_HELLO".niceFaceClubString]
                    ConversationViewController.showConversationViewController(self.rootController!.navigationController!, userId: userId!,initMessage: msg)
                }
            })
        }
    }
    
    
    @IBAction func onClickCardButton(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            NFCMemberCardAlert.showNFCMemberCardAlert(self.rootController!, memberId: self.post.mbId)
        }
    }
    
    @IBAction func onClickLike(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            if NFCPostManager.instance.likedInCached(self.post.pid){
                self.likeMarkImage.animationMaxToMin(0.3, maxScale: 1.6, completion: nil)
                return;
            }
            let hud = self.rootController?.showActivityHud()
            let profile = self.rootController!.profile
            let memberId = profile.mbId ?? nil
            NFCPostManager.instance.likePost(self.post.pid,mbId: memberId,nick: profile.nick, callback: { (suc) in
                hud?.hideAnimated(true)
                if(suc){
                    self.post.lc += 1
                    self.playLikeAnimation()
                }else{
                    self.rootController?.playCrossMark("LIKE_POST_OP_ERROR".niceFaceClubString)
                }
            })
        }
    }
    
}

//MARK: NFCCommentViewControllerDelegate
extension NFCPostCell:NFCCommentViewControllerDelegate{
    func nfcCommentController(sender: NFCPostCommentViewController, didPostNewComment newComment: NFCPostComment, post: NFCPost) {
        if post.pid == self.post.pid {
            self.commentTipsLabel.text = post.cmtCnt.friendString
        }
    }
}

//MARK: God Methods
extension NFCPostCell{
    @IBAction func godLikeClick(sender: AnyObject) {
        let hud = self.rootController?.showActivityHud()
        NFCPostManager.instance.godLikePost(post.pid){ suc in
            hud?.hideAnimated(true)
            suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
        }
    }
    
    @IBAction func godBlockMemberClick(sender: AnyObject){
        let ac = UIAlertAction(title: "Yes", style: .Default) { (a) in
            let hud = self.rootController?.showActivityHud()
            NFCPostManager.instance.godBlockMember(self.post.mbId) { suc in
                hud?.hideAnimated(true)
                suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
            }
        }
        self.rootController?.showAlert("Block Member", msg: "Block This User Forever?", actions: [ac,ALERT_ACTION_CANCEL])
        
    }
    
    @IBAction func godRmPostClick(sender: AnyObject){
        let ac = UIAlertAction(title: "Yes", style: .Default) { (a) in
            let hud = self.rootController?.showActivityHud()
            NFCPostManager.instance.godDeletePost(self.post.pid) { suc in
                hud?.hideAnimated(true)
                suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
            }
        }
        self.rootController?.showAlert("Remove Post", msg: "Remove This Post Forever?", actions: [ac,ALERT_ACTION_CANCEL])
    }
    
}
