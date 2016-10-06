//
//  NFCMainViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/4.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh

class NFCPostCell: UITableViewCell {
    static let reuseId = "NFCPostCell"
    @IBOutlet weak var blackListButton: UIButton!{
        didSet{
            blackListButton.hidden = true//!UserSetting.godMode
        }
    }
    
    @IBOutlet weak var godLikeButton: UIButton!{
        didSet{
            godLikeButton.hidden = true//!UserSetting.godMode
        }
    }
    
    @IBOutlet weak var likeMarkImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeTipsLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var imageContentView: UIImageView!
    
    let nfcLikeCountBaseLimit = 10
    
    weak var rootController:NFCMainViewController?
    var post:NFCPost!{
        didSet{
            if post != nil {
                let oldImg = oldValue?.img ?? ""
                if oldImg != post.img {
                    imageContentView.image = nil
                    ServiceContainer.getFileService().setAvatar(imageContentView, iconFileId: post.img)
                }
                let dateString = NSDate(timeIntervalSince1970: post.ts.doubleValue).toFriendlyString()
                dateLabel?.text = dateString
                updateLikeTipsLabel()
                chatButton.hidden = !NFCPostManager.instance.likedInCached(post.pid)
            }
        }
    }
    
    
    
    private func updateLikeTipsLabel(){
        if post.t == NFCPost.typeNewMemberPost && post.lc < nfcLikeCountBaseLimit{
            likeTipsLabel?.text = "\(post.lc.friendString) (\(String(format: "NEED_X_LIKE_TO_JOIN_NFC".niceFaceClubString, nfcLikeCountBaseLimit - post.lc)))"
        }else{
            likeTipsLabel?.text = post.lc.friendString
        }
    }
    
    func playLikeAnimation() {
        likeMarkImage.animationMaxToMin(0.3, maxScale: 1.6, completion: nil)
        likeTipsLabel.text = "+1"
        self.post.lc += 1
        likeTipsLabel.animationMaxToMin(0.3, maxScale: 1.6) {
            self.updateLikeTipsLabel()
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
    }
}

extension NFCPostCell{
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
                    ConversationViewController.showConversationViewController(self.rootController!.navigationController!, userId: userId!)
                }
            })
        }
    }
    
    
    @IBAction func onClickCardButton(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            
        }
    }
    
    @IBAction func onClickLike(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            let hud = self.rootController?.showAnimationHud()
            NFCPostManager.instance.likePost(self.post.pid, callback: { (suc) in
                hud?.hideAnimated(true)
                if(suc){
                    self.chatButton.hidden = false
                    self.playLikeAnimation()
                }else{
                    self.rootController?.playCrossMark("LIKE_POST_OP_ERROR".niceFaceClubString)
                }
            })
        }
    }
    
    @IBAction func onBlackListButtonClick(sender: AnyObject) {
        
    }
    
    @IBAction func onGodLikeButtonClick(sender: AnyObject) {
        
    }
}

class NFCMainViewController: UIViewController {
    
    @IBOutlet weak var rookieButton: UIButton!
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
    
    let homeListType = 0
    let newMemberListType = 1
    let myPostListType = 2
    
    private var listType:Int = 0{
        didSet{
            tableView?.reloadData()
        }
    }
    
    private var taskFileMap = [String:FileAccessInfo]()
    
    
    deinit {
        NFCPostManager.instance.releaseManager();
        debugLog("Deinited:\(self.description)")
    }
}

extension NFCMainViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return posts[listType].count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts[listType][section].count
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NFCPostCell.reuseId, forIndexPath: indexPath) as! NFCPostCell
        cell.setSeparatorFullWidth()
        cell.rootController = self
        cell.post = posts[listType][indexPath.section][indexPath.row]
        return cell
    }
}

extension NFCMainViewController{
    @IBAction func onClickMemberButton(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert(){
            return
        }
    }
    
    @IBAction func onHomeButtonClick(sender: AnyObject) {
        switchListType(homeListType)
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
    
    @IBAction func onRookieButtonClick(sender: AnyObject) {
        if tryShowForbiddenAnymoursAlert(){
            return
        }
        switchListType(newMemberListType)
    }
    
    
    private func tryShowForbiddenAnymoursAlert() -> Bool{
        if profile.score < NiceFaceClubManager.minScore {
            self.showAlert("NFC".niceFaceClubString, msg: "NFC_ANONYMOUS_TIPS".niceFaceClubString)
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
                    self.playCheckMark(""){
                        self.posts[self.homeListType].append([p])
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
        if profile == nil {
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
        let hud = self.showAnimationHud()
        let lastPost = posts[listType].last?.last
        let ts = lastPost?.ts ?? 0
        if listType == homeListType && lastPost == nil{
            NFCPostManager.instance.getMainBoardData({ (data) in
                hud.hideAnimated(true)
                self.tableView.mj_footer?.endRefreshing()
                self.tableView.mj_header?.endRefreshing()
                if let d = data{
                    self.rookieButton.badgeValue = d.newMemCnt > 0 ? d.newMemCnt.friendString : nil
                    if d.posts != nil && d.posts.count > 0{
                        self.posts[self.homeListType].append(d.posts)
                    }else{
                        self.playToast("NO_POSTS".niceFaceClubString)
                    }
                }else{
                    self.playCrossMark("REFRESH_ERROR".niceFaceClubString)
                }
            })
        }else{
            NFCPostManager.instance.getNFCPosts(listType,startTimeSpan: ts, pageCount: 20, callback: { (posts) in
                hud.hideAnimated(true)
                self.tableView.mj_footer.endRefreshing()
                self.tableView.mj_header.endRefreshing()
                if posts.count > 0{
                    self.posts[self.listType].append(posts)
                }else{
                    self.playToast("NO_POSTS".niceFaceClubString)
                }
            })
        }
    }
    
    func switchListType(type:Int) {
        homeButton?.enabled = type != homeListType
        rookieButton?.enabled = type != newMemberListType
        self.listType = type
        if posts[listType].count == 0 {
            refreshPosts()
        }
    }
    
    private func anonymousMode(){
        if profile == nil {
            self.profile = UserNiceFaceProfile()
            self.profile.faceId = nil
            self.profile.nick = ""
            self.profile.id = IdUtil.generateUniqueId()
            self.profile.score = 6.0
            self.profile.sex = 0
        }
        switchListType(homeListType)
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
                if p.score < NiceFaceClubManager.minScore{
                    self.showBenchMarkAlert()
                }else{
                    self.switchListType(self.homeListType)
                    self.showViews()
                    self.refreshPosts()
                }
            }else{
                let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                    self.navigationController?.popViewControllerAnimated(true)
                })
                self.showAlert("NICE_FACE_CLUB".niceFaceClubString, msg: "FETCH_YOUR_PROFILE_ERROR".niceFaceClubString, actions: [ok])
            }
        })
    }
    
    private func showBenchMarkAlert() {
        let alert = NFCMessageAlert.showNFCMessageAlert(self, title: "NICE_FACE_CLUB".niceFaceClubString, message: "YOU_NEED_FACE_BENCHMARK".niceFaceClubString)
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
