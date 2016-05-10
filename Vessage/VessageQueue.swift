//
//  VessageQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import MessageUI

class SendVessageFileStep:BahamutTaskStepWorker{
    func taskStepStart(task: BahamutTask, step: BahamutTaskStep, taskModel: BahamutTaskModel) {
        let model = SendVessageTaskInfo(json: taskModel.taskUserInfo)
        ServiceContainer.getService(FileService).sendFileToAliOSS(model.filePath, type: .Video) { (taskId, fileKey) -> Void in
            if fileKey != nil{
                model.fileId = fileKey.fileId
                step.finishedStep(nil)
            }else{
                step.failStep(nil)
            }
        }
    }
}

class PostVessageToServer:BahamutTaskStepWorker{
    func taskStepStart(task: BahamutTask, step: BahamutTaskStep, taskModel: BahamutTaskModel) {
        let model = SendVessageTaskInfo(json: taskModel.taskUserInfo)
        let vessage = Vessage()
        vessage.sender = ServiceContainer.getUserService().myProfile.userId
        vessage.fileId = model.fileId
        //TODO: high version finish
//        ServiceContainer.getVessageService().sendVessage(vessage){ sended in
//            if sended{
//                step.finishedStep(nil)
//            }else{
//                step.failStep(nil)
//            }
//        }
    }
}

class SendVessageTaskInfo:BahamutObject{
    var filePath:String!
    var fileId:String!
    
    var receiverId:String!
    var receiverMobile:String!
}

class VessageQueue:NSObject{
    let sendVessageQueueName = "SendVessage"
    let sendVessageQueueWorkStep = ["SendAliOSSFile","PostVessage"]
    private var taskInfoDict = [String:SendVessageTaskInfo]()
    static var sharedInstance:VessageQueue = {
        return VessageQueue()
    }()
    
    //primary version do not use queue
//    func pushNewVideoTo(conversationId:String,fileUrl:NSURL){
//        //TODO: delete test
//        let testMark = "tn" + ""
//        if testMark == "tn"{
//            return
//        }
//        
//        let userInfoModel = SendVessageTaskInfo()
//        userInfoModel.filePath = fileUrl.path!
//        BahamutTaskQueue.getQueue(sendVessageQueueName).pushTask(userInfoModel.toJsonString(), step: sendVessageQueueWorkStep)
//        
//    }
    
    func initObservers(){
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(VessageQueue.onVessageSended(_:)), name: VessageService.onNewVessageSended, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(VessageQueue.onVessageSendFail(_:)), name: VessageService.onNewVessageSendFail, object: nil)
    }
    
    func removeObservers(){
        ServiceContainer.getVessageService().removeObserver(self)
    }
    
    func onVessageSendFail(a:NSNotification){
        RecordMessageController.instance.playCrossMark("VESSAGE_SEND_FAIL".localizedString())
    }
    
    func onVessageSended(a:NSNotification){
        if let task = a.userInfo?[SendedVessageTaskValue] as? VessageFileUploadTask{
            if let path = ServiceContainer.getService(FileService).getFilePath(task.fileId, type: .Video){
                if !PersistentFileHelper.deleteFile(path){
                    NSLog("Delete Sended Vessage Failed Error:%@", path)
                }
            }
        }
        RecordMessageController.instance.playCheckMark("VESSAGE_SENDED".localizedString())
    }
    
    func pushNewVessageTo(receiverId:String?,receiverMobile:String?,videoUrl:NSURL){
        let userInfoModel = SendVessageTaskInfo()
        userInfoModel.receiverId = receiverId
        userInfoModel.receiverMobile = receiverMobile
        userInfoModel.filePath = videoUrl.path!
        let taskInfoKey = IdUtil.generateUniqueId()
        taskInfoDict[taskInfoKey] = userInfoModel
        sendVessage(taskInfoKey)
    }
    
    private func sendVessageFile(vessageId:String, taskInfoKey:String){
        
        let sendingHud = RecordMessageController.instance.showActivityHud()
        if let taskInfo = taskInfoDict[taskInfoKey]{
            ServiceContainer.getService(FileService).sendFileToAliOSS(taskInfo.filePath, type: .Video) { (taskId, fileKey) -> Void in
                if fileKey != nil{
                    self.taskInfoDict.removeValueForKey(taskInfoKey)
                    
                    let task = VessageFileUploadTask()
                    task.taskId = taskId
                    task.receiverId = taskInfo.receiverId
                    task.receiverMobile = taskInfo.receiverMobile
                    task.fileId = fileKey.fileId
                    task.vessageId = vessageId
                    ServiceContainer.getVessageService().observeOnVessageFileUploadTask(task)
                    sendingHud.hideAsync(false)
                    RecordMessageController.instance.playToast("VESSAGE_PUSH_IN_QUEUE".localizedString(),async: false){
                        self.sendSMSToFriend(taskInfo)
                    }
                    
                }else{
                    sendingHud.hideAsync(false)
                    self.retrySendFile(vessageId,taskInfoKey: taskInfoKey)
                }
            }
        }
    }
    
    
    private func retrySendFile(vessageId:String,taskInfoKey:String){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessageFile(vessageId,taskInfoKey: taskInfoKey)
        }
        let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (action) -> Void in
            ServiceContainer.getVessageService().cancelSendVessage(vessageId)
            RecordMessageController.instance.playCrossMark("CANCEL".localizedString())
        }
        RecordMessageController.instance.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }
    
    private func sendVessage(taskInfoKey:String){
        func sendedCallback(vessageId:String?){
            if let vid = vessageId{
                self.sendVessageFile(vid, taskInfoKey: taskInfoKey)
            }else{
                self.retrySendVessage(taskInfoKey)
            }
        }
        let userService = ServiceContainer.getUserService()
        let sendNick = userService.myProfile.nickName
        let sendMobile = userService.myProfile.mobile
        if let taskInfo = taskInfoDict[taskInfoKey]{
            if let receiverId = taskInfo.receiverId{
                ServiceContainer.getVessageService().sendVessageToUser(receiverId, sendNick: sendNick,sendMobile: sendMobile, callback: sendedCallback)
            }else if let receiverMobile = taskInfo.receiverMobile{
                ServiceContainer.getVessageService().sendVessageToMobile(receiverMobile, sendNick: sendNick,sendMobile: sendMobile, callback: sendedCallback)
            }else{
            }
        }
    }
    
    private func retrySendVessage(taskInfoKey:String){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessage(taskInfoKey)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            RecordMessageController.instance.playCrossMark("CANCEL".localizedString())
        }
        RecordMessageController.instance.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }
    
    //MARK: send sms to people
    private func sendSMSToFriend(taskInfo:SendVessageTaskInfo){
        if String.isNullOrWhiteSpace(taskInfo.receiverId){
            if !UserSetting.isSettingEnable("InviteSMS:\(taskInfo.receiverMobile)"){
                let send = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) -> Void in
                    var url = ""
                    if let senderNick = ServiceContainer.getUserService().myProfile.nickName{
                        url = VessageConfig.bahamutConfig.bahamutAppOuterExecutorUrlPrefix + senderNick.base64String()
                    }else{
                        url = VessageConfig.bahamutConfig.bahamutAppOuterExecutorUrlPrefix + "\(ServiceContainer.getUserService().myProfile.accountId)"
                    }
                    RecordMessageController.instance.showMessageView(taskInfo.receiverMobile, body: String(format: "NOTIFY_SMS_FORMAT".localizedString(),url))
                })
                let cancel = UIAlertAction(title: "NO".localizedString(), style: .Cancel, handler: { (ac) -> Void in
                    
                })
                
                RecordMessageController.instance.showAlert("SEND_NOTIFY_SMS_TO_FRIEND".localizedString(), msg: taskInfo.receiverMobile, actions: [send,cancel])
            }
        }
    }
}

extension RecordMessageController:MFMessageComposeViewControllerDelegate,UINavigationControllerDelegate{
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true) { 
            switch result{
            case MessageComposeResultCancelled:
                self.playCrossMark("CANCEL".localizedString())
                MobClick.event("CancelSendNotifySMS")
            case MessageComposeResultFailed:
                self.playCrossMark("FAIL".localizedString())
            case MessageComposeResultSent:
                self.playCheckMark("SUCCESS".localizedString())
                MobClick.event("UserSendSMSToFriend")
            default:break;
            }
        }
    }
    
    private func showMessageView(phone:String,body:String){
        if MFMessageComposeViewController.canSendText(){
            let controller = MFMessageComposeViewController()
            controller.recipients = [phone]
            controller.body = body
            controller.delegate = self
            controller.messageComposeDelegate = self
            RecordMessageController.instance.presentViewController(controller, animated: true, completion: { () -> Void in
                MobClick.event("OpenSendNotifySMS")
            })
        }else{
            RecordMessageController.instance.showAlert("REQUIRE_SMS_FUNCTION_TITLE".localizedString(), msg: "REQUIRE_SMS_FUNCTION_MSG".localizedString())
        }
    }
}