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
}

let VessageServiceNotificationValue = "VessageServiceNotificationValue"
let SendedVessageResultModelValue = "SendedVessageResultModelValue"
let SendedVessageTaskValue = "SendedVessageTaskValue"

//MARK: VessageService
class VessageService:NSNotificationCenter, ServiceProtocol,ProgressTaskDelegate {
    static let onNewVessageReceived = "onNewVessageReceived"
    static let onNewVessageSended = "onNewVessageSended"
    
    static let onVessageRead = "onVessageRead"
    @objc static var ServiceName:String {return "Vessage Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        
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
    
    func observeOnFileUploadedForVessage(taskId:String,vessageId:String,fileKey:FileAccessInfo){
        let task = VessageFileUploadTask()
        task.taskId = taskId
        task.fileId = fileKey.fileId
        task.vessageId = vessageId
        task.saveModel()
        ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
    }
    
    //MARK: ProgressTask Delegate
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(VessageFileUploadTask.self, idValue: taskIdentifier){
            self.finishSendVessage(task)
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(VessageFileUploadTask.self, idValue: taskIdentifier){
            self.cancelSendVessage(task.vessageId)
            PersistentManager.sharedInstance.removeModel(task)
        }
    }
    
    private func finishSendVessage(task:VessageFileUploadTask){
        if let m = getSendVessageResult(task.vessageId){
            let req = FinishSendVessageRequest()
            req.vessageId = m.vessageId
            req.vessageBoxId = m.vessageBoxId
            req.fileId = task.fileId
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req, callback: { (result) -> Void in
                if result.isSuccess{
                    MobClick.event("TotalPostVessages")
                    var userInfo = [String:AnyObject]()
                    PersistentManager.sharedInstance.removeModel(task)
                    userInfo.updateValue(task, forKey: SendedVessageTaskValue)
                    PersistentManager.sharedInstance.removeModel(m)
                    userInfo.updateValue(m, forKey: SendedVessageResultModelValue)
                    self.postNotificationName(VessageService.onNewVessageSended, object: self, userInfo:userInfo)
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
    
    func readVessage(vessage:Vessage){
        vessage.isRead = true
        vessage.saveModel()
        PersistentManager.sharedInstance.refreshCache(Vessage)
        self.postNotificationNameWithMainAsync(VessageService.onVessageRead, object: self, userInfo: [VessageServiceNotificationValue:vessage])
    }
    
    func removeVessage(vessage:Vessage){
        if vessage.isRead == false{
            self.postNotificationNameWithMainAsync(VessageService.onVessageRead, object: self, userInfo: [VessageServiceNotificationValue:vessage])
        }
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
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        SystemSoundHelper.vibrate()
                        vsgs.forEach({ (vsg) -> () in
                            self.postNotificationName(VessageService.onNewVessageReceived, object: self, userInfo: [VessageServiceNotificationValue:vsg])
                        })
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
        var vsgs = PersistentManager.sharedInstance.getAllModelFromCache(Vessage).filter{($0.sender == chatterId) }
        vsgs.sortInPlace { (a, b) -> Bool in
            a.sendTime.dateTimeOfAccurateString.isAfter(b.sendTime.dateTimeOfAccurateString)
        }
        return vsgs.first
    }
    
    func getNotReadVessage(chatterId:String) -> [Vessage]{
        return PersistentManager.sharedInstance.getAllModelFromCache(Vessage).filter{$0.isRead == false && ($0.sender == chatterId) }
    }
}