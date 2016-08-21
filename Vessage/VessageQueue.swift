//
//  VessageQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VessageQueue: BahamutTaskQueue {
    static var sharedInstance:VessageQueue = {
        return VessageQueue()
    }()
    
    private var extraInfoString:String!
    override func initQueue(userId: String) {
        super.initQueue(userId)
        initObservers()
        refreshExtraInfoString()
        var stepHandlers = [String:BahamutTaskQueueStepHandler]()
        stepHandlers.updateValue(PostVessageHandler(), forKey: PostVessageHandler.stepKey)
        stepHandlers.updateValue(SendAliOSSFileHandler(), forKey: SendAliOSSFileHandler.stepKey)
        stepHandlers.updateValue(FinishFileVessageHandler(), forKey: FinishFileVessageHandler.stepKey)
        stepHandlers.updateValue(FinishNormalVessageHandler(), forKey: FinishNormalVessageHandler.stepKey)
        initHandlers(stepHandlers)
    }
    
    override func releaseQueue() {
        super.releaseQueue()
        removeObservers()
    }
    
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
        extraInfoString = extraInfo.toMiniJsonString()
    }
    
    private func initObservers(){
        ServiceContainer.instance.addObserver(self, selector: #selector(VessageQueue.onUserLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
    }
    
    private func removeObservers(){
        ServiceContainer.instance.removeObserver(self)
    }
    
    func onUserLogout(a:NSNotification){
        releaseQueue()
    }
    
    func pushNewVessageTo(receiverId:String?,vessage:Vessage,taskSteps:[String],uploadFileUrl:NSURL? = nil){
        let queueTask = SendVessageQueueTask()
        let vsg = vessage
        vsg.extraInfo = extraInfoString
        vsg.sender = ServiceContainer.getUserService().myProfile.userId
        queueTask.steps = taskSteps
        queueTask.receiverId = receiverId
        queueTask.filePath = uploadFileUrl?.path!
        queueTask.vessage = vsg
        pushTask(queueTask)
    }
}