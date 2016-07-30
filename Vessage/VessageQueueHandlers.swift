
//
//  VessageQueueHandlers.swift
//  Vessage
//
//  Created by AlexChow on 16/7/30.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class SendVessageTaskSteps {
    static let normalVessageSteps = [PostVessageHandler.stepKey]
    
    static let fileVessageSteps = [
        PostVessageHandler.stepKey,
        SendAliOSSFileHandler.stepKey,
        FinishPostVessageHandler.stepKey
    ]
}


class PostVessageHandler :SendVessageQueueStepHandler {
    static let stepKey = "PostVessage"
    func initHandler(queue:VessageQueue) {
        
    }
    
    func releaseHandler() {
        
    }
    
    func doTask(vessageQueue:VessageQueue,task: SendVessageQueueTask) {
        ServiceContainer.getVessageService().sendVessageToUser(task.receiverId, vessage: task.vessage){ vessageId in
            if let vsgId = vessageId{
                task.vessage.vessageId = vsgId
                task.saveModel()
                vessageQueue.nextStep(task)
            }else{
                vessageQueue.doTaskStepError(task, message: "POST_VESSAGE_ERROR")
            }
        }
    }
}

class SendAliOSSFileHandler: SendVessageQueueStepHandler,ProgressTaskDelegate {
    static let stepKey = "SendAliOSSFile"
    private var uploadDict = [String:SendVessageQueueTask]()
    
    func initHandler(queue:VessageQueue) {
        
    }
    
    func releaseHandler() {
        uploadDict.removeAll()
    }
    
    func doTask(vessageQueue: VessageQueue, task: SendVessageQueueTask) {
        ServiceContainer.getService(FileService).sendFileToAliOSS(task.filePath, type: .Video) { (uploadTaskId, fileKey) -> Void in
            if fileKey != nil{
                task.vessage.fileId = fileKey.fileId
                task.saveModel()
                self.uploadDict[uploadTaskId] = task
                ProgressTaskWatcher.sharedInstance.addTaskObserver(uploadTaskId, delegate: self)
            }else{
                vessageQueue.doTaskStepError(task,message: "GET_FILE_KEY_ERROR")
            }
        }
    }
    
    @objc func taskProgress(taskIdentifier: String, persent: Float) {
        if let task = uploadDict[taskIdentifier]{
            VessageQueue.sharedInstance.notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: persent / 100)
        }
    }
    
    @objc func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = uploadDict[taskIdentifier]{
            if let path = ServiceContainer.getFileService().getFilePath(task.vessage.fileId, type: .Video){
                if !PersistentFileHelper.deleteFile(path){
                    NSLog("Delete Sended Vessage Failed Error:%@", path)
                }
            }
            VessageQueue.sharedInstance.nextStep(task)
        }
    }
    
    @objc func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = uploadDict[taskIdentifier]{
            VessageQueue.sharedInstance.doTaskStepError(task, message: "UPLOAD_FILE_ERROR")
        }
    }
}

class FinishPostVessageHandler: SendVessageQueueStepHandler {
    static let stepKey = "FinishPostVessage"
    func initHandler(queue:VessageQueue) {
        
    }
    
    func releaseHandler() {
        
    }
    
    func doTask(vessageQueue: VessageQueue, task: SendVessageQueueTask) {
        ServiceContainer.getVessageService().finishSendVessage(task.vessage.vessageId, postUploadedFileId: task.vessage.fileId){ finished,resultModel in
            if finished{
                vessageQueue.nextStep(task)
            }else{
                vessageQueue.doTaskStepError(task, message: "POST_FINISH_SEND_VESSAGE_ERROR")
            }
        }
    }
}
