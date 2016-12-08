//
//  RecordVessageVideoController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

protocol RecordVessageVideoControllerDelegate{
    func recordVessageVideoControllerCanceled(controller:RecordVessageVideoController)
    func recordVessageVideoControllerSaveVideoError(controller:RecordVessageVideoController)
    func recordVessageVideoController(videoSavedUrl:NSURL,isTimeUp:Bool, controller:RecordVessageVideoController)
}

class RecordVessageVideoControllerProxyBase :NSObject{
    var rootController:RecordVessageVideoController!
    
    var groupFaceImageViewContainer:UIView!{
        return rootController?.groupFaceContainer
    }
    
    var noSmileFaceTipsLabel: UILabel!{
        return rootController?.noSmileFaceTipsLabel
    }
    var recordingFlashView: UIView!{
        return rootController?.recordingFlashView
    }
    var recordingProgress:KDCircularProgress!{
        return rootController?.recordingProgress
    }
    var previewRectView: UIView!{
        return rootController?.previewRectView
    }
    
    var delegate:RecordVessageVideoControllerDelegate?{
        return rootController?.delegate
    }
    
    var isGroupChat:Bool{
        return rootController?.isGroupChat ?? false
    }
    
    var chatterId:String?{
        return rootController?.chatGroup?.groupId
    }
    
    
    func initManager(controller: RecordVessageVideoController){
        self.rootController = controller
    }
}

class RecordVessageVideoController: UIViewController {
    
    var delegate:RecordVessageVideoControllerDelegate?
    var isGroupChat:Bool = false
    var chatterId:String?
    
    
    //MARK: Record Views
    @IBOutlet weak var sendRecordButton: UIButton!{
        didSet{
            sendRecordButton.hidden = true
        }
    }
    @IBOutlet weak var cancelRecordButton: UIButton!
    
    @IBOutlet weak var previewRectView: UIView!{
        didSet{
            previewRectView.backgroundColor = UIColor.clearColor()
        }
    }
    
    @IBOutlet weak var recordingProgress: KDCircularProgress!{
        didSet{
            recordingProgress.layoutIfNeeded()
            recordingProgress.hidden = true
        }
    }
    
    @IBOutlet weak var recordingFlashView: UIView!{
        didSet{
            recordingFlashView.layoutIfNeeded()
            recordingFlashView.layer.cornerRadius = recordingFlashView.frame.size.height / 2
            recordingFlashView.hidden = true
        }
    }
    
    @IBOutlet weak var noSmileFaceTipsLabel: UILabel!
    @IBOutlet weak var groupFaceContainer: UIView!
    
    private(set) var recordVessageManager:RecordVessageManager!
    private(set) var isRecording:Bool = false
    @IBOutlet weak var recordViewContainer: UIView!
    
    var chatGroup:ChatGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recordVessageManager = RecordVessageManager()
        recordVessageManager.initManager(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.getAppService().addObserver(self, selector: #selector(RecordVessageVideoController.onAppResignActive(_:)), name: AppService.onAppResignActive, object: nil)
        if let cg = chatGroup{
            recordViewContainer.layoutIfNeeded()
            recordVessageManager?.onChatGroupUpdated(cg)
            recordVessageManager.onSwitchToManager()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        recordVessageManager.openCamera()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getAppService().removeObserver(self)
        recordVessageManager.onReleaseManager()
    }
    
    func onAppResignActive(_:AnyObject?) {
        if isRecording {
            self.recordVessageManager.cancelRecord()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

extension RecordVessageVideoController{
    static func startRecordVideo(vc:UIViewController,isGroupChat:Bool,chatGroup:ChatGroup, delegate:RecordVessageVideoControllerDelegate){
        let controller = instanceFromStoryBoard("Conversation", identifier: "RecordVessageVideoController") as! RecordVessageVideoController
        controller.delegate = delegate
        controller.isGroupChat = isGroupChat
        controller.chatGroup = chatGroup
        vc.presentViewController(controller, animated: true) {
        }
    }
}
