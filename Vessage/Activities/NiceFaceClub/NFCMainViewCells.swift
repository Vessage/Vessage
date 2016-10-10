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
import ImageSlideshow

class NFCMainInfoCell: UITableViewCell {
    static let reuseId = "NFCMainInfoCell"
    
    @IBOutlet weak var nextTipsLabel: UILabel!
    @IBOutlet weak var nextImageView: UIImageView!
    @IBOutlet weak var announcementLabel: UILabel!
    @IBOutlet weak var newCmtLabel: LTMorphingLabel!
    @IBOutlet weak var newLikesLabel: LTMorphingLabel!
}

class NFCPostCell: UITableViewCell {
    static let reuseId = "NFCPostCell"
    
    @IBOutlet weak var godPanel: UIView!{
        didSet{
            godPanel.hidden = !UserSetting.godMode
        }
    }
    
    @IBOutlet weak var memberCardButton: UIButton!
    @IBOutlet weak var likeMarkImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeTipsLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var newCommentButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var imageContentView: UIImageView!{
        didSet{
            imageContentView.userInteractionEnabled = true
            imageContentView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCPostCell.onTapImage(_:))))
        }
    }
    
    @IBOutlet weak var commentTipsLabel: UILabel!
    
    @IBAction func godLikeClick(sender: AnyObject) {
        NFCPostManager.instance.godLikePost(post.pid)
    }
    @IBAction func godBlockMemberClick(sender: AnyObject) {
        NFCPostManager.instance.godBlockMember(post.mbId)
    }
    @IBAction func godRmPostClick(sender: AnyObject) {
        NFCPostManager.instance.godDeletePost(post.pid)
    }
    
    weak var rootController:NFCMainViewController?
    var post:NFCPost!{
        didSet{
            if post != nil {
                let dateString = "\(NSDate(timeIntervalSince1970: post.ts.doubleValue).toFriendlyString()) By \(post.pster)"
                dateLabel?.text = dateString
                self.likeTipsLabel?.text = self.post.lc.friendString
                chatButton.hidden = isSelfPost ? true : !NFCPostManager.instance.likedInCached(post.pid)
                newCommentButton.hidden = isSelfPost ? false : chatButton.hidden
                commentTipsLabel.text = self.post.cmtCnt.friendString
                memberCardButton.hidden = true
            }
        }
    }
    
    private var isSelfPost:Bool{
        if let selfMbId = self.rootController?.profile?.mbId {
            return selfMbId == self.post.mbId
        }
        return false
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        let slideshow = ImageSlideshow()
        slideshow.setImageInputs([ImageSource(image: imageContentView.image!)])
        let ctr = FullScreenSlideshowViewController()
        // called when full-screen VC dismissed and used to set the page to our original slideshow
        ctr.pageSelected = { page in
            slideshow.setScrollViewPage(page, animated: false)
        }
        
        // set the initial page
        ctr.initialImageIndex = slideshow.scrollViewPage
        // set the inputs
        ctr.inputs = slideshow.images
        let slideshowTransitioningDelegate = ZoomAnimatedTransitioningDelegate(slideshowView: slideshow, slideshowController: ctr)
        ctr.transitioningDelegate = slideshowTransitioningDelegate
        self.rootController?.presentViewController(ctr, animated: true, completion: nil)
    }
    
    func updateImage() {
        imageContentView.image = nil
        imageContentView.contentMode = .Center
        if let img = post?.img {
            ServiceContainer.getFileService().setAvatar(imageContentView, iconFileId: img,defaultImage: UIImage(named:"nfc_post_img_bcg")){ suc in
                if suc{
                    self.imageContentView.contentMode = .ScaleAspectFill
                }
            }
        }
        
    }
    
    func playLikeAnimation() {
        likeMarkImage.animationMaxToMin(0.3, maxScale: 1.6, completion: nil)
        likeTipsLabel.text = "+1"
        likeTipsLabel.animationMaxToMin(0.3, maxScale: 1.6) {
            self.likeTipsLabel?.text = self.post.lc.friendString
            if !self.isSelfPost{
                self.chatButton.hidden = false
                self.chatButton.animationMaxToMin(0.2, maxScale: 1.3){
                    self.newCommentButton.hidden = false
                    self.newCommentButton.animationMaxToMin(0.2, maxScale: 1.3){
                        
                    }
                }
            }
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
    }
}

extension NFCPostCell{
    @IBAction func onClickNewComment(sender: AnyObject) {
        NFCPostCommentViewController.showNFCMemberCardAlert(self.rootController!.navigationController!, post: self.post)
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
                    let msg = ["input_text":"NFC_HELLO".niceFaceClubString]
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
            NFCPostManager.instance.likePost(self.post.pid, callback: { (suc) in
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

