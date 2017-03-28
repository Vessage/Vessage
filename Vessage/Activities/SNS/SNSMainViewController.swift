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
    
    //MARK: Share Outter Source Content
    fileprivate(set) var newImageIdFromOutterSource:String?
    fileprivate(set) var newImageFromOutterSource:UIImage?
    fileprivate(set) var newImageOutterSourceName:String?
    fileprivate(set) var postNewImageDelegate:SNSPostNewImageDelegate?
    
    //MARK: Specific User's SNS Posts
    var isUserPageMode:Bool{
        return String.isNullOrWhiteSpace(specificUserId) == false
    }
    
    fileprivate(set) var specificUserId:String?
    fileprivate(set) var specificUserNick:String?
    
    let userService = ServiceContainer.getUserService()
    
    fileprivate var originBottomViewHeightConstant:CGFloat!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!{
        didSet{
            if originBottomViewHeightConstant == nil {
                originBottomViewHeightConstant = bottomViewHeight.constant
            }
        }
    }
    
    var bottomViewsHidden = false{
        didSet{
            homeButton?.superview?.superview?.superview?.isHidden = bottomViewsHidden
            bottomViewHeight?.constant = bottomViewsHidden ? 0 : originBottomViewHeightConstant
        }
    }
    
    @IBOutlet weak var newPostButton: UIButton!
    @IBOutlet weak var myPostsButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.tableFooterView = UIView()
        }
    }
    
    fileprivate var postingAnimationImageView:UIImageView!
    @IBOutlet weak var postingIndicator: UIActivityIndicatorView!
    
    fileprivate var posts:[[[SNSPost]]] = [[[SNSPost]](),[[SNSPost]](),[[SNSPost]]()]
    
    fileprivate var posting = [SNSPost](){
        didSet{
            if posting.count > 0 {
                postingIndicator?.isHidden = false
                postingIndicator?.startAnimating()
            }else{
                postingIndicator?.stopAnimating()
            }
        }
    }
    
    fileprivate var listTableViewOffset = [CGPoint.zero,CGPoint.zero,CGPoint.zero]
    
    fileprivate var listType:Int = 0{
        didSet{
            if listType != oldValue {
                tableView?.mj_footer?.resetNoMoreData()
                listTableViewOffset[oldValue] = tableView.contentOffset
                tableView?.setContentOffset(listTableViewOffset[listType], animated: false)
                DispatchQueue.main.afterMS(100, handler: { 
                    self.tableView?.reloadData()
                })
            }
        }
    }
    
    fileprivate var boardData:SNSMainBoardData!
    
    fileprivate var showControllerTimes:Int{
        get{
            return UserSetting.getUserIntValue("ShowSNSMainView")
        }
        set{
            UserSetting.setUserIntValue("ShowSNSMainView", value: newValue)
        }
    }
    
    fileprivate var tipsLabel:FlashTipsLabel = {
        return FlashTipsLabel()
    }()
    
    @IBAction func tellFriends(_ sender: AnyObject) {
        self.shareSNS()
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
        tableView.isHidden = true
        tableView.autoRowHeight()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.mj_header = MJRefreshGifHeader(refreshingTarget: self, refreshingAction: #selector(SNSMainViewController.mjHeaderRefresh(_:)))
        tableView.mj_footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(SNSMainViewController.mjFooterRefresh(_:)))
        tableView?.mj_footer.isAutomaticallyHidden = true
        bottomViewsHidden = true
        
        newPostButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(SNSMainViewController.onLongPressNewPost(_:))))
        
        MobClick.event("SNS_Login")
    }
    
    func mjFooterRefresh(_ a:AnyObject?) {
        refreshPosts()
    }
    
    func mjHeaderRefresh(_ a:AnyObject?) {
        tableView?.mj_header?.endRefreshing()
        self.posts[listType].removeAll()
        self.refreshPosts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        start()
    }
}

//MARK: actions
extension SNSMainViewController{
    
    func updatePostState(_ postId:String,newState:Int) {
        let typeList = self.posts[listType]
        var i = 0
        for psts in typeList {
            if let index = (psts.index{$0.pid == postId}){
                self.posts[listType][i][index].st = newState
                let tableViewSection = i + 1
                self.tableView.reloadRows(at: [IndexPath(row: index, section: tableViewSection)], with: .none)
            }
            i += 1
        }
    }
    
    @discardableResult
    func removePost(_ postId:String) ->Bool {
        let typeList = self.posts[listType]
        var i = 0
        for psts in typeList {
            if let index = (psts.index{$0.pid == postId}){
                self.posts[listType][i].remove(at: index)
                let tableViewSection = i + 1
                self.tableView.deleteRows(at: [IndexPath(row: index, section: tableViewSection)], with: .automatic)
                return true
            }
            i += 1
        }
        return false
    }
    
    fileprivate func shareSNS() {
        ShareHelper.instance.showTellVegeToFriendsAlert(self, message: "SHARE_SNS_MSG".SNSString, alertMsg: "SHARE_SNS_ALERT_MSG".SNSString, title: "SNS".SNSString,copyLink: true)
    }
    
    @IBAction func onHomeButtonClick(_ sender: AnyObject) {
        switchListType(SNSPost.typeNormalPost)
    }
    
    @IBAction func onClickNewPostButton(_ sender: AnyObject) {
        let v = sender as! UIView
        
        let text = UIAlertAction(title:"POST_ONLY_TEXT".SNSString, style: .default) { _ in
            self.showNewTextPost()
        }
        
        v.animationMaxToMin(0.1, maxScale: 1.2) {
            let imagePicker = UIImagePickerController.showUIImagePickerAlert(self, title: "POST_NEW_SHARE".SNSString, message: nil,extraAlertAction:[text])
            imagePicker.delegate = self
        }
    }
    
    func onLongPressNewPost(_ ges:UILongPressGestureRecognizer) {
        if ges.state == .began {
            showNewTextPost()
        }
    }
    
    fileprivate func showNewTextPost() {
        let model = generateTimEditorModel(nil)
        TIMImageTextContentEditorController.showEditor(self.navigationController!, model: model, delegate: self)
    }
    
    @IBAction func onMyPostButtonClick(_ sender: AnyObject) {
        self.switchListType(SNSPost.typeMyPost)
    }
    
    func playPostingIndicatorAnimation(_ img:UIImage?) {
        if img == nil {
            return
        }
        if nil == postingAnimationImageView {
            self.postingAnimationImageView = UIImageView()
            self.postingAnimationImageView.contentMode = .scaleAspectFill
        }
        let width = self.view.frame.width - 20
        let height = width
        let y = (self.view.frame.height - height) / 2
        let frame = CGRect(x: 0 - width, y: y, width: width, height: height)
        self.postingAnimationImageView.frame = frame
        self.postingAnimationImageView.image = img
        self.view.addSubview(postingAnimationImageView)
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2))
        animation.toValue = NSValue(cgPoint: CGPoint(x: 0 + 36, y: self.view.frame.height - 24))
        animation.duration = 0.6
        
        let animation2 = CABasicAnimation(keyPath: "transform.scale")
        animation2.fromValue = CGFloat(1)
        animation2.toValue = CGFloat(0.01)
        animation2.duration = 0.6
        animation2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        postingAnimationImageView.layer.add(animation2, forKey: "postingScale")
        self.postingAnimationImageView.isHidden = false
        self.postingAnimationImageView?.superview?.bringSubview(toFront: self.postingAnimationImageView)
        UIAnimationHelper.playAnimation(self.postingAnimationImageView, animation: animation, key: "movePostingImg") {
            self.postingAnimationImageView?.frame.size = CGSize.zero
            self.postingAnimationImageView?.superview?.sendSubview(toBack: self.postingAnimationImageView)
            self.postingAnimationImageView?.image = nil
            self.postingAnimationImageView?.isHidden = true
            self.postingAnimationImageView?.removeFromSuperview()
        }
    }
}

extension SNSMainViewController{
    
    fileprivate func showViews(){
        self.tableView.isHidden = false
        bottomViewsHidden = false
    }
    
    fileprivate func showNewerAlert(){
        let ok = UIAlertAction(title: "NEWER_ALERT_YES".SNSString, style: .default) { (ac) in
            self.onClickNewPostButton(self.newPostButton)
        }
        
        let cancel = UIAlertAction(title: "NEWER_ALERT_NO".SNSString, style: .default) { (ac) in
            
        }
        
        self.showAlert("NEWER_ALERT_TITLE".SNSString, msg: "NEWER_ALERT_MSG".SNSString, actions: [cancel,ok])
    }
    
    fileprivate func refreshPosts() {
        let lastPost = posts[listType].last?.last
        let ts = lastPost?.ts ?? Int64(Date().timeIntervalSince1970 * 1000)
        let hud:MBProgressHUD? = lastPost == nil ? self.showActivityHud() : nil
        if listType == SNSPost.typeNormalPost && lastPost == nil{
            SNSPostManager.instance.getMainBoardData(postPageCount,callback: { (data) in
                hud?.hide(animated: true)
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
                    }else if !String.isNullOrWhiteSpace(d.alertMsg){
                        self.showAlert("SNS".SNSString, msg: d.alertMsg)
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
            SNSPostManager.instance.getSNSPosts(listType,startTimeSpan: ts, pageCount: postPageCount,specificUserId: specificUserId, callback: { (posts) in
                hud?.hide(animated: true)
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
    
    fileprivate func setMJFooter(){
        if let cnt = posts[listType].last?.count{
            if cnt > 0 && cnt < postPageCount {
                self.tableView?.mj_footer?.endRefreshingWithNoMoreData()
            }else{
                self.tableView?.mj_footer?.endRefreshing()
            }
        }
    }
    
    func switchListType(_ type:Int) {
        if isUserPageMode {
            self.title = specificUserNick ?? "UNKNOW_NAME".localizedString()
        }else{
            self.title = type == SNSPost.typeMyPost ? "MY_SNS_POST_WALL".SNSString : "SNS".SNSString
        }
        homeButton?.isEnabled = type != SNSPost.typeNormalPost
        myPostsButton?.isEnabled = type != SNSPost.typeMyPost
        self.listType = type
        if posts[listType].count == 0 {
            refreshPosts()
        }
    }
}

extension SNSMainViewController{
    
    fileprivate func start(){
        if isUserPageMode {
            self.switchListType(SNSPost.typeSingleUserPost)
            self.tableView.isHidden = false
            self.bottomViewsHidden = true
        }else{
            self.switchListType(self.listType)
            self.showViews()
        }
        
    }
    
    fileprivate func tryShowShareAlert(){
        showControllerTimes += 1
        let sct = showControllerTimes
        if sct == 3 || sct == 9 || sct == 23 || sct == 42 || sct == 60 {
            self.shareSNS()
        }
    }
    
}

extension SNSMainViewController{
    fileprivate func flashTipsLabel(_ msg:String){
        let x = self.view.frame.width / 2
        let y = self.tableView.frame.origin.y + self.tableView.frame.height - 32
        let center = CGPoint(x: x, y: y)
        tipsLabel.flashTips(self.view, msg: msg, center: center)
    }
}

//MARK: UITableViewDelegate
extension SNSMainViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts[listType].count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return isUserPageMode ? 0 : 1
        }
        return posts[listType][section - 1].count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return isUserPageMode ? 0 : 10
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: SNSMainInfoCell.reuseId, for: indexPath) as! SNSMainInfoCell
            cell.newLikesLabel.text = "+\(self.boardData?.nlks.friendString ?? "0")"
            cell.newCmtLabel.text = "+\(self.boardData?.ncmt.friendString ?? "0")"
            cell.delegate = self
            switch listType {
            case SNSPost.typeMyPost:
                cell.announcementLabel.text = "MY_SNS_POST_WALL_ANC".SNSString
            default:
                let format = String.isNullOrWhiteSpace(self.boardData?.annc) ? "DEFAULT_SNS_ANC".SNSString : self.boardData!.annc!
                cell.announcementLabel.text = String(format: format, userService.myProfile.nickName)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: SNSPostCell.reuseId, for: indexPath) as! SNSPostCell
        if let p = postOfIndexPath(indexPath) {
            cell.setSeparatorFullWidth()
            cell.rootController = self
            cell.post = p
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layoutSubviews()
        if let c = cell as? SNSPostCell {
            c.updateImage()
        }
    }
    
    func postOfIndexPath(_ indexPath:IndexPath) -> SNSPost? {
        if posts[listType].count >= indexPath.section && posts[listType][indexPath.section - 1].count > indexPath.row{
            return posts[listType][indexPath.section - 1][indexPath.row]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? SNSPostCell{
            cell.isSelected = false
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

    func snsMainInfoCellDidClickNewLikes(_ sender:UIView,cell:SNSMainInfoCell) {
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
    
    func snsMainInfoCellDidClickNewComment(_ sender:UIView,cell:SNSMainInfoCell) {
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
    fileprivate func generateTimEditorModel(_ image:UIImage?,imageId:String? = nil) -> TIMImageTextContentEditorModel{
        let model = TIMImageTextContentEditorModel()
        model.image = image
        if image == nil && String.isNullOrWhiteSpace(imageId) {
            model.editorTitle = "POST_NEW_SHARE_TXT".SNSString
        }else{
            model.editorTitle = "POST_NEW_SHARE".SNSString
        }
        
        model.placeHolder = "TEXT_CONTENT_PLACE_HOLDER".SNSString
        model.userInfo = NSMutableDictionary()
        if String.isNullOrWhiteSpace(imageId) == false {
            model.userInfo![TIMImageTextContentEditorModel.imageIdKey] = imageId!
        }
        
        model.userInfo![TIMImageTextContentEditorModel.extraSwitchOnTipsKey] = "PUBLIC_POST_TIPS".SNSString
        model.userInfo![TIMImageTextContentEditorModel.extraSwitchOffTipsKey] = "PRIVATE_POST_TIPS".SNSString
        model.userInfo![TIMImageTextContentEditorModel.extraSwitchInitValueKey] = true
        model.userInfo![TIMImageTextContentEditorModel.extraSwitchLabelTextKey] = "PUBLIC_PRI_LABEL".SNSString
        model.extraSetup = true
        
        return model
    }
    
    func imageTextContentEditor(_ sender: TIMImageTextContentEditorController, newTextContent: String?, model: TIMImageTextContentEditorModel?) {
        
        var postState = SNSPost.stateNormal
        
        if let publicPost = model?.userInfo?[TIMImageTextContentEditorModel.extraSwitchValueKey] as? Bool {
            if !publicPost {
                postState = SNSPost.statePrivate
            }
        }
        
        var autoPrivateSec = 0
        
        if let sec = model?.userInfo?[TIMImageTextContentEditorModel.extraAutoPrivateSecKey] as? Int{
            autoPrivateSec = sec
        }
        
        let tmpPost = SNSPost()
        tmpPost.cmtCnt = 0
        if String.isNullOrWhiteSpace(newTextContent) == false{
            tmpPost.body = String.miniJsonStringWithDictionary(["txt":newTextContent!])
        }
        
        tmpPost.pid = IdUtil.generateUniqueId()
        tmpPost.st = postState
        tmpPost.atpv = autoPrivateSec
        
        if let img = model?.image{
            self.sendNewPost(img,post: tmpPost)
        }else{
            if let imageId = model?.userInfo?["imageId"] as? String{
                tmpPost.img = imageId
            }
            
            self.posting.insert(tmpPost, at: 0)
            self.pushNewPost(tmpPost)
        }
    }
}

//MARK: UIImagePickerControllerDelegate
extension SNSMainViewController:UIImagePickerControllerDelegate,ProgressTaskDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?){
        picker.dismiss(animated: true) {
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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func sendNewPost(_ imageForSend:UIImage,post:SNSPost) {
        let fService = ServiceContainer.getFileService()
        if let imageData = UIImageJPEGRepresentation(imageForSend,0.8){
            debugPrint("ImageSize:\(imageData.count / 1024)KB")
            let localPath = PersistentManager.sharedInstance.createTmpFileName(FileType.image)
            
            if PersistentFileHelper.storeFile(imageData, filePath: localPath)
            {
                let hud = self.showActivityHud()
                fService.sendFileToAliOSS(localPath, type: FileType.image, callback: { (taskId, fileKey) -> Void in
                    hud.hide(animated: true)
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                    if let fk = fileKey
                    {
                        post.img = fk.fileId
                        post.pid = taskId
                        
                        self.posting.insert(post, at: 0)
                        DispatchQueue.main.async(execute: {
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
    
    func pushNewPost(_ tmpPost:SNSPost) {
        SNSPostManager.instance.newPost(tmpPost.img,body: tmpPost.body,state: tmpPost.st,autoPrivate: tmpPost.atpv, callback: { (post) in
            if let p = post{
                self.playCheckMark(){
                    self.posting.removeElement{$0.pid == tmpPost.pid}
                    self.posts[SNSPost.typeNormalPost].insert([p], at: 0)
                    if self.listType == SNSPost.typeNormalPost{
                        self.tableView.insertSections(IndexSet(integer: 1), with: .automatic)
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .bottom, animated: true)
                    }
                    self.postNewImageDelegate?.snsMainViewController(self, onImagePosted:post?.img ?? tmpPost.img)
                }
            }else{
                self.playCrossMark("POST_NEW_ERROR".SNSString)
            }
        })
    }
    
    func taskCompleted(_ taskIdentifier: String, result: Any!) {
        if let tmpPost = (posting.filter{$0.pid == taskIdentifier}).first{
            pushNewPost(tmpPost)
        }
    }
    
    func taskFailed(_ taskIdentifier: String, result: Any!) {
        self.posting.removeElement{$0.pid == taskIdentifier}
        self.playCrossMark("POST_NEW_ERROR".localizedString())
    }
}

//MARK: Post New Image From Outter Source
protocol SNSPostNewImageDelegate {
    func snsMainViewController(_ sender:SNSMainViewController, onImagePosted imageId:String!)
}

extension SNSMainViewController{
    
    fileprivate func clearOutterNewImage(){
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
        
        let sourceId = newImageIdFromOutterSource
        let sourceImage = newImageFromOutterSource
        
        clearOutterNewImage()
        
        let model = self.generateTimEditorModel(sourceImage!, imageId: sourceId)
        TIMImageTextContentEditorController.showEditor(self.navigationController!, model: model, delegate: self)
        
        return true
    }
    
    static fileprivate func instanceFromStoryBoard() -> SNSMainViewController{
        return instanceFromStoryBoard("SNS", identifier: "SNSMainViewController") as! SNSMainViewController
    }
    
    @discardableResult
    static func showUserSNSPostViewController(_ nvc:UINavigationController,userId:String,nick:String) -> SNSMainViewController{
        let controller = instanceFromStoryBoard()
        controller.specificUserId = userId
        controller.specificUserNick = nick
        nvc.pushViewController(controller, animated: true)
        return controller
    }
    
    @discardableResult
    static func showSNSMainViewControllerWithNewPostImage(_ nvc:UINavigationController,imageId:String? = nil,image:UIImage? = nil,sourceName:String,delegate:SNSPostNewImageDelegate?) -> SNSMainViewController {
        let controller = instanceFromStoryBoard()
        controller.newImageIdFromOutterSource = imageId
        controller.newImageFromOutterSource = image
        return showSNSMainViewController(nvc, controller: controller,sourceName: sourceName,delegate: delegate)
        
    }
    
    @discardableResult
    fileprivate static func showSNSMainViewController(_ nvc:UINavigationController,controller:SNSMainViewController,sourceName:String,delegate:SNSPostNewImageDelegate?) -> SNSMainViewController{
        controller.newImageOutterSourceName = sourceName
        controller.postNewImageDelegate = delegate
        nvc.pushViewController(controller, animated: true)
        return controller
    }
}
