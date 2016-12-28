//
//  SNSMainViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/4.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MJRefresh
import LTMorphingLabel
import MBProgressHUD
import EVReflection

//MARK: SNSMainViewController
class SNSMainViewController: UIViewController {
    let SNSLikeCountBaseLimit = 10
    let postPageCount = 20
    
    private(set) var newImageIdFromOutterSource:String?
    private(set) var newImageFromOutterSource:UIImage?
    private(set) var newImageOutterSourceName:String?
    private(set) var postNewImageDelegate:SNSPostNewImageDelegate?
    
    let userService = ServiceContainer.getUserService()
    
    
    
    @IBOutlet weak var newPostButton: UIButton!
    @IBOutlet weak var myPostsButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.tableFooterView = UIView()
        }
    }
    
    private var postingAnimationImageView:UIImageView!
    @IBOutlet weak var postingIndicator: UIActivityIndicatorView!
    
    private var posts:[[[SNSPost]]] = [[[SNSPost]](),[[SNSPost]]()]
    
    private var posting = [SNSPost](){
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
    
    private var boardData:SNSMainBoardData!
    
    private var showControllerTimes:Int{
        get{
            return UserSetting.getUserIntValue("ShowSNSMainView")
        }
        set{
            UserSetting.setUserIntValue("ShowSNSMainView", value: newValue)
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
        SNSPostManager.instance.releaseManager();
        debugLog("Deinited:\(self.description)")
    }
}

//MARK: Life Circle
extension SNSMainViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        SNSPostManager.instance.initManager()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.hidden = true
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(SNSMainViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(SNSMainViewController.mjFooterRefresh(_:)))
        tableView?.mj_footer.automaticallyHidden = true
        homeButton.superview?.superview?.superview?.hidden = true
        MobClick.event("SNS_Login")
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
        start()
    }
}

//MARK: actions
extension SNSMainViewController{
    
    func removePost(postId:String) ->Bool {
        let typeList = self.posts[listType]
        var i = 0
        for psts in typeList {
            if let index = (psts.indexOf{$0.pid == postId}){
                self.posts[listType][i].removeAtIndex(index)
                self.tableView.reloadData()
                return true
            }
            i += 1
        }
        return false
    }
    
    private func shareSNS() {
        ShareHelper.instance.showTellVegeToFriendsAlert(self, message: "SHARE_SNS_MSG".SNSString, alertMsg: "SHARE_SNS_ALERT_MSG".SNSString, title: "SNS".SNSString)
    }
    
    @IBAction func onHomeButtonClick(sender: AnyObject) {
        switchListType(SNSPost.typeNormalPost)
    }
    
    @IBAction func onClickNewPostButton(sender: AnyObject) {
        let v = sender as! UIView
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            let imagePicker = UIImagePickerController.showUIImagePickerAlert(self, title: "SNS".SNSString, message: "POST_NEW_SHARE".SNSString)
            imagePicker.delegate = self
        }
    }
    
    @IBAction func onMyPostButtonClick(sender: AnyObject) {
        self.switchListType(SNSPost.typeMyPost)
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
        self.postingAnimationImageView?.superview?.bringSubviewToFront(self.postingAnimationImageView)
        UIAnimationHelper.playAnimation(self.postingAnimationImageView, animation: animation, key: "movePostingImg") {
            self.postingAnimationImageView?.frame.size = CGSizeZero
            self.postingAnimationImageView?.superview?.sendSubviewToBack(self.postingAnimationImageView)
            self.postingAnimationImageView?.image = nil
            self.postingAnimationImageView?.hidden = true
            self.postingAnimationImageView?.removeFromSuperview()
        }
    }
}

extension SNSMainViewController{
    
    private func showViews(){
        self.tableView.hidden = false
        homeButton.superview?.superview?.superview?.hidden = false
    }
    
    private func showNewerAlert(){
        let ok = UIAlertAction(title: "NEWER_ALERT_YES".SNSString, style: .Default) { (ac) in
            self.onClickNewPostButton(self.newPostButton)
        }
        
        let cancel = UIAlertAction(title: "NEWER_ALERT_NO".SNSString, style: .Default) { (ac) in
            
        }
        
        self.showAlert("NEWER_ALERT_TITLE".SNSString, msg: "NEWER_ALERT_MSG".SNSString, actions: [cancel,ok])
    }
    
    private func refreshPosts() {
        let lastPost = posts[listType].last?.last
        let ts = lastPost?.ts ?? Int64(NSDate().timeIntervalSince1970 * 1000)
        let hud:MBProgressHUD? = lastPost == nil ? self.showActivityHud() : nil
        if listType == SNSPost.typeNormalPost && lastPost == nil{
            SNSPostManager.instance.getMainBoardData(postPageCount,callback: { (data) in
                hud?.hideAnimated(true)
                if let d = data{
                    self.boardData = d
                    ServiceContainer.getActivityService().clearActivityAllBadge(SNSPostManager.activityId)
                    if (d.posts?.count ?? 0) > 0{
                        self.posts[SNSPost.typeNormalPost].append(d.posts)
                    }else{
                        self.flashTipsLabel("NO_POSTS".SNSString)
                    }
                    
                    if self.tryPostOutterImage(){
                        debugPrint("Post Image From Outter")
                    }else if d.newer {
                        self.showNewerAlert()
                    }else if (d.posts?.count ?? 0) > 0{
                        self.tryShowShareAlert()
                    }
                }else{
                    self.playCrossMark("REFRESH_ERROR".SNSString)
                }
                self.setMJFooter()
                self.tableView?.reloadData()
            })
        }else{
            SNSPostManager.instance.getSNSPosts(listType,startTimeSpan: ts, pageCount: postPageCount, callback: { (posts) in
                hud?.hideAnimated(true)
                if posts.count > 0{
                    self.posts[self.listType].append(posts)
                }else{
                    self.flashTipsLabel("NO_POSTS".SNSString)
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
        self.title = type == SNSPost.typeMyPost ? "MY_SNS_POST_WALL".SNSString : "SNS".SNSString
        homeButton?.enabled = type != SNSPost.typeNormalPost
        myPostsButton?.enabled = type != SNSPost.typeMyPost
        self.listType = type
        if posts[listType].count == 0 {
            refreshPosts()
        }
    }
}

extension SNSMainViewController{
    
    private func start(){
        
        self.switchListType(SNSPost.typeNormalPost)
        self.showViews()
    }
    
    private func tryShowShareAlert(){
        showControllerTimes += 1
        let sct = showControllerTimes
        if sct == 3 || sct == 9 || sct == 23 || sct == 42 || sct == 60 {
            self.shareSNS()
        }
    }
    
}

extension SNSMainViewController{
    private func flashTipsLabel(msg:String){
        
        if tipsLabel == nil {
            tipsLabel = UILabel()
        }
        self.tipsLabel.text = msg
        self.tipsLabel.sizeToFit()
        
        self.tipsLabel.layoutIfNeeded()
        self.tipsLabel.frame.size.height += 10
        self.tipsLabel.frame.size.width += 16
        
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
extension SNSMainViewController:UITableViewDelegate,UITableViewDataSource{
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
            let cell = tableView.dequeueReusableCellWithIdentifier(SNSMainInfoCell.reuseId, forIndexPath: indexPath) as! SNSMainInfoCell
            cell.newLikesLabel.text = "+\(self.boardData?.nlks.friendString ?? "0")"
            cell.newCmtLabel.text = "+\(self.boardData?.ncmt.friendString ?? "0")"
            cell.delegate = self
            switch listType {
            case SNSPost.typeMyPost:
                cell.announcementLabel.text = "MY_SNS_POST_WALL_ANC".SNSString
            default:
                let format = String.isNullOrWhiteSpace(self.boardData?.annc) ? "DEFAULT_SNS_ANC".SNSString : self.boardData!.annc
                cell.announcementLabel.text = String(format: format, userService.myProfile.nickName)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(SNSPostCell.reuseId, forIndexPath: indexPath) as! SNSPostCell
        if let p = postOfIndexPath(indexPath) {
            cell.setSeparatorFullWidth()
            cell.rootController = self
            cell.post = p
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? SNSPostCell {
            c.updateImage()
        }
    }
    
    func postOfIndexPath(indexPath:NSIndexPath) -> SNSPost? {
        if posts[listType].count >= indexPath.section && posts[listType][indexPath.section - 1].count > indexPath.row{
            return posts[listType][indexPath.section - 1][indexPath.row]
        }
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SNSPostCell{
            cell.selected = false
            if indexPath.section != 0 {
                if let post = postOfIndexPath(indexPath){
                    SNSPostCommentViewController.showPostCommentViewController(self.navigationController!, post: post).delegate = cell
                }
            }
        }
    }
}

//MARK: SNSMainInfoCellDelegate
extension SNSMainViewController:SNSMainInfoCellDelegate{

    func snsMainInfoCellDidClickNewLikes(sender:UIView,cell:SNSMainInfoCell) {
        cell.likeImageView.animationMaxToMin(0.1, maxScale: 1.2) {
            if let cnt = self.boardData?.nlks{
                self.boardData?.nlks = 0
                cell.newLikesLabel.text = "+0"
                let ctr = SNSReceivedLikeViewController.instanceFromStoryBoard()
                self.navigationController?.pushViewController(ctr, animated: true)
                ctr.loadInitLikes(cnt == 0 ? 10 : cnt)
            }
        }
    }
    
    func snsMainInfoCellDidClickNewComment(sender:UIView,cell:SNSMainInfoCell) {
        cell.newCommentImageView.animationMaxToMin(0.1, maxScale: 1.2) {
            if let cnt = self.boardData?.ncmt{
                self.boardData?.ncmt = 0
                cell.newCmtLabel.text = "+0"
                let ctr = SNSMyCommentViewController.instanceFromStoryBoard()
                self.navigationController?.pushViewController(ctr, animated: true)
                ctr.loadInitComments(cnt == 0 ? 10 : cnt)
            }
        }
    }
}

//MARK: TIMImageTextContentEditorControllerDelegate
extension SNSMainViewController:TIMImageTextContentEditorControllerDelegate{
    private func generateTimEditorModel(image:UIImage,imageId:String? = nil) -> TIMImageTextContentEditorModel{
        let model = TIMImageTextContentEditorModel()
        model.image = image
        model.editorTitle = "POST_NEW_SHARE".SNSString
        model.placeHolder = "TEXT_CONTENT_PLACE_HOLDER".SNSString
        if String.isNullOrWhiteSpace(imageId) == false {
            model.userInfo = ["imageId":imageId!]
        }
        return model
    }
    
    func imageTextContentEditor(sender: TIMImageTextContentEditorController, newTextContent: String?, model: TIMImageTextContentEditorModel?) {
        if let imageId = model?.userInfo?["imageId"] as? String{
            let tmpPost = SNSPost()
            tmpPost.cmtCnt = 0
            tmpPost.img = imageId
            
            if String.isNullOrWhiteSpace(newTextContent) == false{
                tmpPost.body = EVObject(dictionary: ["txt":newTextContent!]).toMiniJsonString()
            }
            
            tmpPost.pid = IdUtil.generateUniqueId()
            self.posting.insert(tmpPost, atIndex: 0)
            self.pushNewPost(tmpPost)
        }else if let img = model?.image{
            self.sendNewPost(img,textContent:newTextContent)
        }
    }
}

//MARK: UIImagePickerControllerDelegate
extension SNSMainViewController:UIImagePickerControllerDelegate,ProgressTaskDelegate{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?){
        picker.dismissViewControllerAnimated(true) {
            if min(image.size.width, image.size.height) > 600{
                let imageForSend = image.size.width < image.size.height ? image.scaleToWidthOf(600) : image.scaleToHeightOf(600)
                let model = self.generateTimEditorModel(imageForSend)
                TIMImageTextContentEditorController.showEditor(self.navigationController!, model: model, delegate: self)
            }else{
                let model = self.generateTimEditorModel(image)
                TIMImageTextContentEditorController.showEditor(self.navigationController!, model: model, delegate: self)
            }
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func sendNewPost(imageForSend:UIImage,textContent:String?) {
        let fService = ServiceContainer.getService(FileService)
        if let imageData = UIImageJPEGRepresentation(imageForSend,0.8){
            debugPrint("ImageSize:\(imageData.length / 1024)KB")
            let localPath = PersistentManager.sharedInstance.createTmpFileName(FileType.Image)
            
            if PersistentFileHelper.storeFile(imageData, filePath: localPath)
            {
                let hud = self.showActivityHud()
                fService.sendFileToAliOSS(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                    hud.hideAnimated(true)
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                    if let fk = fileKey
                    {
                        let post = SNSPost()
                        post.img = fk.fileId
                        post.pid = taskId
                        
                        if String.isNullOrWhiteSpace(textContent) == false{
                            post.body = "{\"txt\":\"\(textContent!)\"}"
                        }
                        
                        self.posting.insert(post, atIndex: 0)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.playPostingIndicatorAnimation(imageForSend)
                        })
                    }else{
                        self.playCrossMark("POST_NEW_ERROR".SNSString)
                    }
                })
            }else
            {
                self.playCrossMark("POST_NEW_ERROR".SNSString)
            }
        }else{
            self.playCrossMark("POST_NEW_ERROR".SNSString)
        }
    }
    
    func pushNewPost(tmpPost:SNSPost) {
        SNSPostManager.instance.newPost(tmpPost.img,body: tmpPost.body, callback: { (post) in
            if let p = post{
                self.playCheckMark(){
                    self.posting.removeElement{$0.pid == tmpPost.pid}
                    self.posts[SNSPost.typeNormalPost].insert([p], atIndex: 0)
                    self.tableView?.setContentOffset(CGPointZero, animated: true)
                    self.tableView?.reloadData()
                    self.postNewImageDelegate?.snsMainViewController(self, onImagePosted:post?.img ?? tmpPost.img)
                }
            }else{
                self.playCrossMark("POST_NEW_ERROR".SNSString)
            }
        })
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let tmpPost = (posting.filter{$0.pid == taskIdentifier}).first{
            pushNewPost(tmpPost)
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        self.posting.removeElement{$0.pid == taskIdentifier}
        self.playCrossMark("POST_NEW_ERROR".localizedString())
    }
}

//MARK: Post New Image From Outter Source
protocol SNSPostNewImageDelegate {
    func snsMainViewController(sender:SNSMainViewController, onImagePosted imageId:String!)
}

extension SNSMainViewController{
    
    private func clearOutterNewImage(){
        newImageIdFromOutterSource = nil
        newImageFromOutterSource = nil
        newImageOutterSourceName = nil
    }
    
    var hasOutterNewImage:Bool{
        return newImageFromOutterSource != nil || String.isNullOrWhiteSpace(newImageIdFromOutterSource) == false
    }
    
    func tryPostOutterImage() -> Bool{
        
        if hasOutterNewImage == false {
            return false
        }
        
        let sourceName = String.isNullOrWhiteSpace(self.newImageOutterSourceName) ? "UNKNOW_SOURCE".SNSString : newImageOutterSourceName!
        let sourceId = newImageIdFromOutterSource
        let sourceImage = newImageFromOutterSource
        
        clearOutterNewImage()
        
        let title = "SHARE_IMAGE_FROM_OUTTER".SNSString
        let msgFormat = "SHARE_IMAGE_FROM_OUTTER_FROM_X".SNSString
        let msg = String(format: msgFormat, sourceName)
        let alert = UIAlertController.create(title: title, message: msg, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (ac) in
            let model = self.generateTimEditorModel(sourceImage!, imageId: sourceId)
            TIMImageTextContentEditorController.showEditor(self.navigationController!, model: model, delegate: self)
        })
        alert.addAction(ok)
        alert.addAction(ALERT_ACTION_CANCEL)
        self.showAlert(alert)
        
        return true
    }
    
    static private func instanceFromStoryBoard() -> SNSMainViewController{
        return instanceFromStoryBoard("SNS", identifier: "SNSMainViewController") as! SNSMainViewController
    }
    
    static func showSNSMainViewControllerWithNewPostImage(nvc:UINavigationController,imageId:String? = nil,image:UIImage? = nil,sourceName:String,delegate:SNSPostNewImageDelegate?) -> SNSMainViewController {
        let controller = instanceFromStoryBoard()
        controller.newImageIdFromOutterSource = imageId
        controller.newImageFromOutterSource = image
        return showSNSMainViewController(nvc, controller: controller,sourceName: sourceName,delegate: delegate)
        
    }
    
    private static func showSNSMainViewController(nvc:UINavigationController,controller:SNSMainViewController,sourceName:String,delegate:SNSPostNewImageDelegate?) -> SNSMainViewController{
        controller.newImageOutterSourceName = sourceName
        controller.postNewImageDelegate = delegate
        nvc.pushViewController(controller, animated: true)
        return controller
    }
}
