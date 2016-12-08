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
        let recordStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission()
        
        if recordStatus == .Denied || microphoneStatus == .Denied{
            let go = UIAlertAction(title: "GO_SETTING".localizedString(), style: .Default, handler: { (ac) in
                if let url = NSURL(string: UIApplicationOpenSettingsURLString){
                    if UIApplication.sharedApplication().canOpenURL(url){
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
            })
            self.showAlert("NEED_RECORD_PERMISSION".localizedString(), msg: "NEED_RECORD_PERMISSION_TIPS".localizedString(),actions: [ALERT_ACTION_CANCEL,go])
        }else{
            startRecord()
        }
    }
    
    private func startRecord(){
        RecordVessageVideoController.startRecordVideo(self, isGroupChat: isGroupChat, chatGroup: chatGroup, delegate: self)
    }
    
    func recordVessageVideoControllerCanceled(controller: RecordVessageVideoController) {
        
    }
    
    func recordVessageVideoControllerSaveVideoError(controller: RecordVessageVideoController) {
        self.showAlert("RECORD_VIDEO".localizedString(), msg: "SAVE_VIDEO_FAILED".localizedString())
    }
    
    func recordVessageVideoController(videoSavedUrl: NSURL, isTimeUp: Bool, controller: RecordVessageVideoController) {
        confirmSend(videoSavedUrl, isTimeUpRecord: isTimeUp)
    }
}

//MARK: Send Vessage
extension ConversationViewController{
    
    private func confirmSend(url:NSURL,isTimeUpRecord:Bool){
        #if DEBUG
            let size = PersistentFileHelper.fileSizeOf(url.path!)
            print("Recorded Video Size:\(size/1024)KB")
        #endif
        if isTimeUpRecord {
            let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
                self.pushNewVessageToQueue(url)
            }
            let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (action) -> Void in
                MobClick.event("Vege_CancelSendVessage")
            }
            self.showAlert("CONFIRM_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
        }else{
            pushNewVessageToQueue(url)
        }
    }
    
    private func pushNewVessageToQueue(url:NSURL){
        self.setProgressSending()
        let chatterId = self.conversation.chatterId
        let vsg = Vessage()
        vsg.typeId = Vessage.typeChatVideo
        vsg.body = getSendVessageBodyString([:])
        #if DEBUG
            if isInSimulator() {
                PersistentFileHelper.deleteFile(url.path!)
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
