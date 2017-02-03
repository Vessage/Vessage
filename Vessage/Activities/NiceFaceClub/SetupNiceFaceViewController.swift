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

    static let imageWidth:CGFloat = 480
    static let imageQuality:CGFloat = 0.6
    static func saveImage(image:UIImage) -> String?{
        let img = image.scaleToWidthOf(imageWidth)
        let imageData = UIImageJPEGRepresentation(img, imageQuality)
        let localPath = PersistentManager.sharedInstance.createTmpFileName(FileType.Image)
        return PersistentFileHelper.storeFile(imageData!, filePath: localPath) ? localPath : nil
    }
    
    @IBOutlet weak var faceScoreViewMask: UIView!{
        didSet{
            faceScoreViewMask.layoutIfNeeded()
            faceScoreViewMask.clipsToBounds = true
            faceScoreViewMask.layer.cornerRadius = faceScoreViewMask.frame.height / 2
        }
    }
    @IBOutlet weak var faceScoreLabel: UILabel!
    @IBOutlet weak var faceScoreView: UIProgressView!{
        didSet{
            self.faceScoreView.superview?.layoutIfNeeded()
            self.faceScoreView.superview?.clipsToBounds = true
            self.faceScoreView.superview?.layer.cornerRadius = self.faceScoreView.superview!.frame.height / 2
        }
    }
    
    private var previewView: UIView!
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
                let img = chatImage.scaleToWidthOf(SetupNiceFaceViewController.imageWidth)
                self.imageData = UIImageJPEGRepresentation(img, SetupNiceFaceViewController.imageQuality)
            }else{
                takedImageView?.image = nil
                takedImageView?.removeFromSuperview()
                imageData = nil
                faceScore = nil
                uploadedFileId = nil
                niceFaceUploadResult = nil
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
    
    private var niceFaceUploadResult:NiceFaceUploadResult!
    private var uploadedFileId:String? = nil
    
    private var faceScore:NiceFaceTestResult!{
        didSet{
            refreshFaceScoreView()
            refreshButtons()
        }
    }
    
    private var hud:MBProgressHUD?
    
    private var faceScoreAddtion:Float = 0.0
    
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
        self.previewView = UIView(frame: self.view.bounds)
        self.view.addSubview(previewView)
        self.view.sendSubviewToBack(previewView)
        camera = VessageCamera()
        camera.delegate = self
        camera.isRecordVideo = false
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
    
    static func instanceFromStoryBoard() -> SetupNiceFaceViewController{
        return instanceFromStoryBoard("NiceFaceClub", identifier: "SetupNiceFaceViewController") as! SetupNiceFaceViewController
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
        if let imageId = uploadedFileId {
            setNiceFace(imageId)
        }else{
            pushSetNiceFaceUploadTask()
        }
    }
}

class NiceFaceUploadResult:EVObject{
    var Host:String!
    var Url:String!
}



extension SetupNiceFaceViewController{
    
    private func faceScoreTest() {
        self.view.userInteractionEnabled = false
        self.view.startScaningRepeatCount(20)
        self.closeButton?.hidden = true
        if niceFaceUploadResult == nil {
            uploadFaceImage()
        }else{
            getFaceScoreTestResult()
        }
    }
    
    private func uploadFaceImage(){
        self.retakePicButton?.hidden = true
        let uploadUrl = "http://kan.msxiaobing.com/Api/Image/UploadBase64"
        Alamofire.upload(.POST, uploadUrl,headers: ["User-Agent":"Mozilla/5.0"], data: imageData.base64String().toUTF8EncodingData()).responseString { (resp:Response<String, NSError>) in
            if resp.result.isSuccess{
                if let json = resp.result.value{
                    let returnObject = NiceFaceUploadResult(json:json)
                    self.niceFaceUploadResult = returnObject
                    self.getFaceScoreTestResult()
                }
            }else{
                self.showRetryAlert()
            }
        }
    }
    
    private func showRetryAlert(){
        self.view.stopScaning()
        self.view.userInteractionEnabled = true
        let ok = UIAlertAction(title: "OK".localizedString(), style: .Default) { (ac) in
            self.faceScoreTest()
        }
        
        let cancel = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (ac) in
            self.closeButton?.hidden = false
            self.onRetakePicClick(ac)
        }
        
        self.showAlert("NETWORK_ERROR".localizedString(), msg: "RETRY_TEST_FACE".niceFaceClubString, actions: [ok,cancel])
    }
    
    private func getFaceScoreTestResult() {
        self.retakePicButton?.hidden = true
        self.closeButton?.hidden = true
        let imgUrl = "\(niceFaceUploadResult.Host)\(niceFaceUploadResult.Url)"
        NiceFaceClubManager.instance.faceScoreTest(imgUrl,addtion: faceScoreAddtion, callback: { (result) in
            if let r = result{
                self.faceScore = r
                self.view.stopScaning()
                self.closeButton?.hidden = false
                self.view.userInteractionEnabled = true
                let pass = r.hs >= NiceFaceClubManager.minScore
                let alert = NFCMessageAlert.showNFCMessageAlert(self, title: "NICE_FACE_CLUB".niceFaceClubString, message: r.msg)
                if pass{
                    alert.shareButton.setTitle("INVITE_FRIENDS".niceFaceClubString, forState: .Normal)
                    alert.shareTipsLabel.text = "PASS_SHARE_TIPS".niceFaceClubString
                }
                let btnTitle = pass ? "CONTINUE".niceFaceClubString : "CONTINUE_FACE_TEST".niceFaceClubString
                alert.continueButton.setTitle(btnTitle, forState: .Normal)
                alert.onSharedHandler = { nfcc in
                    self.faceScoreAddtion = 0.1
                }
                alert.onTestScoreHandler = { nfcc in
                    nfcc.dismissViewControllerAnimated(true, completion: {
                        if pass{
                            UIAnimationHelper.flashView(self.acceptPicButton!, duration: 0.2, autoStop: true, stopAfterMs: 3000, completion: nil)
                        }else{
                            self.onRetakePicClick(nfcc)
                        }
                    })
                }
            }else{
                self.showRetryAlert()
            }
        })
    }
    
    private func addSetChatImageObservers(){
        
        BahamutTaskQueue.defaultInstance.addObserver(self, selector: #selector(SetupNiceFaceViewController.onTaskFinished(_:)), name: BahamutTaskQueue.onTaskFinished, object: nil)
        BahamutTaskQueue.defaultInstance.addObserver(self, selector: #selector(SetupNiceFaceViewController.onTaskStepError(_:)), name: BahamutTaskQueue.onTaskStepError, object: nil)
        BahamutTaskQueue.defaultInstance.addObserver(self, selector: #selector(SetupNiceFaceViewController.onTaskCanceled(_:)), name: BahamutTaskQueue.onTaskCanceled, object: nil)
    }
    
    private func removeSetChatImageObservers(){
        BahamutTaskQueue.defaultInstance.removeObserver(self)
    }
    
    private func pushSetNiceFaceUploadTask(){
        
        hud = showActivityHud()
        if let filePath = SetupNiceFaceViewController.saveImage(takedImage!){
            let task = SetChatImagesTask()
            task.filePath = filePath
            task.imageType = nil
            task.steps = [SendChatImageHandler.key]
            BahamutTaskQueue.defaultInstance.pushTask(task)
        }else
        {
            hud?.hideAnimated(true)
            self.playCrossMark("SAVE_IMAGE_ERROR".localizedString())
        }
    }
    
    func onTaskFinished(a:NSNotification) {
        
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SetChatImagesTask{
            self.uploadedFileId = task.fileId
            if !ServiceContainer.getUserService().isUserChatBackgroundIsSeted{
                ServiceContainer.getUserService().setChatBackground(task.fileId, imageType: nil, callback: { (suc) in
                })
            }
            self.setNiceFace(task.fileId)
        }
    }
    
    func setNiceFace(imageId:String) {
        NiceFaceClubManager.instance.setUserNiceFace(faceScore, imageId: imageId, callback: { (suc) in
            self.hud?.hideAnimated(true)
            if suc{
                let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                    self.onCloseClick(self)
                })
                self.showAlert("NICE_FACE_SETTED".niceFaceClubString, msg: "NICE_FACE_SETTED_MSG".niceFaceClubString, actions: [ok])
            }else{
                self.playCrossMark("SET_NICE_FACE_ERROR".niceFaceClubString)
            }
        })
    }
    
    func onTaskStepError(a:NSNotification) {
        hud?.hideAnimated(true)
        self.showAlert("UPLOAD_NICE_FACE_IMAGE_ERROR".localizedString(), msg: nil)
    }
    
    func onTaskCanceled(a:NSNotification) {
        hud?.hideAnimated(true)
        self.showAlert("UPLOAD_NICE_FACE_IMAGE_CANCELED".localizedString(), msg: nil)
    }
}

extension SetupNiceFaceViewController{
    
    private func refreshFaceScoreView(){
        if let f = faceScore {
            faceScoreView?.progressTintColor = f.highScore >= NiceFaceClubManager.minScore ? UIColor.orangeColor() : UIColor.redColor()
            faceScoreViewMask?.hidden = f.highScore <= 0
            faceScoreLabel?.text = "\(f.highScore)"
            faceScoreView?.setProgress(f.highScore / 10, animated: true)
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
        acceptPicButton?.hidden = (faceScore?.highScore ?? 0) < NiceFaceClubManager.minScore
    }
    
    private func refreshShotButton() {
        shotButton?.hidden = takedImage != nil
    }
}

extension SetupNiceFaceViewController:UIImagePickerControllerDelegate{
    
    private func showAlbum(){
        self.hud = self.showActivityHud()
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) {
            self.hud?.hideAnimated(true)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        
        picker.dismissViewControllerAnimated(true)
        {
            if let imgData = UIImageJPEGRepresentation(image, 1.0){
                if let img = CIImage(data: imgData){
                    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                    let faces = faceDetector.featuresInImage(img)
                    self.hud?.hideAnimated(true)
                    if faces.count > 0{
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
            self.hud?.hideAnimated(true)
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
