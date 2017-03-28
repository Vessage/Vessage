//
//  RecordVessageVideoController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import KDCircularProgress

protocol RecordVessageVideoControllerDelegate{
    func recordVessageVideoControllerCanceled(_ controller:RecordVessageVideoController)
    func recordVessageVideoControllerSaveVideoError(_ controller:RecordVessageVideoController)
    func recordVessageVideoController(_ videoSavedUrl:URL,isTimeUp:Bool, controller:RecordVessageVideoController)
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
    
    
    func initManager(_ controller: RecordVessageVideoController){
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
            sendRecordButton.isHidden = true
        }
    }
    @IBOutlet weak var cancelRecordButton: UIButton!
    
    @IBOutlet weak var previewRectView: UIView!{
        didSet{
            previewRectView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet weak var recordingProgress: KDCircularProgress!{
        didSet{
            recordingProgress.layoutIfNeeded()
            recordingProgress.isHidden = true
        }
    }
    
    @IBOutlet weak var recordingFlashView: UIView!{
        didSet{
            recordingFlashView.layoutIfNeeded()
            recordingFlashView.layer.cornerRadius = recordingFlashView.frame.size.height / 2
            recordingFlashView.isHidden = true
        }
    }
    
    @IBOutlet weak var noSmileFaceTipsLabel: UILabel!
    @IBOutlet weak var groupFaceContainer: UIView!
    
    fileprivate(set) var recordVessageManager:RecordVessageManager!
    fileprivate(set) var isRecording:Bool = false
    @IBOutlet weak var recordViewContainer: UIView!
    
    var chatGroup:ChatGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recordVessageManager = RecordVessageManager()
        recordVessageManager.initManager(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.getAppService().addObserver(self, selector: #selector(RecordVessageVideoController.onAppResignActive(_:)), name:AppService.onAppResignActive, object: nil)
        if let cg = chatGroup{
            recordViewContainer.layoutIfNeeded()
            recordVessageManager?.onChatGroupUpdated(cg)
            recordVessageManager.onSwitchToManager()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        recordVessageManager.openCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getAppService().removeObserver(self)
        recordVessageManager.onReleaseManager()
    }
    
    func onAppResignActive(_:AnyObject?) {
        if isRecording {
            self.recordVessageManager.cancelRecord()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension RecordVessageVideoController{
    static func startRecordVideo(_ vc:UIViewController,isGroupChat:Bool,chatGroup:ChatGroup, delegate:RecordVessageVideoControllerDelegate){
        let controller = instanceFromStoryBoard("Conversation", identifier: "RecordVessageVideoController") as! RecordVessageVideoController
        controller.delegate = delegate
        controller.isGroupChat = isGroupChat
        controller.chatGroup = chatGroup
        vc.present(controller, animated: true) {
        }
    }
}
