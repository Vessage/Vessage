//
//  RecordVessageManager.swift
//  Vessage
//
//  Created by AlexChow on 16/5/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MBProgressHUD

//MARK: RecordVessageManager
class RecordVessageManager: ConversationViewControllerProxy,VessageCameraDelegate {
    private(set) var camera:VessageCamera!
    private var recordingTimer:NSTimer!
    private var userClickSend = false
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
    private let maxRecordTime:CGFloat = 16
    private var recordingTime:CGFloat = 0{
        didSet{
            if recordingProgress != nil{
                updateRecordingProgress()
            }
            if recordingTime == maxRecordTime{
                userClickSend = false
                rootController.setReadingVessage()
                sendVessage()
            }
        }
    }
    
    func recordingFlashing(_:AnyObject?){
        if recording{
            recordingTime += 1
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
            recordButton.setImage(UIImage(named: "checkRound"), forState: .Normal)
            recordButton.setImage(UIImage(named: "checkRound"), forState: .Highlighted)
        }else{
            recordButton.setImage(UIImage(named: "chat"), forState: .Normal)
            recordButton.setImage(UIImage(named: "chat"), forState: .Highlighted)
        }
    }
    
    override func onSwitchToManager() {
        rightButton.setImage(UIImage(named: "close"), forState: .Normal)
        rightButton.setImage(UIImage(named: "close"), forState: .Highlighted)
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(RecordVessageManager.onVessageSended(_:)), name: VessageService.onNewVessageSended, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(RecordVessageManager.onVessageSendFail(_:)), name: VessageService.onNewVessageSendFail, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(RecordVessageManager.onVessageSending(_:)), name: VessageService.onNewVessageSending, object: nil)
        
        camera = VessageCamera()
        camera.delegate = self
        camera.initCamera(rootController,previewView: self.previewRectView)
        self.recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(RecordVessageManager.recordingFlashing(_:)), userInfo: nil, repeats: true)
    }
    
    func onVessageSending(a:NSNotification){
        if let task = a.userInfo?[SendedVessageTaskValue] as? VessageFileUploadTask{
            if task.receiverId == self.conversation?.chatterId {
                if let persent = a.userInfo?[SendingVessagePersentValue] as? Float{
                    self.rootController.progressView.progress = persent
                }
            }
        }
    }
    
    func onVessageSendFail(a:NSNotification){
        self.rootController.progressView.hidden = true
        self.rootController.controllerTitle = "VESSAGE_SEND_FAIL".localizedString()
    }
    
    func onVessageSended(a:NSNotification){
        self.rootController.controllerTitle = "VESSAGE_SENDED".localizedString()
        NSTimer.scheduledTimerWithTimeInterval(2.3, target: self, selector: #selector(RecordVessageManager.resetTitle(_:)), userInfo: nil, repeats: false)
        if let task = a.userInfo?[SendedVessageTaskValue] as? VessageFileUploadTask{
            if let userId = task.receiverId{
                if userId == conversation?.chatterId {
                    if !self.isGroupChat && String.isNullOrEmpty(chatter?.accountId) {
                        self.showSendTellFriendAlert()
                    }
                }
            }
        }
    }
    
    func resetTitle(_:AnyObject?) {
        self.rootController.progressView.hidden = true
        
        if isGroupChat {
            self.rootController.controllerTitle = chatGroup.groupName
        }else{
            self.rootController.controllerTitle = ServiceContainer.getUserService().getUserNotedName(conversation.chatterId)
        }
    }
    
    private func showSendTellFriendAlert(){
        let send = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) -> Void in
            let contentText = String(format: "NOTIFY_SMS_FORMAT".localizedString(),"")
            ShareHelper.showTellTextMsgToFriendsAlert(self.rootController, content: contentText)
        })
        let name = ServiceContainer.getUserService().getUserNotedName(chatter.userId)
        self.rootController.showAlert("SEND_NOTIFY_SMS_TO_FRIEND".localizedString(), msg: name, actions: [send])
    }
    
    func startRecord()
    {
        if camera.cameraInited{
            userClickSend = true
            MobClick.event("Vege_RecordVessage")
            camera.startRecord()
        }else{
            self.rootController.playToast("CAMERA_NOT_INITED".localizedString())
        }
        
    }
    
    func sendVessage() {
        if recording {
            prepareSendRecord()
        }
    }
    
    private func prepareSendRecord()
    {
        recordButton.userInteractionEnabled = false
        camera.saveRecordedVideo()
    }
    
    private func confirmSend(url:NSURL){
        #if DEBUG
            let size = PersistentFileHelper.fileSizeOf(url.path!)
            print("\(size/1024)kb")
        #endif
        if userClickSend {
            pushNewVessageToQueue(url)
        }else{
            let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
                self.pushNewVessageToQueue(url)
            }
            let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (action) -> Void in
                MobClick.event("Vege_CancelSendVessage")
            }
            self.rootController.showAlert("CONFIRM_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
        }
    }
    
    private func pushNewVessageToQueue(url:NSURL){
        MobClick.event("Vege_ConfirmSendVessage")
        dispatch_async(dispatch_get_main_queue()) {
            self.rootController.progressView.progress = 0.2
            self.rootController.progressView.hidden = false
            self.rootController.controllerTitle = "VESSAGE_SENDING".localizedString()
        }
        let chatterId = isGroupChat ? self.chatGroup.groupId : self.chatter.userId
        VessageQueue.sharedInstance.pushNewVessageTo(chatterId,isGroup: isGroupChat, videoUrl: url)
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
    
    func vessageCameraVideoSaved(videoSavedUrl video: NSURL) {
        recordButton.userInteractionEnabled = true
        let newFilePath = PersistentManager.sharedInstance.createTmpFileName(.Video)
        if PersistentFileHelper.moveFile(video.path!, destinationPath: newFilePath)
        {
            confirmSend(NSURL(fileURLWithPath: newFilePath))
        }else
        {
            self.rootController.showAlert("SAVE_VIDEO_FAILED".localizedString(), msg: "")
        }
    }
    
    func vessageCameraSaveVideoError(saveVideoError msg: String?) {
        recordButton.userInteractionEnabled = true
        self.rootController.playToast("SAVE_VIDEO_FAILED".localizedString())
    }
    
    override func onChatterUpdated(chatter: VessageUser) {
        self.updateChatImage(chatter.mainChatImage)
    }
    
    override func onChatGroupUpdated(chatGroup: ChatGroup) {
        //TODO: Set Chat Group Images
    }
    
    private var defaultFace:UIImage!
    private func updateChatImage(mainChatImage:String?){
        if defaultFace == nil {
            defaultFace = UIImage(named: "defaultFace")!
        }
        if let imgView = self.smileFaceImageView{
            if let imgId = mainChatImage{
                imgView.contentMode = .Center
                noSmileFaceTipsLabel.hidden = false
                ServiceContainer.getService(FileService).setAvatar(imgView, iconFileId: imgId,defaultImage: defaultFace){ suc in
                    if suc{
                        imgView.contentMode = .ScaleAspectFill
                        self.noSmileFaceTipsLabel.hidden = true
                    }
                }
            }else {
                imgView.image = defaultFace
                imgView.contentMode = .Center
                noSmileFaceTipsLabel.hidden = false
            }
        }
    }
    
    func cancelRecord() {
        camera.cancelRecord()
    }
    
    override func onReleaseManager() {
        ServiceContainer.getVessageService().removeObserver(self)
        camera.cancelRecord()
        camera.closeCamera()
    }
}