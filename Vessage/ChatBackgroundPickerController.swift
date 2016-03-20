//
//  ChatBackgroundPickerController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/19.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

typealias ChatBackgroundPickerSetImageSuccessHandler = (sender:ChatBackgroundPickerController)->Void

//MARK: ChatBackgroundPickerController
class ChatBackgroundPickerController: UIViewController,VessageCameraDelegate,ProgressTaskDelegate {
    private var setImageSuccessHandler:ChatBackgroundPickerSetImageSuccessHandler!
    @IBOutlet weak var previewRectView: UIImageView!{
        didSet{
            previewRectView.backgroundColor = UIColor.clearColor()
        }
    }

    @IBOutlet weak var demoFaceView: UIImageView!{
        didSet{
            demoFaceView.hidden = true
        }
    }
    private var camera:VessageCamera!
    var previewing:Bool = true{
        didSet{
            if previewing{
                camera?.resumeCaptureSession()
            }else{
                camera?.pauseCaptureSession()
            }
            updateMiddleButton()
            updateRightButton()
        }
    }
    
    @IBOutlet weak var closeRecordViewButton: UIButton!{
        didSet{
            closeRecordViewButton.layer.cornerRadius = closeRecordViewButton.frame.size.height / 2
        }
    }
    @IBOutlet weak var middleButton: UIButton!{
        didSet{
            middleButton.hidden = true
            middleButton.layer.cornerRadius = middleButton.frame.size.height / 2
        }
    }
    
    @IBOutlet weak var rightTipsLabel: UILabel!
    @IBOutlet weak var rightButton: UIImageView!{
        didSet{
            rightButton.layer.cornerRadius = rightButton.frame.size.height / 2
            rightButton.hidden = !previewing
            rightButton.userInteractionEnabled = true
            let longPress = UILongPressGestureRecognizer(target: self, action: "longPressRightButton:")
            rightButton.addGestureRecognizer(longPress)
            let tap = UITapGestureRecognizer(target: self, action: "rightButtonClicked:")
            tap.requireGestureRecognizerToFail(longPress)
            rightButton.addGestureRecognizer(tap)
        }
    }
    
    private var takedImage:UIImage!{
        didSet{
            self.previewRectView.image = takedImage
        }
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = VessageCamera()
        camera.delegate = self
        camera.isRecordVideo = false
        camera.initCamera(self,previewView: self.previewRectView)
        self.view.bringSubviewToFront(middleButton)
        self.view.bringSubviewToFront(closeRecordViewButton)
        self.view.bringSubviewToFront(rightButton)
        self.view.bringSubviewToFront(rightTipsLabel)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        camera.openCamera()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    //MARK:notifications
    
    //MARK: actions
    
    func rightButtonClicked(sender: AnyObject) {
        if previewing == false{
            previewing = true
        }
    }
    
    @IBAction func closeRecordView(sender: AnyObject) {
        camera.cancelRecord()
        camera.closeCamera()
        self.dismissViewControllerAnimated(false) { () -> Void in
        }
    }
    
    @IBAction func middleButtonClicked(sender: AnyObject) {
        if self.previewing{
            self.camera.takePicture()
        }else{
            self.sendTakedImage()
        }
    }
    
    func longPressRightButton(ges:UILongPressGestureRecognizer){
        if previewing{
            if ges.state == .Began{
                demoFaceView.hidden = false
                self.view.bringSubviewToFront(demoFaceView)
            }else if ges.state == .Ended{
                demoFaceView.hidden = true
            }
        }
    }
    
    private func updateRightButton(){
        rightTipsLabel.hidden = !previewing
        if previewing{
            rightButton.image = UIImage(named: "profile")
        }else{
            rightButton.image = UIImage(named: "refreshRound")
        }
    }
    
    private func updateMiddleButton(){
        if previewing{
            middleButton?.setImage(UIImage(named: "camera"), forState: .Normal)
            middleButton?.setImage(UIImage(named: "camera"), forState: .Highlighted)
        }else{
            middleButton?.setImage(UIImage(named: "check"), forState: .Normal)
            middleButton?.setImage(UIImage(named: "check"), forState: .Highlighted)
        }
    }
    
    //MARK: VessageCamera Delegate
    
    func vessageCameraReady() {
        middleButton.hidden = false
    }
    
    func vessageCameraImage(image: UIImage) {
        self.takedImage = image
        previewing = false
    }
    
    //MARK: upload image
    private var taskFileMap = [String:FileAccessInfo]()
    
    private func sendTakedImage(){
        let fService = ServiceContainer.getService(FileService)
        let imageData = UIImageJPEGRepresentation(self.takedImage, 0.7)
        let localPath = fService.createLocalStoreFileName(FileType.Image)
        if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
        {
            fService.sendFileToAliOSS(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                if let fk = fileKey
                {
                    self.taskFileMap[taskId] = fk
                }
            })
        }else
        {
            self.playToast("SET_CHAT_BCG_FAILED".localizedString())
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let fileKey = taskFileMap.removeValueForKey(taskIdentifier)
        {
            let uService = ServiceContainer.getService(UserService)
            uService.setChatBackground(fileKey.fileId, callback: { (isSuc) -> Void in
                if isSuc{
                    let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) -> Void in
                        if let handler = self.setImageSuccessHandler{
                            handler(sender: self)
                        }
                    })
                    self.showAlert(nil, msg: "SET_CHAT_BCG_SUCCESS".localizedString(), actions: [okAction])
                }else{
                    self.showAlert(nil, msg: "SET_CHAT_BCG_FAILED".localizedString())
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        taskFileMap.removeValueForKey(taskIdentifier)
        self.showAlert(nil, msg: "SET_CHAT_BCG_FAILED".localizedString())
    }
    
    //MARK: showPickerController
    
    static func showPickerController(vc:UIViewController,setImageSuccessHandler:ChatBackgroundPickerSetImageSuccessHandler)
    {
        let instance = instanceFromStoryBoard("Main", identifier: "ChatBackgroundPickerController") as! ChatBackgroundPickerController
        instance.setImageSuccessHandler = setImageSuccessHandler
        vc.presentViewController(instance, animated: true) { () -> Void in
            
        }
    }
}