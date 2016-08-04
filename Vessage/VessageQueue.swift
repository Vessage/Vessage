//
//  VessageQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VessageQueue:NSNotificationCenter{
    static let onTaskStepError = "onTaskStepError"
    static let onTaskProgress = "onTaskProgress"
    static let onTaskFinished = "onTaskFinished"
    static let onTaskCanceled = "onTaskCanceled"
    
    private var extraInfoString:String!
    //private var sendingQueueTasks = [String:SendVessageQueueTask]()
    private var stepHandler = [String:SendVessageQueueStepHandler]()
    
    static var sharedInstance:VessageQueue = {
        return VessageQueue()
    }()
    
    weak var controller:UIViewController!{
        return UIApplication.currentShowingViewController
    }
    
    func initQueue(userId:String){
        initHandlers()
        refreshExtraInfoString()
        initObservers()
    }
    
    private func releaseQueue() {
        releaseHandlers()
        removeObservers()
    }
    
    private func initHandlers(){
        stepHandler.removeAll()
        stepHandler.updateValue(PostVessageHandler(), forKey: PostVessageHandler.stepKey)
        stepHandler.updateValue(SendAliOSSFileHandler(), forKey: SendAliOSSFileHandler.stepKey)
        stepHandler.updateValue(FinishFileVessageHandler(), forKey: FinishFileVessageHandler.stepKey)
        stepHandler.updateValue(FinishNormalVessageHandler(), forKey: FinishNormalVessageHandler.stepKey)
        stepHandler.values.forEach{$0.initHandler(self)}
    }
    
    private func releaseHandlers(){
        stepHandler.values.forEach{$0.releaseHandler()}
        stepHandler.removeAll()
    }
    
    private func initObservers(){
        ServiceContainer.instance.addObserver(self, selector: #selector(VessageQueue.onUserLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
    }
    
    private func removeObservers(){
        ServiceContainer.instance.removeObserver(self)
    }
    
    func onVessageSendFail(a:NSNotification){
        
    }
    
    func onUserLogout(a:NSNotification){
        releaseQueue()
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
    
    private func getSendVessageQueueTaskByTaskId(taskId:String) -> SendVessageQueueTask?{
        return PersistentManager.sharedInstance.getModel(SendVessageQueueTask.self, idValue: taskId)
    }
    
    func pushNewVessageTo(receiverId:String?,vessage:Vessage,taskSteps:[String],uploadFileUrl:NSURL? = nil){
        let queueTask = SendVessageQueueTask()
        let vsg = vessage
        vsg.extraInfo = extraInfoString
        vsg.sender = ServiceContainer.getUserService().myProfile.userId
        queueTask.steps = taskSteps
        queueTask.receiverId = receiverId
        queueTask.filePath = uploadFileUrl?.path!
        queueTask.taskId = IdUtil.generateUniqueId()
        queueTask.vessage = vsg
        queueTask.currentStep = -1
        queueTask.saveModel()
        nextStep(queueTask)
    }
    
    func nextStep(task:SendVessageQueueTask) {
        task.currentStep += 1
        task.saveModel()
        if task.isFinish() {
            finishTask(task)
        }else{
            startTask(task)
        }
    }
    
    private func finishTask(task:SendVessageQueueTask){
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kSendVessageQueueTaskValue)
        PersistentManager.sharedInstance.removeModel(task)
        self.postNotificationNameWithMainAsync(VessageQueue.onTaskFinished, object: self, userInfo: userInfo)
        self.notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: 0)
        #if DEBUG
            print("SendTaskId:\(task.taskId) -> Finished")
        #endif
    }
    
    func notifyTaskStepProgress(task:SendVessageQueueTask,stepIndex:Int,stepProgress:Float) {
        
        let totalSteps = Float(task.steps.count)
        let stepProgressInTask = 1 / totalSteps * stepProgress
        let finishedProgress = Float(stepIndex) / totalSteps + stepProgressInTask
        
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kSendVessageQueueTaskValue)
        userInfo.updateValue(finishedProgress, forKey: kSendVessageQueueTaskProgressValue)
        self.postNotificationNameWithMainAsync(VessageQueue.onTaskProgress, object: self, userInfo: userInfo)
        #if DEBUG
            print("SendTaskId:\(task.taskId) -> Progress:\(finishedProgress * 100)%")
        #endif
    }
    
    func doTaskStepError(task:SendVessageQueueTask,message:String?) {
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kSendVessageQueueTaskValue)
        if let msg = message{
            userInfo.updateValue(msg, forKey: kSendVessageQueueTaskMessageValue)
        }
        self.postNotificationNameWithMainAsync(VessageQueue.onTaskStepError, object: self, userInfo: userInfo)
    }
    
    func cancelTask(task:SendVessageQueueTask,message:String?) {
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kSendVessageQueueTaskValue)
        if let msg = message{
            userInfo.updateValue(msg, forKey: kSendVessageQueueTaskMessageValue)
        }
        PersistentManager.sharedInstance.removeModel(task)
        self.postNotificationNameWithMainAsync(VessageQueue.onTaskCanceled, object: self, userInfo: userInfo)
        #if DEBUG
            print("SendTaskId:\(task.taskId) -> Canceled")
        #endif
    }
    
    func startTask(task:SendVessageQueueTask)  {
        notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: 0)
        if let step = task.getCurrentStep(){
            if let handler = self.stepHandler[step]{
                #if DEBUG
                    print("SendTaskId:\(task.taskId) -> Do Work:\(step)")
                #endif
                handler.doTask(self, task: task)
            }
        }
    }
}