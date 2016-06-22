//
//  VessageService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VessageFileUploadTask: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "taskId"
    }
    var taskId:String!
    var fileId:String!
    var vessageId:String!
    var receiverId:String!
    var receiverMobile:String!
}

let VessageServiceNotificationValue = "VessageServiceNotificationValue"
let VessageServiceNotificationValues = "VessageServiceNotificationValue"
let SendedVessageResultModelValue = "SendedVessageResultModelValue"
let SendedVessageTaskValue = "SendedVessageTaskValue"
let SendingVessagePersentValue = "SendingVessagePersentValue"


//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getVessageService() -> VessageService{
        return ServiceContainer.getService(VessageService)
    }
}

//MARK: VessageService
class VessageService:NSNotificationCenter, ServiceProtocol,ProgressTaskDelegate {
    static let onNewVessageReceived = "onNewVessageReceived"
    static let onNewVessagesReceived = "onNewVessagesReceived"
    static let onNewVessageSended = "onNewVessageSended"
    static let onNewVessageSendFail = "onNewVessageSendFail"
    static let onNewVessageSending = "onNewVessageSending"
    static let onVessageRead = "onVessageRead"
    //private static let notReadVessageCountStoreKey = "NewVsgCntKey"
    @objc static var ServiceName:String {return "Vessage Service"}
    
    private var notReadVessageCountMap:[String:Int]!
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        initNotReadVessageCountMap()
        setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        setServiceNotReady()
    }
    
    private func initNotReadVessageCountMap(){
        notReadVessageCountMap = [String:Int]()
        var newestVsgMap = [String:Vessage]()
        let vsgs = PersistentManager.sharedInstance.getAllModel(Vessage)
        vsgs.forEach { (vsg) in
            if !vsg.isRead{
                if let cnt = notReadVessageCountMap[vsg.sender]{
                    notReadVessageCountMap[vsg.sender] = cnt + 1
                }else{
                    notReadVessageCountMap[vsg.sender] = 1
                }
            }else{
                if let nvsg = newestVsgMap[vsg.sender]{
                    if nvsg.getSendTime().compare(vsg.getSendTime()) == .OrderedDescending{
                        PersistentManager.sharedInstance.removeModel(vsg)
                    }else{
                        newestVsgMap[vsg.sender] = vsg
                        PersistentManager.sharedInstance.removeModel(nvsg)
                    }
                }else{
                    newestVsgMap[vsg.sender] = vsg
                }
            }
        }
        PersistentManager.sharedInstance.saveAll()
        PersistentManager.sharedInstance.refreshCache(Vessage)
    }
    
    func sendVessageToMobile(receiverMobile:String,sendNick:String?,sendMobile:String?,callback:(vessageId:String?)->Void){
        let req = SendNewVessageToMobileRequest()
        req.receiverMobile = receiverMobile
        sendVessage(req, sendNick: sendNick,sendMobile: sendMobile) { (vessageId) -> Void in
            callback(vessageId: vessageId)
        }
    }
    
    func sendVessageToUser(receiverId:String?, sendNick:String?,sendMobile:String?, callback:(vessageId:String?)->Void){
        let req = SendNewVessageToUserRequest()
        req.receiverId = receiverId
        sendVessage(req, sendNick: sendNick,sendMobile: sendMobile) { (vessageId) -> Void in
            callback(vessageId: vessageId)
        }
    }
    
    private func sendVessage(req:SendNewVessageRequestBase,sendNick:String?,sendMobile:String?,callback:(vessageId:String?)->Void){
        let extraInfo = VessageExtraInfoModel()
        extraInfo.nickName = sendNick
        extraInfo.accountId = UserSetting.lastLoginAccountId
        if String.isNullOrWhiteSpace(sendMobile) == false{
            extraInfo.mobileHash = sendMobile!.md5
        }
        req.extraInfo = extraInfo.toJsonString()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<SendVessageResultModel>) -> Void in
            if let vrm = result.returnObject{
                vrm.saveModel()
                callback(vessageId: vrm.vessageId)
            }else{
                callback(vessageId: nil)
            }
        }
    }
    
    private func getSendVessageResult(vessageId:String) -> SendVessageResultModel?{
        return PersistentManager.sharedInstance.getModel(SendVessageResultModel.self, idValue: vessageId)
    }
    
    private var fileUploadTaskDict = [String:VessageFileUploadTask]()
    
    func observeOnVessageFileUploadTask(task:VessageFileUploadTask){
        task.saveModel()
        fileUploadTaskDict[task.taskId] = task
        ProgressTaskWatcher.sharedInstance.addTaskObserver(task.taskId, delegate: self)
    }
    
    //MARK: ProgressTask Delegate
    func taskProgress(taskIdentifier: String, persent: Float) {
        if let t = fileUploadTaskDict[taskIdentifier]{
            self.postNotificationNameWithMainAsync(VessageService.onNewVessageSending, object: self, userInfo: [SendingVessagePersentValue:persent,SendedVessageTaskValue:t])
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = fileUploadTaskDict[taskIdentifier] {
            self.finishSendVessage(task)
        }else if let task = PersistentManager.sharedInstance.getModel(VessageFileUploadTask.self, idValue: taskIdentifier){
            self.finishSendVessage(task)
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(VessageFileUploadTask.self, idValue: taskIdentifier){
            self.cancelSendVessage(task.vessageId)
            self.fileUploadTaskDict.removeValueForKey(taskIdentifier)
            PersistentManager.sharedInstance.removeModel(task)
            var userInfo = [String:AnyObject]()
            userInfo.updateValue(task, forKey: SendedVessageTaskValue)
            self.postNotificationNameWithMainAsync(VessageService.onNewVessageSendFail, object: self, userInfo:userInfo)
        }
    }
    
    private func finishSendVessage(task:VessageFileUploadTask){
        if let m = getSendVessageResult(task.vessageId){
            let req = FinishSendVessageRequest()
            req.vessageId = m.vessageId
            req.vessageBoxId = m.vessageBoxId
            req.fileId = task.fileId
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req, callback: { (result) -> Void in
                var userInfo = [String:AnyObject]()
                userInfo.updateValue(task, forKey: SendedVessageTaskValue)
                userInfo.updateValue(m, forKey: SendedVessageResultModelValue)
                if result.isSuccess{
                    MobClick.event("Vege_TotalPostVessages")
                    self.fileUploadTaskDict.removeValueForKey(task.taskId)
                    PersistentManager.sharedInstance.removeModel(task)
                    PersistentManager.sharedInstance.removeModel(m)
                    self.postNotificationNameWithMainAsync(VessageService.onNewVessageSended, object: self, userInfo:userInfo)
                }else{
                    self.postNotificationNameWithMainAsync(VessageService.onNewVessageSendFail, object: self, userInfo:userInfo)
                }
            })
        }
    }
    
    func cancelSendVessage(vessageId:String){
        if let m = getSendVessageResult(vessageId){
            let req = CancelSendVessageRequest()
            req.vessageId = m.vessageId
            req.vessageBoxId = m.vessageBoxId
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req, callback: { (result) -> Void in
                
            })
        }
    }
    
    func readVessage(vessage:Vessage,refresh:Bool = true){
        if vessage.isRead == false{
            vessage.isRead = true
            if var cnt = notReadVessageCountMap[vessage.sender]{
                cnt = cnt > 1 ? cnt - 1 : 0
                notReadVessageCountMap[vessage.sender] = cnt
            }else{
                notReadVessageCountMap[vessage.sender] = 0
            }
            self.postNotificationNameWithMainAsync(VessageService.onVessageRead, object: self, userInfo: [VessageServiceNotificationValue:vessage])
        }
        if refresh{
            vessage.saveModel()
            PersistentManager.sharedInstance.refreshCache(Vessage)
        }
    }
    
    func removeVessage(vessage:Vessage){
        readVessage(vessage,refresh: false)
        PersistentManager.sharedInstance.removeModel(vessage)
        PersistentManager.sharedInstance.refreshCache(Vessage)
        let req = SetVessageRead()
        req.vessageId = vessage.vessageId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
        }
    }
    
    func newVessageFromServer(){
        let req = GetNewVessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[Vessage]>) -> Void in
            if let vsgs = result.returnObject{
                if vsgs.count > 0{
                    vsgs.saveBahamutObjectModels()
                    PersistentManager.sharedInstance.saveAll()
                    PersistentManager.sharedInstance.refreshCache(Vessage)
                    vsgs.forEach({ (vsg) in
                        if let cnt = self.notReadVessageCountMap[vsg.sender]{
                            self.notReadVessageCountMap[vsg.sender] = cnt + 1
                        }else{
                            self.notReadVessageCountMap[vsg.sender] = 1
                        }
                    })
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        SystemSoundHelper.vibrate()
                        vsgs.forEach({ (vsg) -> () in
                            self.postNotificationNameWithMainAsync(VessageService.onNewVessageReceived, object: self, userInfo: [VessageServiceNotificationValue:vsg])
                        })
                        
                        self.postNotificationNameWithMainAsync(VessageService.onNewVessagesReceived, object: self, userInfo: [VessageServiceNotificationValue:vsgs])
                    })
                    
                    self.notifyVessageGot()
                }
            }
        }
    }
    
    private func notifyVessageGot(){
        let req = NotifyGotNewVessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
        }
    }
    
    func getCachedNewestVessage(chatterId:String) -> Vessage?{
        var vsgs = PersistentManager.sharedInstance.getAllModelFromCache(Vessage).filter{ !String.isNullOrWhiteSpace($0.sender) && $0.sender == chatterId }
        vsgs.sortInPlace { (a, b) -> Bool in
            a.sendTime.dateTimeOfAccurateString.isAfter(b.sendTime.dateTimeOfAccurateString)
        }
        return vsgs.first
    }
    
    func getChatterNotReadVessageCount(chatterId:String) -> Int{
        if let cnt = notReadVessageCountMap[chatterId] {
            return cnt
        }
        return notReadVessageCountMap[chatterId] ?? 0
    }
    
    func getNotReadVessages(chatterId:String) -> [Vessage]{
        return PersistentManager.sharedInstance.getAllModelFromCache(Vessage).filter{$0.isRead == false && (!String.isNullOrWhiteSpace($0.sender) && $0.sender == chatterId) }
    }
}