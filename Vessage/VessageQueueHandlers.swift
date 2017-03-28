
//
//  VessageQueueHandlers.swift
//  Vessage
//
//  Created by AlexChow on 16/7/30.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class SendVessageTaskSteps {
    static let normalVessageSteps = [PostVessageHandler.stepKey,FinishNormalVessageHandler.stepKey]
    
    static let fileVessageSteps = [
        SendAliOSSFileHandler.stepKey,
        PostVessageHandler.stepKey,
        FinishNormalVessageHandler.stepKey
    ]
}


class PostVessageHandler :SendVessageQueueStepHandler {
    static let stepKey = "PostVessage"
    override func doTask(_ vessageQueue:VessageQueue,task: SendVessageQueueTask) {
        let vsg = task.vessage!
        ServiceContainer.getVessageService().sendVessageToUser(task.receiverId, vessage: vsg){ vessageId in
            if let vsgId = vessageId{
                task.vessage = vsg.copyToObject(Vessage.self)
                task.vessage.vessageId = vsgId
                vessageQueue.nextStep(task)
            }else{
                vessageQueue.doTaskStepError(task, message: "POST_VESSAGE_ERROR")
            }
        }
    }
}

class SendAliOSSFileHandler: SendVessageQueueStepHandler,ProgressTaskDelegate {
    static let stepKey = "SendAliOSSFile"
    fileprivate var uploadDict = [String:SendVessageQueueTask]()
    
    override func releaseHandler() {
        uploadDict.removeAll()
    }
    
    override func doTask(_ vessageQueue: VessageQueue, task: SendVessageQueueTask) {
        ServiceContainer.getFileService().sendFileToAliOSS(task.filePath, type: .noType) { (uploadTaskId, fileKey) -> Void in
            if let fk = fileKey{
                task.vessage.fileId = fk.fileId
                self.uploadDict[uploadTaskId] = task
                ProgressTaskWatcher.sharedInstance.addTaskObserver(uploadTaskId, delegate: self)
            }else{
                vessageQueue.doTaskStepError(task,message: "GET_FILE_KEY_ERROR")
            }
        }
    }
    
    @objc func taskProgress(_ taskIdentifier: String, persent: Float) {
        if let task = uploadDict[taskIdentifier]{
            VessageQueue.sharedInstance.notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: persent / 100)
        }
    }
    
    @objc func taskCompleted(_ taskIdentifier: String, result: Any!) {
        if let task = uploadDict.removeValue(forKey: taskIdentifier){
            DispatchQueue.main.async {
                VessageQueue.sharedInstance.nextStep(task)
            }
        }
    }
    
    @objc func taskFailed(_ taskIdentifier: String, result: Any!) {
        if let task = uploadDict[taskIdentifier]{
            VessageQueue.sharedInstance.doTaskStepError(task, message: "UPLOAD_FILE_ERROR")
        }
    }
}

class FinishNormalVessageHandler: SendVessageQueueStepHandler {
    static let stepKey = "FinishNormalVessage"
    
    override func doTask(_ vessageQueue: VessageQueue, task: SendVessageQueueTask) {
        ServiceContainer.getVessageService().finishSendVessage(task.vessage.vessageId) { (finished, sendVessageResultModel) in
            if finished{
                vessageQueue.nextStep(task)
            }else{
                vessageQueue.doTaskStepError(task, message: "POST_FINISH_SEND_VESSAGE_ERROR")
            }
        }
    }
 
}
/*
class FinishFileVessageHandler: SendVessageQueueStepHandler {
    static let stepKey = "FinishFileVessage"
    
    override func doTask(vessageQueue: VessageQueue, task: SendVessageQueueTask) {
        ServiceContainer.getVessageService().finishSendVessage(task.vessage.vessageId, fileId: task.vessage.fileId){ finished,resultModel in
            if finished{
                vessageQueue.nextStep(task)
            }else{
                vessageQueue.doTaskStepError(task, message: "POST_FINISH_SEND_VESSAGE_ERROR")
            }
        }
    }
}
*/
