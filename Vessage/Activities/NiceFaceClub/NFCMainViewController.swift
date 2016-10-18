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
import MBProgressHUD

//MARK: NFCMainViewController
class NFCMainViewController: UIViewController {
    let nfcLikeCountBaseLimit = 10
    let postPageCount = 20
    @IBOutlet weak var newMemberButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.tableFooterView = UIView()
        }
    }
    private var postingAnimationImageView:UIImageView!
    @IBOutlet weak var postingIndicator: UIActivityIndicatorView!
    private(set) var profile:UserNiceFaceProfile!
    
    private var posts:[[[NFCPost]]] = [[[NFCPost]](),[[NFCPost]](),[[NFCPost]]()]
    
    private var posting = [NFCPost](){
        didSet{
            if posting.count > 0 {
                postingIndicator?.hidden = false
                postingIndicator?.startAnimating()
            }else{
                postingIndicator?.stopAnimating()
            }
        }
    }
    
    private var listTableViewOffset = [CGPointZero,CGPointZero,CGPointZero]
    
    private var listType:Int = 0{
        didSet{
            if listType != oldValue {
                tableView?.mj_footer?.resetNoMoreData()
                listTableViewOffset[oldValue] = tableView.contentOffset
                tableView?.setContentOffset(listTableViewOffset[listType], animated: false)
                dispatch_main_queue_after(100, handler: { 
                    self.tableView?.reloadData()
                })
            }
            
        }
    }
    
    private var boardData:NFCMainBoardData!
    
    private var showControllerTimes:Int{
        get{
            return UserSetting.getUserIntValue("ShowNFCMainView")
        }
        set{
            UserSetting.setUserIntValue("ShowNFCMainView", value: newValue)
        }
    }
    
    private var tipsLabel:UILabel!{
        didSet{
            tipsLabel.text = nil
            tipsLabel.clipsToBounds = true
            tipsLabel.layer.cornerRadius = 8
            tipsLabel.textColor = UIColor.orangeColor()
            tipsLabel.textAlignment = .Center
            tipsLabel.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.6)
        }
    }
    
    deinit {
        NFCPostManager.instance.releaseManager();
        debugLog("Deinited:\(self.description)")
    }
}

//MARK: Life Circle
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
        tableView?.mj_footer.automaticallyHidden = true
        homeButton.superview?.superview?.superview?.hidden = true
        MobClick.event("NFC_Login")
    }
    
    func mjFooterRefresh(a:AnyObject?) {
        refreshPosts()
    }
    
    func mjHeaderRefresh(a:AnyObject?) {
        tableView?.mj_header?.endRefreshing()
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

//MARK: actions
extension NFCMainViewController{
    
    private func shareNFC() {
        ShareHelper.instance.showTellVegeToFriendsAlert(self, message: "SHARE_NICE_FACE_CLUB_MSG".niceFaceClubString, alertMsg: "SHARE_NFC_ALERT_MSG".niceFaceClubString, title: "NFC".niceFaceClubString)
    }
    
    @IBAction func onClickMemberButton(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert(){
            return
        }
        let modifyNiceFace = UIAlertAction(title: "MODIFY_NICE_FACE".niceFaceClubString, style: .Default) { (ac) in
            self.modifyNiceFace()
        }
        let memberCard = UIAlertAction(title: "MEMBER_CARD".niceFaceClubString, style: .Default) { (ac) in
            NFCMemberCardAlert.showNFCMemberCardAlert(self, memberId: self.profile.mbId)
        }
        let userSettig = UIAlertAction(title: "UPDATE_MEMBER_PROFILE".niceFaceClubString, style: .Default) { (ac) in
            UserSettingViewController.showUserSettingViewController(self.navigationController!)
        }
        let alert = UIAlertController(title: "MEMBER_PROFILE".niceFaceClubString, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(modifyNiceFace)
        alert.addAction(userSettig)
        alert.addAction(memberCard)
        alert.addAction(ALERT_ACTION_CANCEL)
        self.showAlert(alert)
        
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
    
    
    func tryShowForbiddenAnymoursAlert() -> Bool{
        if !NiceFaceClubManager.instance.isValidatedMember {
            self.showAlert("NFC".niceFaceClubString, msg: "NFC_ANONYMOUS_TIPS".niceFaceClubString,actions: [ALERT_ACTION_I_SEE])
            return true
        }
        return false
    }
    
    func playPostingIndicatorAnimation(img:UIImage?) {
        if img == nil {
            return
        }
        if nil == postingAnimationImageView {
            self.postingAnimationImageView = UIImageView()
            self.postingAnimationImageView.contentMode = .ScaleAspectFill
        }
        let width = self.view.frame.width - 20
        let height = width
        let y = (self.view.frame.height - height) / 2
        let frame = CGRectMake(0 - width, y, width, height)
        self.postingAnimationImageView.frame = frame
        self.postingAnimationImageView.image = img
        self.view.addSubview(postingAnimationImageView)
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        animation.fromValue = NSValue(CGPoint: CGPointMake(self.view.frame.width / 2, self.view.frame.height / 2))
        animation.toValue = NSValue(CGPoint: CGPointMake(0 + 36, self.view.frame.height - 24))
        animation.duration = 0.6
        
        let animation2 = CABasicAnimation(keyPath: "transform.scale")
        animation2.fromValue = CGFloat(1)
        animation2.toValue = CGFloat(0.01)
        animation2.duration = 0.6
        animation2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        postingAnimationImageView.layer.addAnimation(animation2, forKey: "postingScale")
        self.postingAnimationImageView.hidden = false
        UIAnimationHelper.playAnimation(self.postingAnimationImageView, animation: animation, key: "movePostingImg") {
            self.postingAnimationImageView.hidden = true
            self.postingAnimationImageView.removeFromSuperview()
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
        let ts = lastPost?.ts ?? Int64(NSDate().timeIntervalSince1970 * 1000)
        let hud:MBProgressHUD? = lastPost == nil ? self.showActivityHud() : nil
        if listType == NFCPost.typeNormalPost && lastPost == nil{
            NFCPostManager.instance.getMainBoardData(postPageCount,callback: { (data) in
                hud?.hideAnimated(true)
                if let d = data{
                    self.boardData = d
                    self.newMemberButton.badgeValue = d.nMemCnt > 0 ? d.nMemCnt.friendString : nil
                    if (d.posts?.count ?? 0) > 0{
                        self.posts[NFCPost.typeNormalPost].append(d.posts)
                        self.tryShowShareAlert()
                    }else{
                        self.flashTipsLabel("NO_POSTS".niceFaceClubString)
                    }
                    
                }else{
                    self.playCrossMark("REFRESH_ERROR".niceFaceClubString)
                }
                self.setMJFooter()
                self.tableView?.reloadData()
            })
        }else{
            NFCPostManager.instance.getNFCPosts(listType,startTimeSpan: ts, pageCount: postPageCount, callback: { (posts) in
                hud?.hideAnimated(true)
                if posts.count > 0{
                    self.posts[self.listType].append(posts)
                }else{
                    self.flashTipsLabel("NO_POSTS".niceFaceClubString)
                }
                self.setMJFooter()
                self.tableView?.reloadData()
            })
        }
    }
    
    private func setMJFooter(){
        if let cnt = posts[listType].last?.count{
            if cnt > 0 && cnt < postPageCount {
                self.tableView?.mj_footer?.endRefreshingWithNoMoreData()
            }else{
                self.tableView?.mj_footer?.endRefreshing()
            }
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
        self.profile.nick = ServiceContainer.getUserService().myProfile.nickName
        self.profile.id = NiceFaceClubManager.AnonymousProfileId
        self.profile.score = 6.0
        self.profile.sex = 0
        self.profile.mbAcpt = true
        switchListType(NFCPost.typeNormalPost)
        showViews()
    }
}

extension NFCMainViewController{
    private func initMyProfile(){
        let hud = self.showActivityHud()
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

extension NFCMainViewController{
    private func flashTipsLabel(msg:String){
        
        if tipsLabel == nil {
            tipsLabel = UILabel()
        }
        self.tipsLabel.text = msg
        self.tipsLabel.sizeToFit()
        let x = self.view.frame.width / 2
        let y = self.tableView.frame.origin.y + self.tableView.frame.height - 16
        self.tipsLabel.center = CGPointMake(x, y)
        self.view.addSubview(self.tipsLabel)
        UIAnimationHelper.flashView(self.tipsLabel, duration: 0.6, autoStop: true, stopAfterMs: 3600){
            self.tipsLabel.removeFromSuperview()
        }
    }
}

//MARK: UITableViewDelegate
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(NFCMainInfoCell.reuseId, forIndexPath: indexPath) as! NFCMainInfoCell
            cell.newLikesLabel.text = "+\(self.boardData?.nlks.friendString ?? "0")"
            cell.newCmtLabel.text = "+\(self.boardData?.ncmt.friendString ?? "0")"
            cell.nextImageView.hidden = listType == NFCPost.typeMyPost
            cell.nextTipsLabel.hidden = cell.nextImageView.hidden
            cell.delegate = self
            switch listType {
            case NFCPost.typeMyPost:
                cell.announcementLabel.text = "MY_NFC_POST_WALL".niceFaceClubString
            case NFCPost.typeNewMemberPost:
                cell.announcementLabel.text = String.isNullOrWhiteSpace(self.boardData?.newMemAnnc) ? String(format: "NEWER_NEED_X_LIKE_TO_JOIN_NFC".niceFaceClubString,nfcLikeCountBaseLimit) : self.boardData?.newMemAnnc
            default:
                cell.announcementLabel.text = String.isNullOrWhiteSpace(self.boardData?.annc) ? "DEFAULT_NFC_ANC".niceFaceClubString : self.boardData?.annc
            }
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(NFCPostCell.reuseId, forIndexPath: indexPath) as! NFCPostCell
        if let p = postOfIndexPath(indexPath) {
            cell.setSeparatorFullWidth()
            cell.rootController = self
            cell.post = p
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? NFCPostCell {
            c.updateImage()
        }
    }
    
    func postOfIndexPath(indexPath:NSIndexPath) -> NFCPost? {
        if posts[listType].count >= indexPath.section && posts[listType][indexPath.section - 1].count > indexPath.row{
            return posts[listType][indexPath.section - 1][indexPath.row]
        }
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        if indexPath.section != 0 {
            if let post = postOfIndexPath(indexPath){
                NFCPostCommentViewController.showNFCMemberCardAlert(self.navigationController!, post: post)
            }
        }
    }
}

//MARK: NFCMainInfoCellDelegate
extension NFCMainViewController:NFCMainInfoCellDelegate{
    func nfcMainInfoCellDidClickMyPosts(sender:UIView,cell:NFCMainInfoCell) {
        if tryShowForbiddenAnymoursAlert() {
            return
        }
        cell.nextImageView.animationMaxToMin(0.1, maxScale: 1.2) {
            self.switchListType(NFCPost.typeMyPost)
        }
    }
    
    func nfcMainInfoCellDidClickNewLikes(sender:UIView,cell:NFCMainInfoCell) {
        if tryShowForbiddenAnymoursAlert() {
            return
        }
        cell.likeImageView.animationMaxToMin(0.1, maxScale: 1.2) {
            if let cnt = self.boardData?.nlks{
                self.boardData?.nlks = 0
                let ctr = NFCReceivedLikeViewController.instanceFromStoryBoard()
                self.navigationController?.pushViewController(ctr, animated: true)
                ctr.loadInitLikes(cnt == 0 ? 10 : cnt)
            }
        }
    }
    
    func nfcMainInfoCellDidClickNewComment(sender:UIView,cell:NFCMainInfoCell) {
        if tryShowForbiddenAnymoursAlert() {
            return
        }
        cell.newCommentImageView.animationMaxToMin(0.1, maxScale: 1.2) {
            if let cnt = self.boardData?.ncmt{
                self.boardData?.ncmt = 0
                let ctr = NFCMyCommentViewController.instanceFromStoryBoard()
                self.navigationController?.pushViewController(ctr, animated: true)
                ctr.loadInitComments(cnt == 0 ? 10 : cnt)
            }
        }
    }
}

//MARK: UIImagePickerControllerDelegate
extension NFCMainViewController:UIImagePickerControllerDelegate,ProgressTaskDelegate{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?){
        picker.dismissViewControllerAnimated(true) {
            let imageForSend = image.scaleToWidthOf(600, quality: 0.8)
            
            let fService = ServiceContainer.getService(FileService)
            let imageData = UIImageJPEGRepresentation(imageForSend,1)
            let localPath = PersistentManager.sharedInstance.createTmpFileName(FileType.Image)
            
            if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
            {
                let hud = self.showActivityHud()
                fService.sendFileToAliOSS(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                    hud.hideAnimated(true)
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                    if let fk = fileKey
                    {
                        let post = NFCPost()
                        post.img = fk.fileId
                        post.pid = taskId
                        self.posting.insert(post, atIndex: 0)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.playPostingIndicatorAnimation(imageForSend)
                        })
                    }else{
                        self.playToast("POST_NEW_ERROR".niceFaceClubString)
                    }
                })
            }else
            {
                self.playToast("POST_NEW_ERROR".niceFaceClubString)
            }
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let tmpPost = (posting.filter{$0.pid == taskIdentifier}).first{
            NFCPostManager.instance.newPost(tmpPost.img, callback: { (post) in
                if let p = post{
                    self.playCheckMark(){
                        self.posting.removeElement{$0.pid == tmpPost.pid}
                        self.posts[NFCPost.typeNormalPost].insert([p], atIndex: 0)
                        self.tableView?.setContentOffset(CGPointZero, animated: true)
                        self.tableView?.reloadData()
                    }
                }else{
                    self.playCrossMark("POST_NEW_ERROR".niceFaceClubString)
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        self.posting.removeElement{$0.pid == taskIdentifier}
        self.playCrossMark("POST_NEW_ERROR".localizedString())
    }
}

