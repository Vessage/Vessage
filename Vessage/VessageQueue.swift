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
    var typeId = 0
    
    
}

class VessageQueue:NSObject{
    let sendVessageQueueName = "SendVessage"
    let sendVessageQueueWorkStep = ["SendAliOSSFile","PostVessage"]
    private var taskInfoDict = [String:SendVessageTaskInfo]()
    static var sharedInstance:VessageQueue = {
        return VessageQueue()
    }()
    
    weak var controller:UIViewController!{
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
    
    func initQueue(userId:String){
        refreshExtraInfoString()
        initObservers()
    }
    
    private func releaseQueue() {
        removeObservers()
    }
    
    private func initObservers(){
        ServiceContainer.instance.addObserver(self, selector: #selector(VessageQueue.onUserLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(VessageQueue.onVessageSended(_:)), name: VessageService.onNewVessageSended, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(VessageQueue.onVessageSendFail(_:)), name: VessageService.onNewVessageSendFail, object: nil)
        
    }
    
    private func removeObservers(){
        ServiceContainer.instance.removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
    }
    
    func onVessageSendFail(a:NSNotification){
        
    }
    
    func onUserLogout(a:NSNotification){
        releaseQueue()
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
    
    func pushNewVessageTo(receiverId:String?,isGroup:Bool,typeId:Int,fileUrl:NSURL? = nil,fileId:String? = nil){
        let userInfoModel = SendVessageTaskInfo()
        userInfoModel.receiverId = receiverId
        userInfoModel.filePath = fileUrl?.path!
        userInfoModel.fileId = fileId
        userInfoModel.isGroup = isGroup
        userInfoModel.typeId = typeId
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
    
    private var extraInfoString:String!
    
    private func refreshExtraInfoString(){
        let userService = ServiceContainer.getUserService()
        let sendNick = userService.myProfile.nickName
        let sendMobile = userService.myProfile.mobile
        let extraInfo = VessageExtraInfoModel()
        extraInfo.nickName = sendNick
        extraInfo.accountId = UserSetting.lastLoginAccountId
        if String.isNullOrWhiteSpace(sendMobile) == false{
            extraInfo.mobileHash = sendMobile!.md5
        }
        extraInfoString = extraInfo.toJsonString()
    }
    
    private func sendVessage(taskInfoKey:String){
        let taskInfo:SendVessageTaskInfo! = taskInfoDict[taskInfoKey]
        if taskInfo == nil {
            return
        }
        
        func sendedCallback(vessageId:String?){
            if let vid = vessageId{
                if let fileId = taskInfo?.fileId{
                    ServiceContainer.getVessageService().finishSendVessage(taskInfo!.receiverId,vessageId: vid, fileId: fileId)
                }else{
                    self.sendVessageFile(vid, taskInfoKey: taskInfoKey)
                }
            }else{
                self.retrySendVessage(taskInfoKey)
            }
        }
        
        if let receiverId = taskInfo.receiverId{
            let vsg = Vessage()
            vsg.extraInfo = extraInfoString
            vsg.isGroup = taskInfo.isGroup
            vsg.typeId = taskInfo.typeId
            vsg.fileId = taskInfo.fileId
            ServiceContainer.getVessageService().sendVessageToUser(receiverId, vessage: vsg, callback: sendedCallback)
        }
    }
    
    private func retrySendVessage(taskInfoKey:String){
        let okAction = UIAlertAction(title: "OK".localizedString(), style: .Default) { (action) -> Void in
            self.sendVessage(taskInfoKey)
        }
        let cancelAction = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel) { (action) -> Void in
            self.controller.playCrossMark("CANCEL".localizedString())
        }
        controller.showAlert("RETRY_SEND_VESSAGE_TITLE".localizedString(), msg: nil, actions: [okAction,cancelAction])
    }
}