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
        vessage.sender = ServiceContainer.getService(UserService).myProfile.userId
        vessage.fileId = model.fileId
        //TODO: high version finish
//        ServiceContainer.getService(VessageService).sendVessage(vessage){ sended in
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

class VessageQueue:NSObject,MFMessageComposeViewControllerDelegate,UINavigationControllerDelegate{
    let sendVessageQueueName = "SendVessage"
    let sendVessageQueueWorkStep = ["SendAliOSSFile","PostVessage"]
    private var taskInfoDict = [String:SendVessageTaskInfo]()
    static var sharedInstance:VessageQueue{
        return VessageQueue()
    }
    
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
                    ServiceContainer.getService(VessageService).observeOnFileUploadedForVessage(taskId,vessageId: vessageId, fileKey: fileKey)
                    sendingHud.hideAsync(false)
                    RecordMessageController.instance.playCheckMark("VESSAGE_PUSH_IN_QUEUE".localizedString(),async: false)
                    self.taskInfoDict.removeValueForKey(taskInfoKey)
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
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            ServiceContainer.getService(VessageService).cancelSendVessage(vessageId)
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
        let userService = ServiceContainer.getService(UserService)
        let sendNick = userService.myProfile.nickName
        let sendMobile = userService.myProfile.mobile
        if let taskInfo = taskInfoDict[taskInfoKey]{
            if let receiverId = taskInfo.receiverId{
                ServiceContainer.getService(VessageService).sendVessageToUser(receiverId, sendNick: sendNick,sendMobile: sendMobile, callback: sendedCallback)
            }else if let receiverMobile = taskInfo.receiverMobile{
                ServiceContainer.getService(VessageService).sendVessageToMobile(receiverMobile, sendNick: sendNick,sendMobile: sendMobile, callback: sendedCallback)
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
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch result{
        case MessageComposeResultCancelled:
            RecordMessageController.instance.playCrossMark("CANCEL".localizedString())
        case MessageComposeResultFailed:
            RecordMessageController.instance.playCrossMark("FAIL".localizedString())
        case MessageComposeResultSent:
            RecordMessageController.instance.playCheckMark("SUCCESS".localizedString())
        default:break;
        }
    }
    
    private func showMessageView(phone:String,body:String){
        if MFMessageComposeViewController.canSendText(){
            let controller = MFMessageComposeViewController()
            controller.recipients = [phone]
            controller.body = body
            controller.delegate = self
            RecordMessageController.instance.presentViewController(controller, animated: true, completion: { () -> Void in
                
            })
        }else{
            RecordMessageController.instance.showAlert("REQUIRE_SMS_FUNCTION_TITLE".localizedString(), msg: "REQUIRE_SMS_FUNCTION_MSG".localizedString())
        }
    }
}