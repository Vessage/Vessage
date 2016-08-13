//
//  ChatBackgroundPickerController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/19.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MBProgressHUD

//typealias ChatBackgroundPickerSetImageSuccessHandler = (sender:ChatBackgroundPickerController)->Void
@objc protocol ChatBackgroundPickerControllerDelegate {
    optional func chatBackgroundPickerSetedImage(sender:ChatBackgroundPickerController)->Void
    optional func chatBackgroundPickerSetImageCancel(sender:ChatBackgroundPickerController)->Void
}

//MARK: ChatBackgroundPickerController
class ChatBackgroundPickerController: UIViewController,VessageCameraDelegate,ProgressTaskDelegate,UIImagePickerControllerDelegate{
    static let chatImageWidth:CGFloat = 480
    static let chatImageQuality:CGFloat = 0.6
    private var imagePickerController:UIImagePickerController = UIImagePickerController()
    
    weak private var delegate:ChatBackgroundPickerControllerDelegate!
    private var chatImageType:String? = nil
    private var previewRectView: UIView!{
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
            updateLeftButton()
            updateMiddleButton()
            updateRightButton()
        }
    }
    
    @IBOutlet weak var closeRecordViewButton: UIButton!{
        didSet{
            closeRecordViewButton.layer.cornerRadius = closeRecordViewButton.frame.size.height / 2
        }
    }
    
    @IBOutlet weak var leftButtonTip: UILabel!
    @IBOutlet weak var leftButton: UIImageView!{
        didSet{
            leftButton.userInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(ChatBackgroundPickerController.leftButtonClicked(_:)))
            leftButton.addGestureRecognizer(tap)
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
            if let img = takedImage{
                demoFaceView?.image = img
            }else{
                demoFaceView?.image = UIImage(named: "face")
            }
        }
    }
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = VessageCamera()
        camera.delegate = self
        camera.isRecordVideo = false
        camera.enableFaceMark = true
        previewRectView = UIView(frame: self.view.bounds)
        self.view.addSubview(previewRectView)
        self.view.sendSubviewToBack(previewRectView)
        camera.initCamera(self,previewView: self.previewRectView)
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
    func leftButtonClicked(sender: AnyObject) {
        if previewing {
            selectPictureFromAlbum()
        }else{
            previewing = true
            demoFaceView.hidden = true
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
    
    func rightButtonClicked(sender: AnyObject) {
        if !previewing{
            self.sendTakedImage()
        }
    }
    
    @IBAction func closeRecordView(sender: AnyObject) {
        camera.cancelRecord()
        camera.closeCamera()
        self.dismissViewControllerAnimated(false) { () -> Void in
            if let handler = self.delegate?.chatBackgroundPickerSetImageCancel{
                handler(self)
            }
        }
    }
    
    private func selectPictureFromAlbum()
    {
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
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
    
    private func updateLeftButton(){
        if previewing {
            leftButton?.image = UIImage(named: "select_chat_image")
        }else{
            leftButton?.image = UIImage(named: "shot_refresh")
        }
        leftButtonTip?.hidden = !previewing
    }
    
    private func updateRightButton(){
        if previewing{
            rightButton?.image = UIImage(named: "chat_image_demo_btn")
        }else{
            rightButton?.image = UIImage(named: "record_video_check")
        }
        rightTipsLabel?.hidden = !previewing
    }
    
    private func updateMiddleButton(){
        if previewing{
            middleButton?.setImage(UIImage(named: "camera_shot"), forState: .Normal)
            middleButton?.setImage(UIImage(named: "camera_shot"), forState: .Highlighted)
        }else{
            middleButton?.setImage(UIImage(named: "record_video_check"), forState: .Normal)
            middleButton?.setImage(UIImage(named: "record_video_check"), forState: .Highlighted)
        }
        middleButton?.hidden = !previewing
    }
    
    //MARK: VessageCamera Delegate
    
    func vessageCameraReady() {
        middleButton.hidden = false
        leftButton.hidden = false
    }
    
    func vessageCameraImage(image: UIImage) {
        self.takedImage = image
        self.previewing = false
    }
    
    //MARK: upload image
    private var taskFileMap = [String:FileAccessInfo]()
    private var taskHud:MBProgressHUD!
    private func sendTakedImage(){
        let fService = ServiceContainer.getService(FileService)
        let img = takedImage.scaleToWidthOf(ChatBackgroundPickerController.chatImageWidth)
        let imageData = UIImageJPEGRepresentation(img, ChatBackgroundPickerController.chatImageQuality)
        let localPath = fService.createLocalStoreFileName(FileType.Image)
        taskHud = self.showAnimationHud()
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
            uService.setChatBackground(fileKey.fileId, imageType:self.chatImageType,callback: { (isSuc) -> Void in
                self.taskHud.hideAsync(false)
                if isSuc{
                    let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) -> Void in
                        if let handler = self.delegate?.chatBackgroundPickerSetedImage{
                            handler(self)
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
    
    static func showPickerController(vc:UIViewController,delegate:ChatBackgroundPickerControllerDelegate,imageType:String? = nil)
    {
        let instance = instanceFromStoryBoard("Camera", identifier: "ChatBackgroundPickerController") as! ChatBackgroundPickerController
        instance.delegate = delegate
        instance.chatImageType = imageType
        vc.presentViewController(instance, animated: true) { () -> Void in
            
        }
    }
}