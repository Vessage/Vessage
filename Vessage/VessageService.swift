//
//  VessageService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let VessageServiceNotificationValue = "VessageServiceNotificationValue"
let VessageServiceNotificationValues = "VessageServiceNotificationValues"
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
    static let onVessagesRemoved = "onVessagesRemoved"
    
    @objc static var ServiceName:String {return "Vessage Service"}
    
    private var notReadVessageCountMap = [String:Int]()
    private var receivedCheckMap = [String:Int]()
    private var vsgCntLock = NSRecursiveLock()
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.receivedCheckMap.removeAll()
            self.initNotReadVessageCountMap()
            self.setServiceReady()
        }
    }
    
    @objc func userLogout(userId: String) {
        setServiceNotReady()
    }
    
    private func initNotReadVessageCountMap(){
        var newestVsgMap = [String:Vessage]()
        let vsgs = PersistentManager.sharedInstance.getAllModel(Vessage)
        vsgCntLock.lock()
        notReadVessageCountMap.removeAll()
        vsgs.forEach { (vsg) in
            if !vsg.isRead{
                if let cnt = notReadVessageCountMap[vsg.sender]{
                    notReadVessageCountMap[vsg.sender] = cnt + 1
                }else{
                    notReadVessageCountMap[vsg.sender] = 1
                }
                
            }else{
                if let nvsg = newestVsgMap[vsg.sender]{
                    if nvsg.ts >= vsg.ts{
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
        vsgCntLock.unlock()
        PersistentManager.sharedInstance.saveAll()
        PersistentManager.sharedInstance.refreshCache(Vessage)
    }
    
    func readVessage(vessage:Vessage,refresh:Bool = true){
        if !vessage.isReceivedVessage() {
            return
        }
        if vessage.isRead == false{
            vessage.isRead = true
            vsgCntLock.lock()
            if var cnt = notReadVessageCountMap[vessage.sender]{
                cnt = cnt > 1 ? cnt - 1 : 0
                notReadVessageCountMap[vessage.sender] = cnt
            }else{
                notReadVessageCountMap[vessage.sender] = 0
            }
            vsgCntLock.unlock()
            self.postNotificationNameWithMainAsync(VessageService.onVessageRead, object: self, userInfo: [VessageServiceNotificationValue:vessage])
        }
        if refresh{
            vessage.saveModel()
            PersistentManager.sharedInstance.refreshCache(Vessage)
        }
    }
    
    func removeVessages(vessages:[Vessage]){
        var removed = [Vessage]()
        for vessage in vessages {
            if !vessage.isReceivedVessage() {
                continue
            }
            readVessage(vessage,refresh: false)
            removed.append(vessage)
            PersistentManager.sharedInstance.removeModel(vessage)
            postNotificationName(VessageService.onVessageRemoved, object: self, userInfo: [VessageServiceNotificationValue:vessage])
        }
        PersistentManager.sharedInstance.refreshCache(Vessage)
        postNotificationName(VessageService.onVessagesRemoved, object: self, userInfo: [VessageServiceNotificationValues:removed])
    }
    
    func newVessageFromServer(completion:(()->Void)? = nil){
        
        //prepare received vessages check map
        let keySet = receivedCheckMap.keys.map{$0}
        keySet.forEach { (key) in
            let x = receivedCheckMap[key]
            if x == 1{
                receivedCheckMap.removeValueForKey(key)
            }else{
                receivedCheckMap[key] = 1
            }
        }
        
        let req = GetNewVessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[Vessage]>) -> Void in
            var newVessages = [Vessage]()
            if var vsgs = result.returnObject{
                if vsgs.count > 0{
                    vsgs.sortInPlace({ (a, b) -> Bool in
                        a.ts < b.ts
                    })
                    vsgs.saveBahamutObjectModels()
                    PersistentManager.sharedInstance.saveAll()
                    PersistentManager.sharedInstance.refreshCache(Vessage)
                    vsgs.forEach({ (vsg) in
                        
                        let unexists = self.receivedCheckMap[vsg.vessageId] == nil
                        self.receivedCheckMap[vsg.vessageId] = 0
                        
                        if unexists{
                            newVessages.append(vsg)
                            self.vsgCntLock.lock()
                            if let cnt = self.notReadVessageCountMap[vsg.sender]{
                                self.notReadVessageCountMap[vsg.sender] = cnt + 1
                            }else{
                                self.notReadVessageCountMap[vsg.sender] = 1
                            }
                            self.vsgCntLock.unlock()
                            self.postNotificationName(VessageService.onNewVessageReceived, object: self, userInfo: [VessageServiceNotificationValue:vsg])
                        }
                    })
                    self.notifyVessageGot()
                    if newVessages.count > 0{
                        self.postNotificationName(VessageService.onNewVessagesReceived, object: self, userInfo: [VessageServiceNotificationValues:newVessages])
                        SystemSoundHelper.playSound(1003)
                    }
                }
            }
            completion?()
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
            a.ts > b.ts
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
        return PersistentManager.sharedInstance.getAllModelFromCache(Vessage).filter{$0.isRead == false && (!String.isNullOrWhiteSpace($0.sender) && $0.sender == chatterId) }.sort({ (a, b) -> Bool in
            a.ts < b.ts
        })
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
    
    func sendVessageToUser(receiverId:String?,vessage:Vessage, callback:(vessageId:String?)->Void){
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
        req.ready = true
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
    
    func finishSendVessage(vessageId:String,callback:(finished:Bool,sendVessageResultModel:SendVessageResultModel?)->Void) {
        let m = getSendVessageResult(vessageId)
        callback(finished: true, sendVessageResultModel: m)
        var userInfo = [NSObject:AnyObject]()
        if m != nil {
            PersistentManager.sharedInstance.removeModel(m!)
            userInfo.updateValue(m!, forKey: SendedVessageResultModelValue)
        }
        self.postNotificationNameWithMainAsync(VessageService.onNewVessagePostFinished, object: self, userInfo: userInfo)
        MobClick.event("Vege_TotalPostVessages")
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

//MARK: Deprecated
extension VessageService{
    private func finishSendVessage(vessageId:String,fileId:String,callback:(finished:Bool,sendVessageResultModel:SendVessageResultModel?)->Void) {
        if let m = getSendVessageResult(vessageId){
            let req = FinishSendVessageRequest()
            req.vessageId = m.vessageId
            req.vessageBoxId = m.vessageBoxId
            req.fileId = fileId
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
