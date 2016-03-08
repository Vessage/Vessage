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

    private static var instance:RecordMessageController!
    private var conversation:ConversationViewModel!
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
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        camera.openCamera()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
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
        if recording{
            prepareSendRecord()
        }else{
            startRecord()
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
        VessageQueue.sharedInstance.pushNewVideoTo(self.conversation.id, fileUrl:url)
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
    
    func vessageCamera(videoSavedUrl: NSURL) {
        self.sendingHud.hideAsync(true)
        let size = PersistentFileHelper.fileSizeOf(videoSavedUrl.path!)
        print("\(size/1024)kb")
        confirmSend(videoSavedUrl)
    }
    
    static func showRecordMessageController(vc:UIViewController,conversation:ConversationViewModel)
    {
        if RecordMessageController.instance == nil{
            RecordMessageController.instance = instanceFromStoryBoard("Main", identifier: "RecordMessageController") as! RecordMessageController
        }
        instance.conversation = conversation
        vc.presentViewController(instance, animated: true) { () -> Void in
            
        }
    }
}
