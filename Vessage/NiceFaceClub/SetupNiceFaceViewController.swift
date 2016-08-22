//
//  SetupNiceFaceViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/21.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import MBProgressHUD
import Alamofire
import EVReflection

class SetupNiceFaceViewController: UIViewController {

    @IBOutlet weak var faceScoreViewMask: UIView!{
        didSet{
            faceScoreViewMask.clipsToBounds = true
            faceScoreViewMask.layer.cornerRadius = faceScoreViewMask.frame.height / 2
        }
    }
    @IBOutlet weak var faceScoreLabel: UILabel!
    @IBOutlet weak var faceScoreView: UIProgressView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var retakePicButton: UIButton!
    @IBOutlet weak var selectPicButton: UIButton!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var acceptPicButton: UIButton!
    
    private var camera:VessageCamera!
    private var takedImageView:UIImageView!
    private var takedImage:UIImage?{
        didSet{
            if let chatImage = takedImage {
                let img = chatImage.scaleToWidthOf(ChatBackgroundPickerController.chatImageWidth)
                self.imageData = UIImageJPEGRepresentation(img, ChatBackgroundPickerController.chatImageQuality)
            }else{
                takedImageView?.image = nil
                takedImageView?.removeFromSuperview()
                imageData = nil
                faceScore = nil
                uploadedFileId = nil
            }
            refreshButtons()
        }
    }
    
    private var imageData:NSData!{
        didSet{
            if imageData != nil {
                faceScoreTest()
            }
        }
    }
    
    private var uploadedFileId:String? = nil
    
    private var faceScore:NiceFaceTestResult!{
        didSet{
            refreshFaceScoreView()
            refreshButtons()
        }
    }
    
    private var hud:MBProgressHUD?
    
    func initImageView() {
        if self.takedImageView == nil {
            takedImageView = UIImageView(frame: self.view.bounds)
            takedImageView.contentMode = .ScaleAspectFill
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSetChatImageObservers()
        refreshButtons()
        refreshFaceScoreView()
        shotButton.hidden = true
        camera = VessageCamera()
        camera.initCamera(self, previewView: self.previewView)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        camera.openCamera()
    }
    
    override func viewWillDisappear(animated: Bool) {
        camera.pauseCaptureSession()
    }
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }

}

extension SetupNiceFaceViewController{
    @IBAction func onCloseClick(sender: AnyObject) {
        self.dismissViewControllerAnimated(true){
            self.removeSetChatImageObservers()
            self.camera.closeCamera()
            self.camera = nil
        }
    }
    
    @IBAction func onSelectPicClick(sender: AnyObject) {
        showAlbum()
    }
    
    @IBAction func onRetakePicClick(sender: AnyObject) {
        takedImage = nil
        camera.resumeCaptureSession()
    }
    
    @IBAction func onShotClick(sender: AnyObject) {
        camera.takePicture()
    }
    
    @IBAction func onAcceptPicClick(sender: AnyObject) {
        if takedImage == nil {
            return
        }
        tryUpdateChatImages()
    }
}

class UploadResult:EVObject{
    var Host:String!
    var Url:String!
}

extension SetupNiceFaceViewController{
    
    func faceScoreTest() {
        self.view.userInteractionEnabled = false
        self.view.startScaningRepeatCount(20)
        let uploadUrl = "http://kan.msxiaobing.com/Api/Image/UploadBase64"
        
        
        Alamofire.upload(.POST, uploadUrl, data: imageData.base64String().toUTF8EncodingData()).responseString { (resp:Response<String, NSError>) in
            if resp.result.isSuccess{
                if let json = resp.result.value{
                    let returnObject = UploadResult(json:json)
                    NiceFaceClubManager.instance.faceScoreTest("\(returnObject.Host)\(returnObject.Url)", callback: { (result) in
                        self.view.stopScaning()
                        self.view.userInteractionEnabled = true
                        if let r = result{
                            self.faceScore = r
                            self.showAlert(nil, msg: r.msg)
                        }else{
                            self.playCrossMark("NETWORK_ERROR".localizedString())
                        }
                    })
                }
            }else{
                //self.view.stopScaning()
                self.view.userInteractionEnabled = true
                self.playCrossMark(""){
                }
            }
        }
    }
    
    private func addSetChatImageObservers(){
        
        BahamutTaskQueue.defaultInstance.addObserver(self, selector: #selector(SetupNiceFaceViewController.onTaskFinished(_:)), name: BahamutTaskQueue.onTaskFinished, object: nil)
        BahamutTaskQueue.defaultInstance.addObserver(self, selector: #selector(SetupNiceFaceViewController.onTaskStepError(_:)), name: BahamutTaskQueue.onTaskStepError, object: nil)
        BahamutTaskQueue.defaultInstance.addObserver(self, selector: #selector(SetupNiceFaceViewController.onTaskCanceled(_:)), name: BahamutTaskQueue.onTaskCanceled, object: nil)
    }
    
    private func removeSetChatImageObservers(){
        BahamutTaskQueue.defaultInstance.removeObserver(self)
    }
    
    private func tryUpdateChatImages(){
        
        hud = showAnimationHud()
        if let filePath = ChatBackgroundPickerController.saveChatImage(takedImage!){
            let flag = !ServiceContainer.getUserService().isUserChatBackgroundIsSeted || ServiceContainer.getUserService().myChatImages.count <= 0
            if flag {
                let task = SetChatImagesTask()
                task.filePath = filePath
                task.imageType = nil
                task.steps = [SendChatImageHandler.key]
                BahamutTaskQueue.defaultInstance.pushTask(task)
            }
        }else
        {
            hud?.hide(true)
            self.playToast("SET_CHAT_BCG_FAILED".localizedString())
        }
    }
    
    func onTaskFinished(a:NSNotification) {
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SetChatImagesTask{
            self.uploadedFileId = task.fileId
            if !ServiceContainer.getUserService().isUserChatBackgroundIsSeted{
                ServiceContainer.getUserService().setChatBackground(task.fileId, imageType: nil, callback: { (suc) in
                })
            }
            
            if ServiceContainer.getUserService().myChatImages.count <= 0 {
                ServiceContainer.getUserService().setChatBackground(task.fileId, imageType: defaultImageTypes.first?["type"], callback: { (suc) in
                })
            }
            
            NiceFaceClubManager.instance.setUserNiceFace(faceScore.resultId, imageId: task.fileId, callback: { (suc) in
                
            })
        }
    }
    
    func onTaskStepError(a:NSNotification) {
        hud?.hide(true)
        self.showAlert("SET_CHAT_BCG_FAILED".localizedString(), msg: nil)
    }
    
    func onTaskCanceled(a:NSNotification) {
        hud?.hide(true)
        self.showAlert("SET_CHAT_BCG_FAILED".localizedString(), msg: nil)
    }
}

extension SetupNiceFaceViewController{
    
    private func refreshFaceScoreView(){
        if let f = faceScore {
            faceScoreViewMask?.hidden = f.highScore <= 0
            faceScoreLabel?.text = "\(faceScore.highScore)"
            faceScoreView?.progress = faceScore.highScore / 10
        }else{
            faceScoreView?.progress = 0
            faceScoreViewMask?.hidden = true
        }
    }
    
    private func refreshButtons(){
        refreshShotButton()
        refreshAcceptPicButton()
        refreshRetakePicButton()
        refreshSelectPicButton()
    }
    
    private func refreshSelectPicButton(){
        selectPicButton?.hidden = !(takedImage == nil && UserSetting.godMode)
    }
    
    private func refreshRetakePicButton(){
        retakePicButton?.hidden = takedImage == nil
    }
    
    private func refreshAcceptPicButton() {
        acceptPicButton?.hidden = faceScore?.highScore ?? 0 < NiceFaceClubManager.minScore
    }
    
    private func refreshShotButton() {
        shotButton?.hidden = takedImage != nil
    }
}

extension SetupNiceFaceViewController:UIImagePickerControllerDelegate{
    
    private func showAlbum(){
        self.hud = self.showAnimationHud()
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) {
            self.hud?.hide(true)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        
        picker.dismissViewControllerAnimated(true)
        {
            if let imgData = UIImageJPEGRepresentation(image, 1.0){
                if let img = CIImage(data: imgData){
                    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
                    let faces = faceDetector.featuresInImage(img)
                    self.hud?.hide(true)
                    if faces.count >= 0{
                        self.camera.pauseCaptureSession()
                        self.initImageView()
                        self.takedImageView.image = image
                        self.view.addSubview(self.takedImageView)
                        self.view.exchangeSubviewAtIndex(self.view.subviews.count - 1, withSubviewAtIndex: 1)
                        self.takedImage = image
                        return
                    }
                }
            }
            self.hud?.hide(true)
            self.playToast("NO_HUMEN_FACES_DETECTED".localizedString())
        }
    }
}

extension SetupNiceFaceViewController:VessageCameraDelegate{
    func vessageCameraReady() {
        refreshShotButton()
    }
    
    func vessageCameraSessionClosed() {
        
    }
    
    func vessageCameraImage(image: UIImage) {
        self.camera.pauseCaptureSession()
        self.takedImage = image
    }
}