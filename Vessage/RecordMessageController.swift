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
    
    let userService = ServiceContainer.getUserService()
    private(set) static var instance:RecordMessageController!
    
    private var chatter:VessageUser!{
        didSet{
            self.updateChatImage(chatter?.mainChatImage)
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
    private let maxRecordTime:CGFloat = 16
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
    @IBOutlet weak var noSmileFaceTipsLabel: UILabel!
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
        self.view.bringSubviewToFront(recordingProgress)
        self.view.bringSubviewToFront(recordingFlashView)
        self.view.bringSubviewToFront(recordButton)
        self.view.bringSubviewToFront(closeRecordViewButton)
        self.view.bringSubviewToFront(cancelRecordButton)
        userService.addObserver(self, selector: #selector(RecordMessageController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(RecordMessageController.recordingFlashing(_:)), userInfo: nil, repeats: true)
        updateChatImage(self.chatter?.mainChatImage)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.recordingTimer.invalidate()
        self.recordingTimer = nil
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
            if VessageUser.isTheSameUser(chatter, userb: self.chatter){
                self.chatter = chatter
            }
        }
    }
    
    //MARK: actions
    func updateChatImage(mainChatImage:String?){
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
    
    @IBAction func cancelRecord(sender: AnyObject) {
        camera.cancelRecord()
        self.playToast("CANCEL_RECORD".localizedString())
    }
    
    @IBAction func closeRecordView(sender: AnyObject) {
        camera.cancelRecord()
        camera.closeCamera()
        self.dismissViewControllerAnimated(false) { () -> Void in
            self.chatter = nil
        }
    }
    
    @IBAction func recordButtonClicked(sender: AnyObject) {
        if self.recording{
            self.prepareSendRecord()
        }else{
            SystemSoundHelper.keyTink()
            self.startRecord()
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
    
    private func startRecord()
    {
        MobClick.event("Vege_RecordVessage")
        camera.startRecord()
    }
    
    var prepareHud:MBProgressHUD!
    private func prepareSendRecord()
    {
        prepareHud = self.showActivityHud()
        camera.saveRecordedVideo()
    }
    
    private func confirmSend(url:NSURL){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            MobClick.event("Vege_ConfirmSendVessage")
            VessageQueue.sharedInstance.pushNewVessageTo(self.chatter.userId, receiverMobile: self.chatter.mobile, videoUrl: url)
        }
        let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (action) -> Void in
            MobClick.event("Vege_CancelSendVessage")
        }
        let size = PersistentFileHelper.fileSizeOf(url.path!)
        print("\(size/1024)kb")
        self.showAlert("CONFIRM_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
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
            self.showAlert("SAVE_VIDEO_FAILED".localizedString(), msg: "")
        }
    }
    
    func vessageCameraSaveVideoError(saveVideoError msg: String?) {
        self.prepareHud.hideAsync(true)
        self.playToast("SAVE_VIDEO_FAILED".localizedString())
    }
    
    static func showRecordMessageController(vc:UIViewController,chatter:VessageUser)
    {
        if RecordMessageController.instance == nil{
            RecordMessageController.instance = instanceFromStoryBoard("Camera", identifier: "RecordMessageController") as! RecordMessageController
        }
        instance.chatter = chatter
        vc.presentViewController(instance, animated: true) { () -> Void in
            if String.isNullOrWhiteSpace(chatter.userId) == false && String.isNullOrWhiteSpace(chatter.mainChatImage){
                ServiceContainer.getUserService().fetchUserProfile(chatter.userId)
            }
        }
    }
}
