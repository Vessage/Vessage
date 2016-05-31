//
//  RecordVessageManager.swift
//  Vessage
//
//  Created by AlexChow on 16/5/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MBProgressHUD

class RecordVessageManager: ConversationViewControllerProxy,VessageCameraDelegate {
    private(set) var camera:VessageCamera!
    private var recordingTimer:NSTimer!
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
            recordButton.setImage(UIImage(named: "movie"), forState: .Normal)
            recordButton.setImage(UIImage(named: "movie"), forState: .Highlighted)
        }
    }
    
    override func onSwitchToManager() {
        rightButton.setImage(UIImage(named: "close"), forState: .Normal)
        rightButton.setImage(UIImage(named: "close"), forState: .Highlighted)
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        camera = VessageCamera()
        camera.delegate = self
        camera.initCamera(rootController,previewView: self.previewRectView)
        self.recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(RecordVessageManager.recordingFlashing(_:)), userInfo: nil, repeats: true)
    }
    
    func startRecord()
    {
        if camera.cameraInited{
            MobClick.event("RecordVessage")
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
    
    var prepareHud:MBProgressHUD!
    private func prepareSendRecord()
    {
        prepareHud = self.rootController.showActivityHud()
        camera.saveRecordedVideo()
    }
    
    private func confirmSend(url:NSURL){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            MobClick.event("ConfirmSendVessage")
            VessageQueue.sharedInstance.pushNewVessageTo(self.chatter.userId, receiverMobile: self.chatter.mobile, videoUrl: url)
        }
        let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (action) -> Void in
            MobClick.event("CancelSendVessage")
        }
        let size = PersistentFileHelper.fileSizeOf(url.path!)
        print("\(size/1024)kb")
        self.rootController.showAlert("CONFIRM_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
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
        self.prepareHud.hideAsync(true)
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
        self.prepareHud.hideAsync(true)
        self.rootController.playToast("SAVE_VIDEO_FAILED".localizedString())
    }
    
    override func onChatterUpdated(chatter: VessageUser) {
        self.updateChatImage(chatter.mainChatImage)
    }
    
    private func updateChatImage(mainChatImage:String?){
        if let imgView = self.smileFaceImageView{
            let defaultFace = UIImage(named: "defaultFace")!
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
        camera.cancelRecord()
        camera.closeCamera()
    }
}