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
    //var receiverMobile:String!
    var isGroup = false
    
}

class VessageQueue:NSObject{
    let sendVessageQueueName = "SendVessage"
    let sendVessageQueueWorkStep = ["SendAliOSSFile","PostVessage"]
    private var taskInfoDict = [String:SendVessageTaskInfo]()
    static var sharedInstance:VessageQueue = {
        return VessageQueue()
    }()
    
    var controller:UIViewController!{
        return UIApplication.currentShowingViewController
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
    
    func initObservers(){
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(VessageQueue.onVessageSended(_:)), name: VessageService.onNewVessageSended, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(VessageQueue.onVessageSendFail(_:)), name: VessageService.onNewVessageSendFail, object: nil)
        
    }
    
    func removeObservers(){
        ServiceContainer.getVessageService().removeObserver(self)
    }
    
    func onVessageSendFail(a:NSNotification){
        
    }
    
    func onVessageSended(a:NSNotification){
        if let task = a.userInfo?[SendedVessageTaskValue] as? VessageFileUploadTask{
            if let path = ServiceContainer.getService(FileService).getFilePath(task.fileId, type: .Video){
                if !PersistentFileHelper.deleteFile(path){
                    NSLog("Delete Sended Vessage Failed Error:%@", path)
                }
            }
        }
    }
    
    func pushNewVessageTo(receiverId:String?,isGroup:Bool,videoUrl:NSURL){
        let userInfoModel = SendVessageTaskInfo()
        userInfoModel.receiverId = receiverId
        userInfoModel.filePath = videoUrl.path!
        userInfoModel.isGroup = isGroup
        let taskInfoKey = IdUtil.generateUniqueId()
        taskInfoDict[taskInfoKey] = userInfoModel
        sendVessage(taskInfoKey)
    }
    
    private func sendVessageFile(vessageId:String, taskInfoKey:String){
        if let taskInfo = taskInfoDict[taskInfoKey]{
            ServiceContainer.getService(FileService).sendFileToAliOSS(taskInfo.filePath, type: .Video) { (taskId, fileKey) -> Void in
                if fileKey != nil{
                    self.taskInfoDict.removeValueForKey(taskInfoKey)
                    let task = VessageFileUploadTask()
                    task.taskId = taskId
                    task.receiverId = taskInfo.receiverId
                    task.fileId = fileKey.fileId
                    task.vessageId = vessageId
                    ServiceContainer.getVessageService().observeOnVessageFileUploadTask(task)
                }else{
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
            self.controller.playCrossMark("CANCEL".localizedString())
        }
        controller.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
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
                ServiceContainer.getVessageService().sendVessageToUser(receiverId, isGroup: taskInfo.isGroup,sendNick: sendNick,sendMobile: sendMobile, callback: sendedCallback)
            }
        }
    }
    
    private func retrySendVessage(taskInfoKey:String){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessage(taskInfoKey)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) { (action) -> Void in
            self.controller.playCrossMark("CANCEL".localizedString())
        }
        controller.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }
}