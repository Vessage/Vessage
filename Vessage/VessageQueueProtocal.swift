//
//  VessageQueueProtocal.swift
//  Vessage
//
//  Created by AlexChow on 16/7/30.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class SendVessageQueueStepHandler : BahamutTaskQueueStepHandler{
    
    func initHandler(_ queue: BahamutTaskQueue) {
        initHandler(queue as! VessageQueue)
    }
    
    func doTask(_ queue: BahamutTaskQueue, task: BahamutQueueTask) {
        doTask(queue as! VessageQueue, task: task as! SendVessageQueueTask)
    }
 
    func releaseHandler() {
        
    }
    func initHandler(_ queue:VessageQueue){}
    func doTask(_ vessageQueue:VessageQueue,task:SendVessageQueueTask){}
 
}

class SendVessageQueueTask:BahamutQueueTask{
    var filePath:String!
    var receiverId:String!
    var vessage:Vessage!
}
