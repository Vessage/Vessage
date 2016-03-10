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
    private var conversation:Conversation!
    
    private var chatter:VessageUser!{
        didSet{
            if let oldv = oldValue{
                oldv.removeObserver(self, forKeyPath: "mainChatImage")
            }
            chatter.addObserver(self, forKeyPath: "mainChatImage", options: .New, context: nil)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        if keyPath == "mainChatImage"{
            ServiceContainer.getService(FileService).setAvatar(self.smileFaceImageView, iconFileId: chatter.mainChatImage)
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
            self.chatter = chatter
        }
    }
    
    //MARK: actions
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
    
    private func sendVessage(url:NSURL){
        let hud = self.showActivityHudWithMessage(nil, message: "SENDING_VESSAGE".localizedString())
        ServiceContainer.getService(FileService).sendFileToAliOSS(url.path!, type: .Video) { (taskId, fileKey) -> Void in
            if fileKey != nil{
                let vessage = Vessage()
                vessage.conversationId = self.conversation.conversationId
                vessage.fileId = fileKey.fileId
                ServiceContainer.getService(VessageService).sendVessage(vessage){ sended in
                    hud.hideAsync(false)
                    self.retrySendVessage(vessage)
                }
            }else{
                hud.hideAsync(false)
                self.retrySendFile(url)
            }
        }
        
        //primary version do not use queue
        //VessageQueue.sharedInstance.pushNewVideoTo(conversationId, fileUrl:url)
    }
    
    private func retrySendVessage(vessage:Vessage){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            let hud = self.showActivityHudWithMessage(nil, message: "SENDING_VESSAGE".localizedString())
            ServiceContainer.getService(VessageService).sendVessage(vessage){ sended in
                hud.hideAsync(false)
                self.retrySendVessage(vessage)
            }
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            
        }
        self.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }
    
    private func retrySendFile(url:NSURL){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessage(url)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            
        }
        self.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }
    
    var tmpFilmZipURL:NSURL {
        let tempDir = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: tempDir).URLByAppendingPathComponent("tmpVessage.zip")
        return url
    }
    
    private func confirmSend(url:NSURL){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessage(url)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            
        }
        let conversationNoteName = conversation.chatterNoteName
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
        let size = PersistentFileHelper.fileSizeOf(videoSavedUrl.path!)
        print("\(size/1024)kb")
        confirmSend(videoSavedUrl)
    }
    
    static func showRecordMessageController(vc:UIViewController,conversation:Conversation)
    {
        if RecordMessageController.instance == nil{
            RecordMessageController.instance = instanceFromStoryBoard("Main", identifier: "RecordMessageController") as! RecordMessageController
        }
        instance.conversation = conversation
        if String.isNullOrEmpty(conversation.chatterId) == false{
            instance.chatter = ServiceContainer.getService(UserService).getUserProfile(conversation.chatterId){ chatter in
                
            }
        }else if String.isNullOrEmpty(conversation.chatterMobile) == false{
            instance.chatter = ServiceContainer.getService(UserService).getUserProfile(conversation.chatterMobile){ chatter in
                
            }
        }else{
            return
        }
        vc.presentViewController(instance, animated: true) { () -> Void in
            
        }
    }
}
