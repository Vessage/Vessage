//
//  SetChatImagesTask.swift
//  Vessage
//
//  Created by AlexChow on 16/8/21.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class SetChatImagesTask: BahamutQueueTask {
    var filePath:String!
    var fileId:String!
    var imageType:String!
    
}

extension BahamutTaskQueue{
    func useSetChatImageHandlers() {
        self.useHandler(SendChatImageHandler.key, handler: SendChatImageHandler())
        self.useHandler(SetChatImageHandler.key, handler: SetChatImageHandler())
    }
}

class SendChatImageHandler: BahamutTaskQueueStepHandler,ProgressTaskDelegate {
    static let key = "SendChatImage"
    private var queue:BahamutTaskQueue!
    private var uploadDict = [String:SetChatImagesTask]()
    
    func initHandler(queue: BahamutTaskQueue) {
        self.queue = queue
    }
    
    func doTask(queue: BahamutTaskQueue, task t: BahamutQueueTask) {
        let task = t as! SetChatImagesTask
        ServiceContainer.getService(FileService).sendFileToAliOSS(task.filePath, type: .Image) { (uploadTaskId, fileKey) -> Void in
            if fileKey != nil{
                task.fileId = fileKey.fileId
                task.saveModel()
                self.uploadDict.updateValue(task, forKey: uploadTaskId)
                ProgressTaskWatcher.sharedInstance.addTaskObserver(uploadTaskId, delegate: self)
            }else{
                queue.doTaskStepError(task,message: "GET_FILE_KEY_ERROR")
            }
        }
    }
    
    func releaseHandler() {
        uploadDict.removeAll()
        queue = nil
    }
    
    @objc func taskProgress(taskIdentifier: String, persent: Float) {
        if let task = uploadDict[taskIdentifier]{
            queue.notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: persent / 100)
        }
    }
    
    @objc func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = uploadDict.removeValueForKey(taskIdentifier){
            queue.nextStep(task)
        }
    }
    
    @objc func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = uploadDict[taskIdentifier]{
            queue.doTaskStepError(task, message: "UPLOAD_FILE_ERROR")
        }
    }
}

class SetChatImageHandler: BahamutTaskQueueStepHandler {
    static let key = "SetChatImage"
    func initHandler(queue: BahamutTaskQueue) {
        
    }
    
    func doTask(queue: BahamutTaskQueue, task: BahamutQueueTask) {
        let t = task as! SetChatImagesTask
        ServiceContainer.getUserService().setChatBackground(t.fileId, imageType: t.imageType) { (suc) in
            if suc{
                queue.nextStep(task)
            }else{
                queue.doTaskStepError(task, message: "SET_CHAT_IMAGE_ERROR")
            }
        }
    }
    
    func releaseHandler() {
        
    }
}