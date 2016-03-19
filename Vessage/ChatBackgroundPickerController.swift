//
//  ChatBackgroundPickerController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/19.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ChatBackgroundPickerController: UIViewController,VessageCameraDelegate {
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
            //accept
            print("accept")
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
        self.previewRectView.image = image
        previewing = false
    }
    
    static func showPickerController(vc:UIViewController)
    {
        
        let instance = instanceFromStoryBoard("Main", identifier: "ChatBackgroundPickerController") as! ChatBackgroundPickerController
        vc.presentViewController(instance, animated: true) { () -> Void in
            
        }
    }
}