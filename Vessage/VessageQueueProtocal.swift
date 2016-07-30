//
//  VessageQueueProtocal.swift
//  Vessage
//
//  Created by AlexChow on 16/7/30.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

protocol SendVessageQueueStepHandler {
    func initHandler(queue:VessageQueue)
    func releaseHandler()
    func doTask(vessageQueue:VessageQueue,task:SendVessageQueueTask)
}

class SendVessageQueueTask:BahamutObject{
    override func getObjectUniqueIdName() -> String {
        return "taskId"
    }
    
    var taskId:String!
    var filePath:String!
    var receiverId:String!
    var vessage:Vessage!
    
    var steps:[String]!
    var currentStep = 0
    
    func getCurrentStep() -> String? {
        return steps?[currentStep]
    }
    
    func isFinish() -> Bool {
        return currentStep == steps.count
    }
}

let kSendVessageQueueTaskValue = "TaskValue"
let kSendVessageQueueTaskMessageValue = "TaskMessageValue"
let kSendVessageQueueTaskProgressValue = "TaskMessageValue"
