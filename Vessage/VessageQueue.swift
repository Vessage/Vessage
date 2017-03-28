//
//  VessageQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VessageQueue: BahamutTaskQueue {
    static let onPushNewVessageTask = "onPushNewVessageTask".asNotificationName()
    
    static var sharedInstance:VessageQueue = {
        return VessageQueue()
    }()
    
    fileprivate var extraInfoString:String!
    override func initQueue(_ userId: String) {
        super.initQueue(userId)
        refreshExtraInfoString()
        var stepHandlers = [String:BahamutTaskQueueStepHandler]()
        stepHandlers.updateValue(PostVessageHandler(), forKey: PostVessageHandler.stepKey)
        stepHandlers.updateValue(SendAliOSSFileHandler(), forKey: SendAliOSSFileHandler.stepKey)
        //stepHandlers.updateValue(FinishFileVessageHandler(), forKey: FinishFileVessageHandler.stepKey)
        stepHandlers.updateValue(FinishNormalVessageHandler(), forKey: FinishNormalVessageHandler.stepKey)
        useHandlers(stepHandlers)
    }
    
    override func releaseQueue() {
        super.releaseQueue()
    }
    
    fileprivate func refreshExtraInfoString(){
        let userService = ServiceContainer.getUserService()
        let sendNick = userService.myProfile.nickName
        let extraInfo = VessageExtraInfoModel()
        extraInfo.nickName = sendNick
        extraInfo.accountId = UserSetting.lastLoginAccountId
        extraInfoString = extraInfo.toMiniJsonString()
    }
    
    func pushNewVessageTo(_ receiverId:String?,isGroup:Bool,vessage:Vessage,taskSteps:[String],uploadFileUrl:URL? = nil){
        let queueTask = SendVessageQueueTask()
        let vsg = Vessage()
        vsg.body = vessage.body
        vsg.extraInfo = vessage.extraInfo
        vsg.typeId = vessage.typeId
        vsg.vessageId = Vessage.sendingVessageId
        vsg.isGroup = isGroup
        vsg.extraInfo = extraInfoString
        vsg.isRead = true
        vsg.fileId = vessage.fileId
        vsg.sender = vessage.isGroup ? receiverId : UserSetting.userId
        if vessage.isGroup{
            vsg.gSender = UserSetting.userId
        }
        vsg.ts = Date().totalSecondsSince1970.int64Value * 1000
        
        queueTask.steps = taskSteps
        queueTask.receiverId = receiverId
        queueTask.filePath = uploadFileUrl?.path
        queueTask.vessage = vsg
        pushTask(queueTask)
        MobClick.event("Vege_ConfirmSendVessage")
        self.post(name: VessageQueue.onPushNewVessageTask, object: self, userInfo: [kBahamutQueueTaskValue:queueTask])
    }
}
