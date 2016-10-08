//
//  NFCMainViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/4.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import LTMorphingLabel
import ImageSlideshow

class NFCMainInfoCell: UITableViewCell {
    static let reuseId = "NFCMainInfoCell"
    
    @IBOutlet weak var announcementLabel: UILabel!
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
    
    weak var rootController:NFCMainViewController?
    var post:NFCPost!{
        didSet{
            if post != nil {
                let dateString = "\(NSDate(timeIntervalSince1970: post.ts.doubleValue).toFriendlyString()) By \(post.pster)"
                dateLabel?.text = dateString
                self.likeTipsLabel?.text = self.post.lc.friendString
                chatButton.hidden = !NFCPostManager.instance.likedInCached(post.pid)
                memberCardButton.hidden = true
                newCommentButton.hidden = chatButton.hidden
            }
        }
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
        ServiceContainer.getFileService().setAvatar(imageContentView, iconFileId: post.img,defaultImage: UIImage(named:"nfc_post_img_bcg")){ suc in
            if suc{
                self.imageContentView.contentMode = .ScaleAspectFill
            }
        }
    }
    
    func playLikeAnimation() {
        likeMarkImage.animationMaxToMin(0.3, maxScale: 1.6, completion: nil)
        likeTipsLabel.text = "+1"
        
        likeTipsLabel.animationMaxToMin(0.3, maxScale: 1.6) {
            self.likeTipsLabel?.text = self.post.lc.friendString
            self.chatButton.hidden = false
            self.chatButton.animationMaxToMin(0.2, maxScale: 1.3){
                self.newCommentButton.hidden = false
                self.newCommentButton.animationMaxToMin(0.2, maxScale: 1.3){
                    
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
        NFCPostCommentViewController.showNFCMemberCardAlert(self.rootController!.navigationController!, postId: self.post.pid)
    }
    
    @IBAction func onClickChat(sender: AnyObject) {
        if rootController?.tryShowForbiddenAnymoursAlert() ?? true{
            return
        }
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            let hud = self.rootController?.showAnimationHud()
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
            let hud = self.rootController?.showAnimationHud()
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
    
    @IBAction func onBlackListButtonClick(sender: AnyObject) {
        NFCPostManager.instance.godBlockMember(post.mbId)
    }
    
    @IBAction func onGodLikeButtonClick(sender: AnyObject) {
        NFCPostManager.instance.godLikePost(post.pid)
    }
    
    @IBAction func onClickGodRmPost(sender: AnyObject) {
        NFCPostManager.instance.godDeletePost(post.pid)
    }
}

class NFCMainViewController: UIViewController {
    let nfcLikeCountBaseLimit = 10
    @IBOutlet weak var newMemberButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.tableFooterView = UIView()
        }
    }
    private var profile:UserNiceFaceProfile!
    
    private var posts:[[[NFCPost]]] = [
        [[NFCPost]](),
        [[NFCPost]](),
        [[NFCPost]]()
        ]{
        didSet{
            tableView?.reloadData()
        }
    }
    
    private var listType:Int = 0{
        didSet{
            tableView?.reloadData()
        }
    }
    
    private var boardData:NFCMainBoardData!
    
    private var taskFileMap = [String:FileAccessInfo]()
    
    private var showControllerTimes:Int{
        get{
            return UserSetting.getUserIntValue("ShowNFCMainView")
        }
        set{
            UserSetting.setUserIntValue("ShowNFCMainView", value: newValue)
        }
    }
    
    deinit {
        NFCPostManager.instance.releaseManager();
        debugLog("Deinited:\(self.description)")
    }
}

extension NFCMainViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return posts[listType].count + 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return posts[listType][section - 1].count
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 10
        }
        return 0
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(NFCMainInfoCell.reuseId, forIndexPath: indexPath) as! NFCMainInfoCell
            if (self.boardData?.nlks ?? 0) > 0 {
                cell.newLikesLabel.text = "+\(self.boardData.nlks.friendString)"
            }else{
                cell.newLikesLabel.text = "NO_NEW_LIKES".niceFaceClubString
            }
            
            if listType == NFCPost.typeNewMemberPost {
                cell.announcementLabel.text = String(format: "NEWER_NEED_X_LIKE_TO_JOIN_NFC".niceFaceClubString,nfcLikeCountBaseLimit)
            }else{
                cell.announcementLabel.text = String.isNullOrWhiteSpace(self.boardData?.annc) ? "DEFAULT_NFC_ANC".niceFaceClubString : self.boardData?.annc
            }
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(NFCPostCell.reuseId, forIndexPath: indexPath) as! NFCPostCell
        cell.setSeparatorFullWidth()
        cell.rootController = self
        cell.post = postOfIndexPath(indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? NFCPostCell {
            c.updateImage()
        }
    }
    
    func postOfIndexPath(indexPath:NSIndexPath) -> NFCPost? {
        return posts[listType][indexPath.section - 1][indexPath.row]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        if indexPath.section == 0 {
            if tryShowForbiddenAnymoursAlert() {
                return
            }
            switchListType(NFCPost.typeMyPost)
        }
    }
}

extension NFCMainViewController{
    
    private func shareNFC() {
        ShareHelper.instance.showTellVegeToFriendsAlert(self, message: "SHARE_NICE_FACE_CLUB_MSG".niceFaceClubString, alertMsg: "SHARE_NFC_ALERT_MSG".niceFaceClubString, title: "NFC".niceFaceClubString)
    }
    
    @IBAction func onClickMemberButton(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert(){
            return
        }
        UserSettingViewController.showUserSettingViewController(self.navigationController!)
        //NFCMemberCardAlert.showNFCMemberCardAlert(self, memberId: self.profile.id)
    }
    
    @IBAction func onHomeButtonClick(sender: AnyObject) {
        switchListType(NFCPost.typeNormalPost)
    }
    
    @IBAction func newPostButton(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert(){
            return
        }
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) { 
            let imagePicker = UIImagePickerController.showUIImagePickerAlert(self, title: "NFC".niceFaceClubString, message: "POST_NEW_SHARE".niceFaceClubString)
            imagePicker.delegate = self
        }
    }
    
    @IBAction func onNewMemberButtonClick(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert(){
            return
        }
        switchListType(NFCPost.typeNewMemberPost)
    }
    
    
    private func tryShowForbiddenAnymoursAlert() -> Bool{
        if !NiceFaceClubManager.instance.isValidatedMember {
            self.showAlert("NFC".niceFaceClubString, msg: "NFC_ANONYMOUS_TIPS".niceFaceClubString,actions: [ALERT_ACTION_I_SEE])
            return true
        }
        return false
    }
    
    
}

extension NFCMainViewController:UIImagePickerControllerDelegate,ProgressTaskDelegate{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?){
        picker.dismissViewControllerAnimated(true) {
            let avatarImage = image.scaleToWidthOf(600, quality: 0.8)
            
            let fService = ServiceContainer.getService(FileService)
            let imageData = UIImageJPEGRepresentation(avatarImage,1)
            let localPath = fService.createLocalStoreFileName(FileType.Image)
            
            if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
            {
                fService.sendFileToAliOSS(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                    if let fk = fileKey
                    {
                        self.taskFileMap[taskId] = fk
                    }
                })
            }else
            {
                self.playToast("POST_NEW_ERROR".localizedString())
            }
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let fileKey = taskFileMap.removeValueForKey(taskIdentifier)
        {
            NFCPostManager.instance.newPost(fileKey.fileId, callback: { (post) in
                if let p = post{
                    self.playCheckMark(){
                        self.posts[NFCPost.typeNormalPost].append([p])
                        self.tableView.scrollsToTop = true
                    }
                }else{
                    self.playCrossMark("POST_NEW_ERROR".localizedString())
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        taskFileMap.removeValueForKey(taskIdentifier)
        self.playCrossMark("POST_NEW_ERROR".localizedString())
    }
}

extension NFCMainViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        NFCPostManager.instance.initManager()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.hidden = true
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(NFCMainViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(NFCMainViewController.mjFooterRefresh(_:)))
        homeButton.superview?.superview?.superview?.hidden = true
    }
    
    func mjFooterRefresh(a:AnyObject?) {
        refreshPosts()
    }
    
    func mjHeaderRefresh(a:AnyObject?) {
        self.posts[listType].removeAll()
        self.refreshPosts()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.profile != nil {
            start()
        }else{
            initMyProfile()
        }
    }
}

extension NFCMainViewController{
    
    private func showViews(){
        self.tableView.hidden = false
        homeButton.superview?.superview?.superview?.hidden = false
    }
    
    private func refreshPosts() {
        
        let lastPost = posts[listType].last?.last
        let ts = lastPost?.ts ?? 0
        if listType == NFCPost.typeNormalPost && lastPost == nil{
            let hud = self.showAnimationHud()
            NFCPostManager.instance.getMainBoardData({ (data) in
                hud.hideAnimated(true)
                self.tableView.mj_header?.endRefreshing()
                if let d = data{
                    self.boardData = d
                    self.newMemberButton.badgeValue = d.nMemCnt > 0 ? d.nMemCnt.friendString : nil
                    if d.posts != nil && d.posts.count > 0{
                        self.posts[NFCPost.typeNormalPost].append(d.posts)
                        self.tryShowShareAlert()
                    }else{
                        self.playToast("NO_POSTS".niceFaceClubString)
                    }
                }else{
                    self.playCrossMark("REFRESH_ERROR".niceFaceClubString)
                }
            })
        }else{
            NFCPostManager.instance.getNFCPosts(listType,startTimeSpan: ts, pageCount: 20, callback: { (posts) in
                self.tableView.mj_footer?.endRefreshing()
                if posts.count > 0{
                    self.posts[self.listType].append(posts)
                }else{
                    self.playToast("NO_POSTS".niceFaceClubString)
                }
            })
        }
    }
    
    func switchListType(type:Int) {
        homeButton?.enabled = type != NFCPost.typeNormalPost
        newMemberButton?.enabled = type != NFCPost.typeNewMemberPost
        self.listType = type
        if posts[listType].count == 0 {
            refreshPosts()
        }
    }
    
    private func anonymousMode(){
        self.profile = UserNiceFaceProfile()
        self.profile.faceId = nil
        self.profile.nick = ""
        self.profile.id = "Anonymous"
        self.profile.score = 6.0
        self.profile.sex = 0
        self.profile.mbAcpt = true
        switchListType(NFCPost.typeNormalPost)
        showViews()
    }
}

extension NFCMainViewController{
    private func initMyProfile(){
        let hud = self.showAnimationHud()
        NiceFaceClubManager.instance.getMyNiceFaceProfile({ (mp) in
            hud.hideAnimated(true)
            if let p = mp{
                self.profile = p
                self.start()
            }else{
                let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                    self.navigationController?.popViewControllerAnimated(true)
                })
                self.showAlert("NICE_FACE_CLUB".niceFaceClubString, msg: "FETCH_YOUR_PROFILE_ERROR".niceFaceClubString, actions: [ok])
            }
        })
    }
    
    private func start(){
        if profile.id != "Anonymous" && (profile.score < NiceFaceClubManager.minScore || profile.mbAcpt == false){
            self.showBenchMarkAlert()
        }else{
            self.switchListType(NFCPost.typeNormalPost)
            self.showViews()
            if self.posts.count == 0 {
                self.refreshPosts()
            }
        }
    }
    
    private func tryShowShareAlert(){
        showControllerTimes += 1
        let sct = showControllerTimes
        if sct == 3 || sct == 9 || sct == 23 || sct == 42 || sct == 60 {
            self.shareNFC()
        }
    }
    
    private func showBenchMarkAlert() {
        let msg = profile.score < NiceFaceClubManager.minScore ? "YOU_NEED_FACE_BENCHMARK".niceFaceClubString : "NEED_LIKE_TO_JOIN_NFC".niceFaceClubString
        let alert = NFCMessageAlert.showNFCMessageAlert(self, title: "NICE_FACE_CLUB".niceFaceClubString, message: msg)
        alert.onTestScoreHandler = { alert in
            alert.dismissViewControllerAnimated(true, completion: {
                self.modifyNiceFace(false)
            })
        }
        
        alert.onAnonymousHandler = { alert in
            self.anonymousMode()
            alert.dismissViewControllerAnimated(true, completion: nil)
            
        }
        alert.onCloseHandler = { alert in
            alert.dismissViewControllerAnimated(true, completion: {
                self.navigationController?.popViewControllerAnimated(true)
            })
        }
    }
    
    private func modifyNiceFace(aleadyMember:Bool = true){
        let controller = SetupNiceFaceViewController.instanceFromStoryBoard()
        self.presentViewController(controller, animated: true){
            if aleadyMember{
                NFCMessageAlert.showNFCMessageAlert(controller, title: "NICE_FACE_CLUB".niceFaceClubString, message: "UPDATE_YOUR_NICE_FACE".niceFaceClubString)
            }
        }
    }
}
