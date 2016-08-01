//
//  VessageService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let VessageServiceNotificationValue = "VessageServiceNotificationValue"
let VessageServiceNotificationValues = "VessageServiceNotificationValue"
let SendedVessageResultModelValue = "SendedVessageResultModelValue"

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getVessageService() -> VessageService{
        return ServiceContainer.getService(VessageService)
    }
}

//MARK: VessageService
class VessageService:NSNotificationCenter, ServiceProtocol {
    static let onNewVessageReceived = "onNewVessageReceived"
    static let onNewVessagesReceived = "onNewVessagesReceived"
    
    static let onNewVessagePostFinished = "onNewVessagePostFinished"
    static let onNewVessagePostFinishError = "onNewVessagePostFinishError"
    
    static let onVessageRead = "onVessageRead"
    static let onVessageRemoved = "onVessageRemoved"
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
            self.postNotificationNameWithMainAsync(VessageService.onVessageRemoved, object: self, userInfo: [VessageServiceNotificationValue:vessage])
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

//MARK: Send Vessage
extension VessageService{
    private func sendVessageToMobile(receiverMobile:String,vessage:Vessage,callback:(vessageId:String?)->Void){
        let req = SendNewVessageToMobileRequest()
        req.receiverMobile = receiverMobile
        sendVessage(req, vessage: vessage) { (vessageId) -> Void in
            callback(vessageId: vessageId)
        }
    }
    
    func sendVessageToUser(receiverId:String?, vessage:Vessage, callback:(vessageId:String?)->Void){
        let req = SendNewVessageToUserRequest()
        req.receiverId = receiverId
        req.isGroup = vessage.isGroup
        sendVessage(req, vessage: vessage) { (vessageId) -> Void in
            callback(vessageId: vessageId)
        }
    }
    
    private func sendVessage(req:SendNewVessageRequestBase,vessage:Vessage,callback:(vessageId:String?)->Void){
        req.extraInfo = vessage.extraInfo
        req.fileId = vessage.fileId
        req.typeId = vessage.typeId
        req.body = vessage.body
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
    
    func finishSendVessage(vessageId:String,postUploadedFileId:String?,callback:(finished:Bool,sendVessageResultModel:SendVessageResultModel?)->Void) {
        if String.isNullOrEmpty(postUploadedFileId){
            let m = getSendVessageResult(vessageId)
            callback(finished: true, sendVessageResultModel: m)
            var userInfo = [NSObject:AnyObject]()
            if m != nil {
                PersistentManager.sharedInstance.removeModel(m!)
                userInfo.updateValue(m!, forKey: SendedVessageResultModelValue)
            }
            self.postNotificationNameWithMainAsync(VessageService.onNewVessagePostFinished, object: self, userInfo: userInfo)
            MobClick.event("Vege_TotalPostVessages")
        }else{
            if let m = getSendVessageResult(vessageId){
                let req = FinishSendVessageRequest()
                req.vessageId = m.vessageId
                req.vessageBoxId = m.vessageBoxId
                req.fileId = postUploadedFileId!
                BahamutRFKit.sharedInstance.getBahamutClient().execute(req, callback: { (result) -> Void in
                    var userInfo = [String:AnyObject]()
                    userInfo.updateValue(m, forKey: SendedVessageResultModelValue)
                    if result.isSuccess{
                        MobClick.event("Vege_TotalPostVessages")
                        PersistentManager.sharedInstance.removeModel(m)
                        callback(finished: true, sendVessageResultModel: m)
                        self.postNotificationNameWithMainAsync(VessageService.onNewVessagePostFinished, object: self, userInfo:userInfo)
                    }else{
                        callback(finished: false, sendVessageResultModel: m)
                        self.postNotificationNameWithMainAsync(VessageService.onNewVessagePostFinishError, object: self, userInfo:userInfo)
                    }
                })
            }
            
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
}