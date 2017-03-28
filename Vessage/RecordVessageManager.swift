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
class RecordVessageManager : RecordVessageVideoControllerProxyBase {
    
    //MARK: Properties
    fileprivate var camera:VessageCamera!
    fileprivate var recordingTimer:Timer!
    fileprivate var userClickSend = false
    fileprivate var recording = false{
        didSet{
            updateRecordingProgress()
            previewRectView?.isHidden = !recording
            recordingFlashView?.isHidden = !recording
        }
    }
    fileprivate let maxRecordTime:CGFloat = 16
    fileprivate var recordingTime:CGFloat = 0{
        didSet{
            if recordingProgress != nil{
                updateRecordingProgress()
            }
            if recordingTime == maxRecordTime{
                userClickSend = false
                prepareRecordedVideo()
            }
        }
    }
    fileprivate var groupAvatarManager:GroupChatAvatarManager!
}

//MARK: Manager Life Circle
extension RecordVessageManager{
    
    func onSwitchToManager() {
        groupAvatarManager.renderImageViews()
        groupAvatarManager.refreshFaces()
    }
    
    override func initManager(_ controller: RecordVessageVideoController) {
        super.initManager(controller)
        self.recordingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(RecordVessageManager.recordingFlashing(_:)), userInfo: nil, repeats: true)
        initCamera()
        groupAvatarManager = GroupChatAvatarManager()
        groupAvatarManager.initManager(self.groupFaceImageViewContainer)
        let tap = UITapGestureRecognizer(target: self, action: #selector(RecordVessageManager.onClickSendRecord(_:)))
        self.rootController.sendRecordButton.addGestureRecognizer(tap)
        
        let tapCancel = UITapGestureRecognizer(target: self, action: #selector(RecordVessageManager.onClickCancelRecordButton(_:)))
        self.rootController.cancelRecordButton.addGestureRecognizer(tapCancel)
    }
    
    fileprivate func initCamera(){
        camera = VessageCamera()
        camera.delegate = self
        self.previewRectView.isHidden = true
        camera.initCamera(rootController,previewView: self.previewRectView)
    }
    
    func onReleaseManager() {
        self.recordingTimer.invalidate()
        ServiceContainer.getVessageService().removeObserver(self)
        camera.cancelRecord()
        camera.closeCamera()
        camera = nil
        groupAvatarManager?.releaseManager()
        groupAvatarManager = nil
    }
}

//MARK: Chat Backgroud

class GroupChatAvatarManager:NSObject {
    fileprivate var avatarImageGroup = [UIImageView(),UIImageView(),UIImageView(),UIImageView(),UIImageView()]
    weak fileprivate var container:UIView!
    var userFaceIds = [String:String?]()
    func initManager(_ faceViewsContainer:UIView) {
        ServiceContainer.getUserService().addObserver(self, selector: #selector(GroupChatAvatarManager.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        self.container = faceViewsContainer
    }
    
    func releaseManager() {
        ServiceContainer.getUserService().removeObserver(self)
        avatarImageGroup.removeAll()
        container = nil
    }
    
    func hideContainer() {
        self.container?.isHidden = true
    }
    
    func showContainer() {
        self.container?.isHidden = false
    }
    
    func onUserProfileUpdated(_ a:Notification) {
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if userFaceIds.keys.contains(user.userId) {
                userFaceIds.updateValue(user.mainChatImage, forKey: user.userId)
                refreshFaces()
            }
        }
    }
    
    fileprivate func prepareImageView(_ count:Int){
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
    
    fileprivate func renderImageViews(){
        let count = self.userFaceIds.count
        if count == 1 {
            avatarImageGroup[0].frame = self.container.bounds
            return
        }
        
        var containerFrame = self.container.bounds
        if count > 1 {
            containerFrame = CGRect(x: containerFrame.origin.x, y: containerFrame.origin.y, width: containerFrame.width, height: containerFrame.height - 80)
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
            avatarImageGroup[0].frame = CGRect(x: 0, y: 0 , width: diam, height: diam)
            avatarImageGroup[1].frame = CGRect(x: containerFrame.width - diam, y: containerFrame.height - diam , width: diam, height: diam)
        }else if count == 3{
            diam = min(width, height)
            
            avatarImageGroup[0].frame = CGRect(x: width - diam, y: height - diam , width: diam, height: diam)
            avatarImageGroup[1].frame = CGRect(x: width, y: height - diam , width: diam, height: diam)
            avatarImageGroup[2].frame = CGRect(x: width - diam / 2, y: height , width: diam, height: diam)
        }else if count == 4{
            let diam = min(width, height)
            avatarImageGroup[0].frame = CGRect(x: width - diam, y: height - diam , width: diam, height: diam)
            avatarImageGroup[1].frame = CGRect(x: width, y: height - diam , width: diam, height: diam)
            avatarImageGroup[2].frame = CGRect(x: width - diam, y: height , width: diam, height: diam)
            avatarImageGroup[3].frame = CGRect(x: width, y: height , width: diam, height: diam)
        }else if count == 5{
            let diam = min(width, height)
            avatarImageGroup[0].frame = CGRect(x: 0, y: 0 , width: diam, height: diam)
            avatarImageGroup[1].frame = CGRect(x: containerFrame.width - diam , y: 0, width: diam, height: diam)
            avatarImageGroup[2].frame = CGRect(x: 0, y: containerFrame.height - diam , width: diam, height: diam)
            avatarImageGroup[3].frame = CGRect(x: containerFrame.width - diam , y: containerFrame.height - diam, width: diam, height: diam)
            avatarImageGroup[4].frame = CGRect(x: width - diam / 2, y: height - diam / 2 , width: diam, height: diam)
        }
    }
    
    func setFaces(_ userFaceIds:[String:String?]) {
        prepareImageView(userFaceIds.count)
        self.userFaceIds = userFaceIds
        refreshFaces()
    }
    
    fileprivate func refreshFaces(){
        let df = getDefaultFace()
        var i = 0
        self.userFaceIds.keys.forEach { (key) in
            let imgView = avatarImageGroup[i]
            let fileId = userFaceIds[key]!
            imgView.contentMode = String.isNullOrEmpty(fileId) ? .scaleAspectFit : .scaleAspectFill
            imgView.layoutIfNeeded()
            imgView.layer.cornerRadius = self.userFaceIds.count > 1 ? imgView.frame.width / 2 : 0
            imgView.clipsToBounds = self.userFaceIds.count > 1
            ServiceContainer.getFileService().setImage(imgView, iconFileId: fileId, defaultImage: df)
            i += 1
        }
    }
}

extension RecordVessageManager{

    func onChatGroupUpdated(_ chatGroup: ChatGroup) {
        
        var userFaceIds = [String:String?]()
        for userId in chatGroup.chatters {
            if userId == UserSetting.userId {
                continue
            }else if let user = ServiceContainer.getUserService().getCachedUserProfile(userId){
                userFaceIds.updateValue(user.mainChatImage, forKey: userId)
            }else{
                userFaceIds.updateValue(nil, forKey: userId)
            }
        }
        if isGroupChat {
            noSmileFaceTipsLabel.isHidden = true
        }else if let chatter = chatterId{
            noSmileFaceTipsLabel.isHidden = userFaceIds.keys.contains(chatter)
        }
        groupAvatarManager.setFaces(userFaceIds)
    }
}

//MARK: Send Vessage
extension RecordVessageManager{
    func onClickCancelRecordButton(_:UITapGestureRecognizer) {
        self.cancelRecord()
        self.rootController.dismiss(animated: true) { 
            self.delegate?.recordVessageVideoControllerCanceled(self.rootController)
        }
    }
    
    func onClickSendRecord(_:UITapGestureRecognizer) {
        prepareRecordedVideo()
    }
    
    fileprivate func prepareRecordedVideo()
    {
        if !recording {
            return
        }
        self.rootController.sendRecordButton.isUserInteractionEnabled = false
        #if DEBUG
            if isInSimulator(){
                recording = false
                let newFilePath = PersistentManager.sharedInstance.createTmpFileName(.video)
                PersistentFileHelper.storeFile(Data(), filePath: newFilePath)
                vessageCameraVideoSaved(videoSavedUrl: URL(fileURLWithPath: newFilePath))
            }else{
                camera.saveRecordedVideo()
            }
        #else
            camera.saveRecordedVideo()
        #endif
    }
}

//MARK: Camera And Record
extension RecordVessageManager:VessageCameraDelegate{

    func openCamera() {
        if !camera.cameraRunning {
            camera.openCamera()
        }
    }
    
    fileprivate func startRecord()
    {
        MobClick.event("Vege_RecordVessage")
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
    
    fileprivate func startSimulatorRecord(){
        userClickSend = true
        recordingTime = 0
        recording = true
    }
    
    fileprivate func startRealCameraRecord(){
        
        if self.camera.cameraInited{
            self.userClickSend = true
            self.camera.resumeCaptureSession()
            self.rootController.sendRecordButton.isHidden = true
            DispatchQueue.main.afterMS(100, handler: {   
                self.rootController.sendRecordButton.isHidden = false
                self.camera.startRecord()
            })
            
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
        startRecord()
    }
    
    func vessageCameraSessionClosed() {
    }
    
    func vessageCameraVideoSaved(videoSavedUrl video: URL) {
        self.rootController.sendRecordButton.isUserInteractionEnabled = true
        let newFilePath = PersistentManager.sharedInstance.createTmpFileName(.video)
        if PersistentFileHelper.moveFile(video.path, destinationPath: newFilePath)
        {
            self.rootController.dismiss(animated: true){
                self.delegate?.recordVessageVideoController(URL(fileURLWithPath: newFilePath), isTimeUp: !self.userClickSend, controller: self.rootController)
            }
        }else
        {
            self.rootController.dismiss(animated: true, completion: { 
                self.delegate?.recordVessageVideoControllerSaveVideoError(self.rootController)
            })
        }
    }
    
    func vessageCameraSaveVideoError(saveVideoError msg: String?) {
        self.rootController.sendRecordButton.isUserInteractionEnabled = true
        self.rootController.dismiss(animated: true, completion: {
            self.delegate?.recordVessageVideoControllerSaveVideoError(self.rootController)
        })
    }

    func recordingFlashing(_:AnyObject?){
        if recording{
            recordingFlashView.layer.cornerRadius = recordingFlashView.frame.size.height / 2
            recordingTime += 1
            self.recordingFlashView.isHidden = !self.recordingFlashView.isHidden
        }else{
            self.recordingFlashView.isHidden = true
        }
    }
    
    fileprivate func updateRecordingProgress(){
        let maxAngle:CGFloat = 360
        let angle = recordingTime / maxRecordTime * maxAngle
        self.recordingProgress?.angle = Double(angle)
        self.recordingProgress?.isHidden = !recording
    }
}
