//
//  ChatBackgroundPickerController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/19.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MBProgressHUD

typealias ChatBackgroundPickerSetImageSuccessHandler = (sender:ChatBackgroundPickerController)->Void

//MARK: ChatBackgroundPickerController
class ChatBackgroundPickerController: UIViewController,VessageCameraDelegate,ProgressTaskDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    private var imagePickerController:UIImagePickerController = UIImagePickerController()
    @IBOutlet weak var selectPicButtonTip: UILabel!
    @IBOutlet weak var selectPicButton: UIButton!
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
    private var previewing:Bool = true{
        didSet{
            if previewing{
                camera?.resumeCaptureSession()
            }else{
                camera?.pauseCaptureSession()
            }
            updateSelectPicButton()
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
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ChatBackgroundPickerController.longPressRightButton(_:)))
            rightButton.addGestureRecognizer(longPress)
            let tap = UITapGestureRecognizer(target: self, action: #selector(ChatBackgroundPickerController.rightButtonClicked(_:)))
            
            tap.requireGestureRecognizerToFail(longPress)
            rightButton.addGestureRecognizer(tap)
        }
    }
    
    private var takedImage:UIImage!{
        didSet{
            demoFaceView.image = takedImage
        }
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = VessageCamera()
        camera.delegate = self
        camera.isRecordVideo = false
        camera.enableFaceMark = true
        camera.initCamera(self,previewView: self.previewRectView)
        self.view.bringSubviewToFront(demoFaceView)
        self.view.bringSubviewToFront(middleButton)
        self.view.bringSubviewToFront(closeRecordViewButton)
        self.view.bringSubviewToFront(rightButton)
        self.view.bringSubviewToFront(rightTipsLabel)
        self.view.bringSubviewToFront(selectPicButton)
        self.view.bringSubviewToFront(selectPicButtonTip)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        camera.openCamera()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    //MARK:notifications
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePickerController.dismissViewControllerAnimated(true)
        {
            if let imgData = UIImageJPEGRepresentation(image, 1.0){
                if let img = CIImage(data: imgData){
                    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
                    let faces = faceDetector.featuresInImage(img)
                    if faces.count > 0{
                        self.previewing = false
                        self.takedImage = image
                        self.demoFaceView.hidden = false
                        return
                    }
                }
            }
            self.playToast("NO_HUMEN_FACES_DETECTED".localizedString())
            
        
        }
    }
    
    //MARK: actions
    @IBAction func selectPicButtonClick(sender: AnyObject) {
        selectPictureFromAlbum()
    }
    
    private func selectPictureFromAlbum()
    {
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func rightButtonClicked(sender: AnyObject) {
        if previewing == false{
            previewing = true
            demoFaceView.hidden = true
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
            if camera.detectedFaces{
                SystemSoundHelper.cameraShutter()
                self.camera.takePicture()
            }else{
                self.playToast("NO_HUMEN_FACES_DETECTED".localizedString())
            }
        }else{
            self.sendTakedImage()
        }
    }
    
    func longPressRightButton(ges:UILongPressGestureRecognizer){
        if previewing{
            if ges.state == .Began{
                showDemoFace()
            }else if ges.state == .Ended{
                demoFaceView.hidden = true
            }
        }
    }
    
    private func showDemoFace(){
        demoFaceView.image = UIImage(named: "face")
        demoFaceView.hidden = false
    }
    
    private func updateSelectPicButton(){
        
        selectPicButton?.hidden = !previewing
        selectPicButtonTip?.hidden = selectPicButton.hidden
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
            middleButton?.setImage(UIImage(named: "checkRound"), forState: .Normal)
            middleButton?.setImage(UIImage(named: "checkRound"), forState: .Highlighted)
        }
    }
    
    //MARK: VessageCamera Delegate
    
    func vessageCameraReady() {
        middleButton.hidden = false
        selectPicButton.hidden = false
    }
    
    func vessageCameraImage(image: UIImage) {
        self.takedImage = image
        self.previewing = false
        demoFaceView.hidden = false
    }
    
    //MARK: upload image
    private var taskFileMap = [String:FileAccessInfo]()
    private var taskHud:MBProgressHUD!
    private func sendTakedImage(){
        let fService = ServiceContainer.getService(FileService)
        let img = takedImage.scaleToWidthOf(480)
        let imageData = UIImageJPEGRepresentation(img, 0.7)
        let localPath = fService.createLocalStoreFileName(FileType.Image)
        taskHud = self.showActivityHud()
        if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
        {
            fService.sendFileToAliOSS(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                if let fk = fileKey
                {
                    self.taskFileMap[taskId] = fk
                }else{
                    self.taskHud.hideAsync(false)
                }
            })
        }else
        {
            taskHud.hideAsync(false)
            self.playToast("SET_CHAT_BCG_FAILED".localizedString())
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let fileKey = taskFileMap.removeValueForKey(taskIdentifier)
        {
            let uService = ServiceContainer.getUserService()
            uService.setChatBackground(fileKey.fileId, callback: { (isSuc) -> Void in
                self.taskHud.hideAsync(false)
                if isSuc{
                    let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) -> Void in
                        if let handler = self.setImageSuccessHandler{
                            handler(sender: self)
                        }
                    })
                    self.showAlert("SET_CHAT_BCG_SUCCESS".localizedString(), msg: nil , actions: [okAction])
                }else{
                    self.showAlert("SET_CHAT_BCG_FAILED".localizedString(), msg: nil)
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        taskHud.hideAsync(false)
        taskFileMap.removeValueForKey(taskIdentifier)
        self.showAlert(nil, msg: "SET_CHAT_BCG_FAILED".localizedString())
    }
    
    //MARK: showPickerController
    
    static func showPickerController(vc:UIViewController,setImageSuccessHandler:ChatBackgroundPickerSetImageSuccessHandler)
    {
        let instance = instanceFromStoryBoard("Camera", identifier: "ChatBackgroundPickerController") as! ChatBackgroundPickerController
        instance.setImageSuccessHandler = setImageSuccessHandler
        vc.presentViewController(instance, animated: true) { () -> Void in
            
        }
    }
}