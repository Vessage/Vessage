//
//  VessageQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

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
        vessage.conversationId = model.conversationId
        vessage.fileId = model.fileId
        ServiceContainer.getService(VessageService).sendVessage(vessage){ sended in
            if sended{
                step.finishedStep(nil)
            }else{
                step.failStep(nil)
            }
        }
    }
}

class SendVessageTaskInfo:BahamutObject{
    var filePath:String!
    var fileId:String!
    var conversationId:String!
}

class VessageQueue{
    let sendVessageQueueName = "SendVessage"
    let sendVessageQueueWorkStep = ["SendAliOSSFile","PostVessage"]
    static var sharedInstance:VessageQueue{
        return VessageQueue()
    }
    
    func pushNewVideoTo(conversationId:String,fileUrl:NSURL){
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            return
        }
        
        let userInfoModel = SendVessageTaskInfo()
        userInfoModel.conversationId = conversationId
        userInfoModel.filePath = fileUrl.path!
        BahamutTaskQueue.getQueue(sendVessageQueueName).pushTask(userInfoModel.toJsonString(), step: sendVessageQueueWorkStep)
        
    }
}