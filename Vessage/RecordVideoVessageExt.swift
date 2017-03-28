//
//  RecordVideoVessageExtension.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AVFoundation

extension ConversationViewController:RecordVessageVideoControllerDelegate{
    func startRecordVideoVessage() {
        let recordStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission()
        
        if recordStatus == .denied || microphoneStatus == .denied{
            let go = UIAlertAction(title: "GO_SETTING".localizedString(), style: .default, handler: { (ac) in
                if let url = URL(string: UIApplicationOpenSettingsURLString){
                    if UIApplication.shared.canOpenURL(url){
                        UIApplication.shared.openURL(url)
                    }
                }
            })
            self.showAlert("NEED_RECORD_PERMISSION".localizedString(), msg: "NEED_RECORD_PERMISSION_TIPS".localizedString(),actions: [ALERT_ACTION_CANCEL,go])
        }else{
            startRecord()
        }
    }
    
    fileprivate func startRecord(){
        RecordVessageVideoController.startRecordVideo(self, isGroupChat: isGroupChat, chatGroup: chatGroup, delegate: self)
    }
    
    func recordVessageVideoControllerCanceled(_ controller: RecordVessageVideoController) {
        
    }
    
    func recordVessageVideoControllerSaveVideoError(_ controller: RecordVessageVideoController) {
        self.showAlert("RECORD_VIDEO".localizedString(), msg: "SAVE_VIDEO_FAILED".localizedString())
    }
    
    func recordVessageVideoController(_ videoSavedUrl: URL, isTimeUp: Bool, controller: RecordVessageVideoController) {
        confirmSend(videoSavedUrl, isTimeUpRecord: isTimeUp)
    }
}

//MARK: Send Vessage
extension ConversationViewController{
    
    fileprivate func confirmSend(_ url:URL,isTimeUpRecord:Bool){
        #if DEBUG
            let size = PersistentFileHelper.fileSizeOf(url.path)
            print("Recorded Video Size:\(size/1024)KB")
        #endif
        if isTimeUpRecord {
            let okAction = UIAlertAction(title: "OK".localizedString(), style: .default) { (action) -> Void in
                self.pushNewVessageToQueue(url)
            }
            let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .cancel) { (action) -> Void in
                MobClick.event("Vege_CancelSendVessage")
            }
            self.showAlert("CONFIRM_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
        }else{
            pushNewVessageToQueue(url)
        }
    }
    
    fileprivate func pushNewVessageToQueue(_ url:URL){
        self.setProgressSending()
        let chatterId = self.conversation.chatterId
        let vsg = Vessage()
        vsg.typeId = Vessage.typeChatVideo
        vsg.fileId = url.path
        vsg.body = getSendVessageBodyString([:])
        #if DEBUG
            if isInSimulator() {
                PersistentFileHelper.deleteFile(url.path)
                vsg.fileId = "5790435e99cc251974a42f61"
                VessageQueue.sharedInstance.pushNewVessageTo(chatterId,isGroup: isGroupChat, vessage: vsg,taskSteps: SendVessageTaskSteps.normalVessageSteps)
            }else{
                VessageQueue.sharedInstance.pushNewVessageTo(chatterId,isGroup: isGroupChat, vessage: vsg,taskSteps:SendVessageTaskSteps.fileVessageSteps, uploadFileUrl: url)
            }
        #else
            VessageQueue.sharedInstance.pushNewVessageTo(chatterId,isGroup: isGroupChat, vessage: vsg,taskSteps:SendVessageTaskSteps.fileVessageSteps, uploadFileUrl: url)
        #endif
    }
}
