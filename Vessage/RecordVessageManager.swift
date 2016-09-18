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
class RecordVessageManager: ConversationViewControllerProxy {
    
    //MARK: Properties
    private var camera:VessageCamera!
    private var recordingTimer:NSTimer!
    private var userClickSend = false
    private var recording = false{
        didSet{
            updateRecordButton()
            updateRecordingProgress()
            previewRectView?.hidden = !recording
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
    private var videoPreviewBubble:VideoPreviewBubble!
    private var groupAvatarManager:GroupChatAvatarManager!
}

//MARK: Manager Life Circle
extension RecordVessageManager{
    
    override func onSwitchToManager() {
        nextVessageButton.hidden = true
        rightButton.setImage(UIImage(named: "record_video_cross"), forState: .Normal)
        rightButton.setImage(UIImage(named: "record_video_cross"), forState: .Highlighted)
        rightButton.hidden = false
        groupAvatarManager.renderImageViews()
        groupAvatarManager.refreshFaces()
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        self.recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(RecordVessageManager.recordingFlashing(_:)), userInfo: nil, repeats: true)
        initCamera()
        groupAvatarManager = GroupChatAvatarManager()
        groupAvatarManager.initManager(self.groupFaceImageViewContainer)
        
    }
    
    private func initCamera(){
        camera = VessageCamera()
        camera.delegate = self
        self.previewRectView.hidden = true
        camera.initCamera(rootController,previewView: self.previewRectView.videoPreviewView)
    }
    
    override func onReleaseManager() {
        self.recordingTimer.invalidate()
        ServiceContainer.getVessageService().removeObserver(self)
        camera.cancelRecord()
        camera.closeCamera()
        camera = nil
        groupAvatarManager?.releaseManager()
        groupAvatarManager = nil
        super.onReleaseManager()
    }
}

//MARK: Chat Backgroud

class GroupChatAvatarManager:NSObject {
    private var avatarImageGroup = [UIImageView(),UIImageView(),UIImageView(),UIImageView(),UIImageView()]
    weak private var container:UIView!
    var userFaceIds = [String:String?]()
    func initManager(faceViewsContainer:UIView) {
        ServiceContainer.getUserService().addObserver(self, selector: #selector(GroupChatAvatarManager.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        self.container = faceViewsContainer
    }
    
    func releaseManager() {
        ServiceContainer.getUserService().removeObserver(self)
        avatarImageGroup.removeAll()
        container = nil
    }
    
    func hideContainer() {
        self.container?.hidden = true
    }
    
    func showContainer() {
        self.container?.hidden = false
    }
    
    func onUserProfileUpdated(a:NSNotification) {
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if userFaceIds.keys.contains(user.userId) {
                userFaceIds.updateValue(user.mainChatImage, forKey: user.userId)
                refreshFaces()
            }
        }
    }
    
    private func prepareImageView(count:Int){
        avatarImageGroup.forEach{
            $0.removeFromSuperview()
            $0.layer.cornerRadius = 0
        }
        for i in 0..<count {
            if i < self.avatarImageGroup.count {
                let imgView = avatarImageGroup[i]
                self.container.addSubview(imgView)
                imgView.image = nil
            }
        }
        renderImageViews()
    }
    
    private func renderImageViews(){
        let count = self.userFaceIds.count
        if count == 1 {
            avatarImageGroup[0].frame = self.container.bounds
            return
        }
        
        var containerFrame = self.container.frame
        if count > 1 {
            containerFrame = CGRectMake(containerFrame.origin.x, containerFrame.origin.y, containerFrame.width, containerFrame.height - 80)
        }
        var width = containerFrame.width / 2
        var height = containerFrame.height / 2
        var diam:CGFloat = 0
        if count == 2{
            
            if width < height {
                width = min(height,containerFrame.width)
            }else if height < width{
                height = min(width,containerFrame.height)
            }
            diam = min(width, height)
            avatarImageGroup[0].frame = CGRectMake(0, 0 , diam, diam)
            avatarImageGroup[1].frame = CGRectMake(containerFrame.width - diam, containerFrame.height - diam , diam, diam)
        }else if count == 3{
            diam = min(width, height)
            
            avatarImageGroup[0].frame = CGRectMake(width - diam, height - diam , diam, diam)
            avatarImageGroup[1].frame = CGRectMake(width, height - diam , diam, diam)
            avatarImageGroup[2].frame = CGRectMake(width - diam / 2, height , diam, diam)
        }else if count == 4{
            let diam = min(width, height)
            avatarImageGroup[0].frame = CGRectMake(width - diam, height - diam , diam, diam)
            avatarImageGroup[1].frame = CGRectMake(width, height - diam , diam, diam)
            avatarImageGroup[2].frame = CGRectMake(width - diam, height , diam, diam)
            avatarImageGroup[3].frame = CGRectMake(width, height , diam, diam)
        }else if count == 5{
            let diam = min(width, height)
            avatarImageGroup[0].frame = CGRectMake(0, 0 , diam, diam)
            avatarImageGroup[1].frame = CGRectMake(containerFrame.width - diam , 0, diam, diam)
            avatarImageGroup[2].frame = CGRectMake(0, containerFrame.height - diam , diam, diam)
            avatarImageGroup[3].frame = CGRectMake(containerFrame.width - diam , containerFrame.height - diam, diam, diam)
            avatarImageGroup[4].frame = CGRectMake(width - diam / 2, height - diam / 2 , diam, diam)
        }
    }
    
    func setFaces(userFaceIds:[String:String?]) {
        prepareImageView(userFaceIds.count)
        self.userFaceIds = userFaceIds
        refreshFaces()
    }
    
    private func refreshFaces(){
        let df = getDefaultFace()
        var i = 0
        self.userFaceIds.keys.forEach { (key) in
            let imgView = avatarImageGroup[i]
            let fileId = userFaceIds[key]!
            imgView.contentMode = String.isNullOrEmpty(fileId) ? .ScaleAspectFit : .ScaleAspectFill
            imgView.layer.cornerRadius = self.userFaceIds.count > 1 ? imgView.frame.width / 2 : 0
            imgView.clipsToBounds = self.userFaceIds.count > 1
            ServiceContainer.getFileService().setAvatar(imgView, iconFileId: fileId, defaultImage: df)
            i += 1
        }
    }
}

extension RecordVessageManager{
    override func onChatterUpdated(chatter: VessageUser) {
        noSmileFaceTipsLabel.hidden = chatter.mainChatImage != nil
        groupAvatarManager.setFaces([chatter.userId:chatter.mainChatImage])
    }
    
    override func onChatGroupUpdated(chatGroup: ChatGroup) {
        noSmileFaceTipsLabel.hidden = true
        let myUserId = self.rootController.userService.myProfile.userId
        var userFaceIds = [String:String?]()
        for userId in chatGroup.chatters {
            if userId == myUserId {
                continue
            }else if let user = self.rootController.userService.getCachedUserProfile(userId){
                userFaceIds.updateValue(user.mainChatImage, forKey: userId)
            }else{
                userFaceIds.updateValue(nil, forKey: userId)
            }
        }
        
        groupAvatarManager.setFaces(userFaceIds)
    }
}

//MARK: Send Vessage
extension RecordVessageManager{
    func sendVessage() {
        if recording {
            prepareSendRecord()
        }
    }
    
    private func prepareSendRecord()
    {
        recordButton.userInteractionEnabled = false
        #if DEBUG
            if isInSimulator(){
                recording = false
                let newFilePath = PersistentManager.sharedInstance.createTmpFileName(.Video)
                PersistentFileHelper.storeFile(NSData(), filePath: newFilePath)
                vessageCameraVideoSaved(videoSavedUrl: NSURL(fileURLWithPath: newFilePath))
            }else{
                camera.saveRecordedVideo()
            }
        #else
            camera.saveRecordedVideo()
        #endif
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
        let chatterId = self.conversation.chatterId
        let vsg = Vessage()
        vsg.isGroup = isGroupChat
        vsg.typeId = Vessage.typeVideo
        #if DEBUG
            PersistentFileHelper.deleteFile(url.path!)
            vsg.fileId = "5790435e99cc251974a42f61"
            VessageQueue.sharedInstance.pushNewVessageTo(chatterId, vessage: vsg,taskSteps: SendVessageTaskSteps.normalVessageSteps)
        #else
            VessageQueue.sharedInstance.pushNewVessageTo(chatterId, vessage: vsg,taskSteps:SendVessageTaskSteps.fileVessageSteps, uploadFileUrl: url)
        #endif
    }
}

//MARK: Camera And Record
extension RecordVessageManager:VessageCameraDelegate{
    func startRecord()
    {
        camera.openCamera()
        #if DEBUG
        if isInSimulator() {
            startSimulatorRecord()
        }else{
            startRealCameraRecord()
        }
        #else
            startRealCameraRecord()
        #endif
    }
    
    private func startSimulatorRecord(){
        userClickSend = true
        recordingTime = 0
        recording = true
    }
    
    private func startRealCameraRecord(){
        if camera.cameraInited{
            userClickSend = true
            MobClick.event("Vege_RecordVessage")
            camera.resumeCaptureSession()
            camera.startRecord()
        }else{
            self.rootController.playToast("CAMERA_NOT_INITED".localizedString())
        }
    }
    
    func cancelRecord() {
        #if DEBUG
            if isInSimulator() {
                recording = false
            }else{
                camera.cancelRecord()
            }
        #else
            camera.cancelRecord()
        #endif
        
    }
    
    //MARK: VessageCamera Delegate
    func vessageCameraDidStartRecord() {
        recordingTime = 0
        recording = true
    }
    
    func vessageCameraDidStopRecord() {
        recording = false
        camera.pauseCaptureSession()
    }
    
    func vessageCameraReady() {
        if !rootController.isRecording {
            camera.pauseCaptureSession()
        }
        recordButton.hidden = false
    }
    
    func vessageCameraSessionClosed() {
        //recordButton.hidden = true
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
        self.recordingProgress?.angle = angle
        self.recordingProgress?.hidden = !recording
    }
    
    private func updateRecordButton(){
        if recording{
            recordButton?.setImage(UIImage(named: "record_video_check"), forState: .Normal)
            recordButton?.setImage(UIImage(named: "record_video_check"), forState: .Highlighted)
        }else{
            recordButton?.setImage(UIImage(named: "chat"), forState: .Normal)
            recordButton?.setImage(UIImage(named: "chat"), forState: .Highlighted)
        }
    }
}