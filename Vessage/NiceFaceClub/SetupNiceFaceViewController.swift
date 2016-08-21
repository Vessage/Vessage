//
//  SetupNiceFaceViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/21.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import MBProgressHUD

class SetupNiceFaceViewController: UIViewController {

    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var retakePicButton: UIButton!
    @IBOutlet weak var selectPicButton: UIButton!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var acceptPicButton: UIButton!
    
    private var camera:VessageCamera!
    
    private var takedImage:UIImage?{
        didSet{
            refreshButtons()
        }
    }
    private var hud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshButtons()
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

extension SetupNiceFaceViewController{
    private func tryUpdateChatImages(){
        
    }
}

extension SetupNiceFaceViewController{
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
        previewView?.image = nil
        retakePicButton?.hidden = takedImage == nil
    }
    
    private func refreshAcceptPicButton() {
        acceptPicButton?.hidden = takedImage == nil
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        picker.dismissViewControllerAnimated(true)
        {
            if let imgData = UIImageJPEGRepresentation(image, 1.0){
                if let img = CIImage(data: imgData){
                    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
                    let faces = faceDetector.featuresInImage(img)
                    if faces.count >= 0{
                        self.camera.pauseCaptureSession()
                        self.takedImage = image
                        self.previewView.image = image
                        self.hud?.hide(true)
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