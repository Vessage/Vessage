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
import SDWebImage
import TTTAttributedLabel

@objc protocol SNSMainInfoCellDelegate {
    @objc optional func snsMainInfoCellDidClickNewComment(_ sender:UIView,cell:SNSMainInfoCell)
    @objc optional func snsMainInfoCellDidClickNewLikes(_ sender:UIView,cell:SNSMainInfoCell)
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
    
    func onTapViews(_ a:UITapGestureRecognizer) {
        if a.view == newCmtLabel || a.view == newCommentImageView {
            delegate?.snsMainInfoCellDidClickNewComment?(a.view!,cell:self)
        }else if a.view == newLikesLabel || a.view == likeImageView{
            delegate?.snsMainInfoCellDidClickNewLikes?(a.view!,cell:self)
        }
    }
}

class SNSPostCell: UITableViewCell,TTTAttributedLabelDelegate {
    static let reuseId = "SNSPostCell"
    
    @IBOutlet weak var godPanel: UIView!{
        didSet{
            godPanel.isHidden = !UserSetting.godMode
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView?.layoutIfNeeded()
            avatarImageView?.layer.cornerRadius = avatarImageView.frame.height / 2
            avatarImageView?.layer.borderWidth = 0.2
            avatarImageView?.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    @IBOutlet weak var textContentLabel: TTTAttributedLabel!{
        didSet{
            textContentLabel.delegate = self
            textContentLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        }
    }
    @IBOutlet weak var likeMarkImage: UIImageView!
    @IBOutlet weak var postInfoLabel: UILabel!
    @IBOutlet weak var extraInfoLabel: UILabel!
    @IBOutlet weak var likeTipsLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var newCommentButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var contentContainer: UIView! //containerHeight
    
    @IBOutlet weak var commentTipsLabel: UILabel!
    
    weak var rootController:SNSMainViewController?
    var post:SNSPost!{
        didSet{
            updateCell()
        }
    }
    
    fileprivate var isSelfPost:Bool{
        return UserSetting.userId == self.post.usrId
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let c = rootController{
            SimpleBrowser.openUrl(c, url: url.absoluteString, title: nil)
        }
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        attributedLabel(label, didSelectLinkWith: url)
    }
    
    func onTapImage(_ ges:UITapGestureRecognizer) {
        if let vc = self.rootController,let imgView = ges.view as? UIImageView{
            imgView.slideShowFullScreen(vc)
        }
    }
    
    fileprivate func updateCell() {
        if post != nil {
            let nick = rootController?.userService.getUserNotedNameIfExists(post.usrId) ?? post.pster ?? "UNKNOW_NAME".localizedString()
            postInfoLabel?.text = nick
            
            updateExtraInfo()
            
            self.likeTipsLabel?.text = self.post.lc.friendString
            chatButton.isHidden = isSelfPost
            newCommentButton.isHidden = false
            commentTipsLabel.text = self.post.cmtCnt.friendString
            textContentLabel?.text = nil
            
            self.imgList = [String]()
            if !String.isNullOrWhiteSpace(self.post?.img) {
                imgList.append(self.post.img)
            }
            
            if let json = self.post?.body{
                let dict = EVReflection.dictionaryFromJson(json)
                if let txt = dict["txt"] as? String{
                    textContentLabel?.setTextAndSimplifyUrl(text: txt)
                    textContentLabel?.setNeedsUpdateConstraints()
                    textContentLabel?.updateConstraintsIfNeeded()
                }
                
                if let imgs = dict["imgs"] as? [String] {
                    for img in imgs {
                        if !String.isNullOrWhiteSpace(img) {
                            imgList.append(img)
                        }
                    }
                }
            }
            measureImageContent()
        }
    }
    
    fileprivate func updateExtraInfo(){
        if post.st == SNSPost.statePrivate {
            extraInfoLabel?.text = "\(post.getPostDateFriendString()) \("PRIVATE".SNSString)"
        }else if post.atpv > 0{
            extraInfoLabel?.text = "\(post.getPostDateFriendString()) \("AT_PRIVATE".SNSString)"
        }else{
            extraInfoLabel?.text = post.getPostDateFriendString()
        }
    }
    
    fileprivate var imgList:[String]!
    let defaultBcg = UIImage(named:"nfc_post_img_bcg")
    
    fileprivate func measureImageContent() {
        let hiddenImageContent = imgList.count == 0
        
        var itemWidth = hiddenImageContent ? 0 : self.contentContainer.frame.width
        
        itemWidth = imgList.count == 1 ? itemWidth / 2 : itemWidth / 3
        
        self.contentContainer.removeAllSubviews()

        var x:CGFloat = 0
        var y:CGFloat = 0
        let col = imgList.count == 4 ? 2 : 3
        let span:CGFloat = imgList.count > 1 ? 10 : 0
        
        itemWidth -= span
        
        for i in 0..<imgList.count {
            
            x = CGFloat(i % col) * (itemWidth + span)
            y = CGFloat(i / col) * (itemWidth + span)
            let frame = CGRect(x: x, y: y, width: itemWidth, height: itemWidth)
            let imgView = UIImageView(frame: frame)
            imgView.clipsToBounds = true
            imgView.contentMode = .center
            self.contentContainer.addSubview(imgView)
        }
        
        let contentHeight:CGFloat = y + itemWidth
        self.contentContainer.constraints.filter{$0.identifier == "containerHeight"}.first?.constant = contentHeight
        contentView.setNeedsUpdateConstraints()
        contentView.updateConstraintsIfNeeded()
        
        self.contentContainer.isHidden = hiddenImageContent
        updateImageContents()
    }
    
    fileprivate func onSetedImage(_ imgv:UIImageView){
        imgv.contentMode = .scaleAspectFill
        imgv.isUserInteractionEnabled = true
        imgv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SNSPostCell.onTapImage(_:))))
        
        if self.imgList.count == 1,let size = imgv.image?.size, size.height / size.width < 2{
            let height = imgv.frame.height
            let width = height / size.height * size.width
            imgv.frame.size.width = width
        }
 
    }
    
    fileprivate func updateImageContents() {
        if imgList.count == 0 {
            return
        }else{
            for i in 0..<imgList.count {
                let img = imgList[i]
                let imgv = self.contentContainer.subviews[i] as! UIImageView
                ServiceContainer.getFileService().setImage(imgv, iconFileId: img,defaultImage: defaultBcg){ suc in
                    if suc{
                        self.onSetedImage(imgv)
                    }
                }
            }
        }
    }
    
    func updateImage() {
        
        if let usrId = self.post.usrId,let user = rootController?.userService.getCachedUserProfile(usrId){
            let defaultAvatar = user.accountId != nil ? getDefaultAvatar(user.accountId,sex: user.sex) : UIImage(named:"vg_smile")
            ServiceContainer.getFileService().setImage(avatarImageView, iconFileId: user.avatar,defaultImage: defaultAvatar)
        }else{
            avatarImageView.image = UIImage(named:"vg_smile")
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
    
    fileprivate func updatePostState(_ newState:Int) {
        let hud = self.rootController!.showActivityHud()
        SNSPostManager.instance.updatePostState(self.post.pid,state: newState, callback: { (suc) in
            hud.hide(animated: true)
            if suc{
                if newState < 0{
                    self.post.st = newState
                    self.rootController?.removePost(self.post.pid)
                }else{
                    self.rootController?.updatePostState(self.post.pid,newState: newState)
                }
            }else{
                self.rootController?.playCrossMark()
            }
        })
    }
    
    @IBAction func onClickMore(_ sender: AnyObject) {
        let alert = UIAlertController.create(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if isSelfPost {
            
            
            let ac = UIAlertAction(title: "DELETE_POST".SNSString, style: .default, handler: { (ac) in
                
                let dtPst = UIAlertAction(title: "YES".localizedString(), style: .default, handler: { (ac) in
                    self.updatePostState(SNSPost.stateRemoved)
                })
                self.rootController!.showAlert("DELETE_POST".SNSString, msg: "SURE_DELETE_POST".SNSString, actions: [dtPst,ALERT_ACTION_CANCEL])
                
            })
            
            if self.post.st == SNSPost.stateNormal{
                let setPrivate = UIAlertAction(title: "SET_POST_PRIVATE".SNSString, style: .default, handler: { (ac) in
                    self.updatePostState(SNSPost.statePrivate)
                })
                alert.addAction(setPrivate)
                
            }else if self.post.st == SNSPost.statePrivate{
                let setPublic = UIAlertAction(title: "SET_POST_PUBLIC".SNSString, style: .default, handler: { (ac) in
                    self.updatePostState(SNSPost.stateNormal)
                })
                alert.addAction(setPublic)
            }
            
            alert.addAction(ac)
        }else{
            let ac = UIAlertAction(title: "REPORT_POST".SNSString, style: .default, handler: { (ac) in
                
                let rpPst = UIAlertAction(title: "YES".localizedString(), style: .default, handler: { (ac) in
                    let hud = self.rootController!.showActivityHud()
                    SNSPostManager.instance.reportObjectionablePost(self.post.pid, callback: { (suc) in
                        hud.hide(animated: true)
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
    
    @IBAction func onClickNewComment(_ sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            SNSPostCommentViewController.showPostCommentViewController(self.rootController!.navigationController!, post: self.post).delegate = self
        }
    }
    
    @IBAction func onClickChat(_ sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            ConversationViewController.showConversationViewController(self.rootController!.navigationController!, userId: self.post.usrId,createByActivityId:SNSPostManager.activityId)
        }
    }
    
    @IBAction func onClickLike(_ sender: AnyObject) {
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
                hud?.hide(animated: true)
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
    func snsCommentController(_ sender: SNSPostCommentViewController, didPostNewComment newComment: SNSPostComment, post: SNSPost) {
        if post.pid == self.post.pid {
            self.commentTipsLabel.text = post.cmtCnt.friendString
        }
    }
}

//MARK: God Methods
extension SNSPostCell{
    @IBAction func godLikeClick(_ sender: AnyObject) {
        let hud = self.rootController?.showActivityHud()
        SNSPostManager.instance.godLikePost(post.pid){ suc in
            hud?.hide(animated: true)
            suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
        }
    }
    
    @IBAction func godBlockMemberClick(_ sender: AnyObject){
        let ac = UIAlertAction(title: "Yes", style: .default) { (a) in
            let hud = self.rootController?.showActivityHud()
            SNSPostManager.instance.godBlockMember(self.post.usrId) { suc in
                hud?.hide(animated: true)
                suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
            }
        }
        self.rootController?.showAlert("Block Member", msg: "Block This User Forever?", actions: [ac,ALERT_ACTION_CANCEL])
        
    }
    
    @IBAction func godRmPostClick(_ sender: AnyObject){
        let ac = UIAlertAction(title: "Yes", style: .default) { (a) in
            let hud = self.rootController?.showActivityHud()
            SNSPostManager.instance.godDeletePost(self.post.pid) { suc in
                hud?.hide(animated: true)
                suc ? self.rootController?.playCheckMark() : self.rootController?.playCrossMark()
            }
        }
        self.rootController?.showAlert("Remove Post", msg: "Remove This Post Forever?", actions: [ac,ALERT_ACTION_CANCEL])
    }
    
}
