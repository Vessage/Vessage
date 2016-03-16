//
//  RecordMessageController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import AssetsLibrary
import MBProgressHUD

//MARK: RecordMessageController
class RecordMessageController: UIViewController,VessageCameraDelegate {
    
    let userService = ServiceContainer.getService(UserService)
    private static var instance:RecordMessageController!
    
    private var chatter:VessageUser!{
        didSet{
            let oldChatImage = oldValue?.mainChatImage
            if oldChatImage != chatter?.mainChatImage{
                self.updateChatImage(chatter?.mainChatImage)
            }
        }
    }
    
    private var recording = false{
        didSet{
            if cancelRecordButton != nil{
                cancelRecordButton.hidden = !recording
            }
            if recordButton != nil{
                updateRecordButton()
            }
            if recordingProgress != nil{
                updateRecordingProgress()
            }
            if previewRectView != nil{
                previewRectView.hidden = recording
            }
        }
    }
    private let maxRecordTime:CGFloat = 10
    private var recordingTime:CGFloat = 0{
        didSet{
            if recordingProgress != nil{
                updateRecordingProgress()
            }
            if recordingTime == maxRecordTime{
                prepareSendRecord()
            }
        }
    }
    @IBOutlet weak var previewRectView: UIView!{
        didSet{
            previewRectView.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var recordingProgress: KDCircularProgress!{
        didSet{
            recordingProgress.hidden = true
            
        }
    }
    private var camera:VessageCamera!
    private var recordingTimer:NSTimer!
    @IBOutlet weak var smileFaceImageView: UIImageView!
    
    @IBOutlet weak var recordingFlashView: UIView!{
        didSet{
            recordingFlashView.layer.cornerRadius = recordingFlashView.frame.size.height / 2
            recordingFlashView.hidden = true
        }
    }
    @IBOutlet weak var closeRecordViewButton: UIButton!{
        didSet{
            closeRecordViewButton.layer.cornerRadius = closeRecordViewButton.frame.size.height / 2
        }
    }
    @IBOutlet weak var recordButton: UIButton!{
        didSet{
            recordButton.hidden = true
            recordButton.layer.cornerRadius = recordButton.frame.size.height / 2
        }
    }
    @IBOutlet weak var cancelRecordButton: UIButton!{
        didSet{
            cancelRecordButton.layer.cornerRadius = cancelRecordButton.frame.size.height / 2
            cancelRecordButton.hidden = !recording
        }
    }
    //MARK: life circle
    deinit{
        chatter = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = VessageCamera()
        camera.delegate = self
        camera.initCamera(self,previewView: self.previewRectView)
        self.recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "recordingFlashing:", userInfo: nil, repeats: true)
        self.view.bringSubviewToFront(recordingProgress)
        self.view.bringSubviewToFront(recordingFlashView)
        self.view.bringSubviewToFront(recordButton)
        self.view.bringSubviewToFront(closeRecordViewButton)
        self.view.bringSubviewToFront(cancelRecordButton)
        userService.addObserver(self, selector: "onUserProfileUpdated:", name: UserService.userProfileUpdated, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let imgId = self.chatter.mainChatImage{
            self.chatter.mainChatImage = imgId
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        camera.openCamera()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    //MARK:notifications
    func onUserProfileUpdated(a:NSNotification){
        if let chatter = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if self.chatter.userId == chatter.userId || self.chatter.mobile == chatter.mobile || self.chatter.mobile.md5 == chatter.mobile{
                self.chatter = chatter
            }
        }
    }
    
    //MARK: actions
    func updateChatImage(mainChatImage:String?){
        if let imgView = self.smileFaceImageView{
            ServiceContainer.getService(FileService).setAvatar(imgView, iconFileId: mainChatImage)
        }
    }
    
    @IBAction func cancelRecord(sender: AnyObject) {
        camera.cancelRecord()
        self.playToast("CANCEL_RECORD".localizedString())
    }
    
    @IBAction func closeRecordView(sender: AnyObject) {
        camera.cancelRecord()
        camera.closeCamera()
        self.dismissViewControllerAnimated(false) { () -> Void in
        }
    }
    
    @IBAction func recordButtonClicked(sender: AnyObject) {
        if self.recording{
            self.prepareSendRecord()
        }else{
            self.startRecord()
        }
    }
    
    func recordingFlashing(_:AnyObject?){
        if recording{
            recordingTime++
            self.recordingFlashView.hidden = !self.recordingFlashView.hidden
        }else{
            self.recordingFlashView.hidden = true
        }
    }
    
    private func updateRecordingProgress(){
        let maxAngle:CGFloat = 360
        let angle = Int(recordingTime / maxRecordTime * maxAngle)
        self.recordingProgress.angle = angle
        self.recordingProgress.hidden = !recording
    }
    
    private func updateRecordButton(){
        if recording{
            recordButton.setImage(UIImage(named: "check"), forState: .Normal)
            recordButton.setImage(UIImage(named: "check"), forState: .Highlighted)
        }else{
            recordButton.setImage(UIImage(named: "movie"), forState: .Normal)
            recordButton.setImage(UIImage(named: "movie"), forState: .Highlighted)
        }
    }
    
    private func startRecord()
    {
        camera.startRecord()
    }
    
    var sendingHud:MBProgressHUD!
    private func prepareSendRecord()
    {
        sendingHud = self.showActivityHud()
        camera.saveRecordedVideo()
    }
    
    private func sendVessageFile(vessageId:String, url:NSURL){
        let hud = self.showActivityHudWithMessage(nil, message: "SENDING_VESSAGE".localizedString())
        ServiceContainer.getService(FileService).sendFileToAliOSS(url.path!, type: .Video) { (taskId, fileKey) -> Void in
            hud.hideAsync(false)
            if fileKey != nil{
                ServiceContainer.getService(VessageService).observeOnFileUploadedForVessage(vessageId, fileKey: fileKey)
            }else{
                self.retrySendFile(vessageId,url: url)
            }
        }
        
        //primary version do not use queue
        //VessageQueue.sharedInstance.pushNewVideoTo(conversationId, fileUrl:url)
    }
    
    
    private func retrySendFile(vessageId:String,url:NSURL){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessageFile(vessageId,url: url)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            ServiceContainer.getService(VessageService).cancelSendVessage(vessageId)
            self.playCrossMark("CANCEL".localizedString())
        }
        self.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }
    
    private func sendVessage(url:NSURL){
        let hud = self.showActivityHudWithMessage(nil, message: "SENDING_VESSAGE".localizedString())
        func sendedCallback(vessageId:String?){
            hud.hideAsync(false)
            if let vid = vessageId{
                self.sendVessageFile(vid, url: url)
            }else{
                self.retrySendVessage(url)
            }
        }
        let sendNick = self.userService.myProfile.nickName
        let sendMobile = self.userService.myProfile.mobile
        if let receiverId = self.chatter?.userId{
            ServiceContainer.getService(VessageService).sendVessageToUser(receiverId, sendNick: sendNick,sendMobile: sendMobile, callback: sendedCallback)
        }else if let receiverMobile = self.chatter.mobile{
            ServiceContainer.getService(VessageService).sendVessageToMobile(receiverMobile, sendNick: sendNick,sendMobile: sendMobile, callback: sendedCallback)
        }else{
            hud.hideAsync(false)
        }
    }
    
    private func retrySendVessage(url:NSURL){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessage(url)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            self.playCrossMark("CANCEL".localizedString())
        }
        self.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }

    
    private func confirmSend(url:NSURL){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessage(url)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            
        }
        let size = PersistentFileHelper.fileSizeOf(url.path!)
        print("\(size/1024)kb")
        let conversationNoteName = chatter.nickName
        self.showAlert("CONFIRM_SEND_VESSAGE_TITLE".localizedString(), msg: conversationNoteName, actions: [okAction,cancelAction])
    }
    
    //MARK: VessageCamera Delegate
    func vessageCameraDidStartRecord() {
        recordingTime = 0
        recording = true
    }
    
    func vessageCameraDidStopRecord() {
        recording = false
    }
    
    func vessageCameraReady() {
        recordButton.hidden = false
    }
    
    func vessageCameraSessionClosed() {
        recordButton.hidden = true
    }
    
    func vessageCamera(videoSavedUrl: NSURL) {
        self.sendingHud.hideAsync(true)
        let newFilePath = PersistentManager.sharedInstance.createTmpFileName(.Video)
        if PersistentFileHelper.moveFile(videoSavedUrl.path!, destinationPath: newFilePath)
        {
            self.playToast("VIDEO_SAVED".localizedString())
            confirmSend(NSURL(fileURLWithPath: newFilePath))
        }else
        {
            self.showAlert("SAVE_VIDEO_FAILED".localizedString(), msg: "")
        }
        
    }
    
    static func showRecordMessageController(vc:UIViewController,chatter:VessageUser)
    {
        if RecordMessageController.instance == nil{
            RecordMessageController.instance = instanceFromStoryBoard("Main", identifier: "RecordMessageController") as! RecordMessageController
        }
        instance.chatter = chatter
        vc.presentViewController(instance, animated: true) { () -> Void in
            
        }
    }
}
