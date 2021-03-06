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
        return ServiceContainer.getService(VessageService.self)
    }
}

//MARK: VessageService
class VessageService:NotificationCenter, ServiceProtocol {
    static let onNewVessageReceived = "onNewVessageReceived".asNotificationName()
    static let onNewVessagesReceived = "onNewVessagesReceived".asNotificationName()
    
    static let onNewVessagePostFinished = "onNewVessagePostFinished".asNotificationName()
    static let onNewVessagePostFinishError = "onNewVessagePostFinishError".asNotificationName()
    
    static let onVessageRead = "onVessageRead".asNotificationName()
    static let onVessageRemoved = "onVessageRemoved".asNotificationName()
    static let onVessagesRemoved = "onVessagesRemoved".asNotificationName()
    
    @objc static var ServiceName:String {return "Vessage Service"}
    
    fileprivate var notReadVessageCountMap = [String:Int]()
    fileprivate var receivedCheckMap = [String:Int]()
    fileprivate var vsgCntLock = NSRecursiveLock()
    
    @objc func appStartInit(_ appName: String) {
        
    }
    
    @objc func userLoginInit(_ userId: String) {
        DispatchQueue.main.async {
            self.receivedCheckMap.removeAll()
            self.initNotReadVessageCountMap()
            self.setServiceReady()
        }
    }
    
    @objc func userLogout(_ userId: String) {
        setServiceNotReady()
    }
    
    fileprivate func initNotReadVessageCountMap(){
        var newestVsgMap = [String:Vessage]()
        let vsgs = PersistentManager.sharedInstance.getAllModel(Vessage.self)
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
        PersistentManager.sharedInstance.refreshCache(Vessage.self)
    }
    
    @discardableResult
    func readVessage(_ vessage:Vessage,refresh:Bool = true) -> Bool{
        if vessage.isRead || !vessage.isReceivedVessage() {
            return false
        }else {
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
            PersistentManager.sharedInstance.refreshCache(Vessage.self)
        }
        return true
    }
    
    func removeVessages(_ vessages:[Vessage]){
        var removed = [Vessage]()
        for vessage in vessages {
            if readVessage(vessage,refresh: false){
                removed.append(vessage)
                PersistentManager.sharedInstance.removeModel(vessage)
                post(name: VessageService.onVessageRemoved, object: self, userInfo: [VessageServiceNotificationValue:vessage])
            }
        }
        PersistentManager.sharedInstance.refreshCache(Vessage.self)
        post(name: VessageService.onVessagesRemoved, object: self, userInfo: [VessageServiceNotificationValues:removed])
    }
    
    func newVessageFromServer(_ completion:(()->Void)? = nil){
        
        //prepare received vessages check map
        let keySet = receivedCheckMap.keys.map{$0}.reversed()
        for key in keySet {
            let x = receivedCheckMap[key]
            if x == 1{
                receivedCheckMap.removeValue(forKey: key)
            }else{
                receivedCheckMap[key] = 1
            }
        }
        
        let req = GetNewVessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[Vessage]>) -> Void in
            var newVessages = [Vessage]()
            if var vsgs = result.returnObject{
                if vsgs.count > 0{
                    self.vsgCntLock.lock()
                    vsgs.sort(by: { (a, b) -> Bool in
                        a.ts < b.ts
                    })
                    vsgs.saveBahamutObjectModels()
                    PersistentManager.sharedInstance.saveAll()
                    PersistentManager.sharedInstance.refreshCache(Vessage.self)
                    for vsg in vsgs{
                        let key = "\(vsg.vessageId!)_\(vsg.sender!)_\(vsg.ts)".md5
                        
                        if !self.receivedCheckMap.keys.contains(key){
                            newVessages.append(vsg)
                            if let cnt = self.notReadVessageCountMap[vsg.sender]{
                                self.notReadVessageCountMap[vsg.sender] = cnt + 1
                            }else{
                                self.notReadVessageCountMap[vsg.sender] = 1
                            }
                            
                            self.post(name: VessageService.onNewVessageReceived, object: self, userInfo: [VessageServiceNotificationValue:vsg])
                        }
                        self.receivedCheckMap[key] = 0
                    }
                    
                    self.notifyVessageGot()
                    if newVessages.count > 0{
                        self.post(name: VessageService.onNewVessagesReceived, object: self, userInfo: [VessageServiceNotificationValues:newVessages])
                        SystemSoundHelper.playSound(1003)
                    }
                    self.vsgCntLock.unlock()
                }
            }
            completion?()
        }
    }
    
    fileprivate func notifyVessageGot(){
        let req = NotifyGotNewVessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
        }
    }
    
    func getCachedNewestVessage(_ chatterId:String) -> Vessage?{
        var vsgs = PersistentManager.sharedInstance.getAllModelFromCache(Vessage.self).filter{ !String.isNullOrWhiteSpace($0.sender) && $0.sender == chatterId }
        vsgs.sort { (a, b) -> Bool in
            a.ts > b.ts
        }
        return vsgs.first
    }
    
    func getChatterNotReadVessageCount(_ chatterId:String) -> Int{
        if let cnt = notReadVessageCountMap[chatterId] {
            return cnt
        }
        return notReadVessageCountMap[chatterId] ?? 0
    }
    
    func getNotReadVessages(_ chatterId:String) -> [Vessage]{
        return PersistentManager.sharedInstance.getAllModelFromCache(Vessage.self).filter{$0.isRead == false && (!String.isNullOrWhiteSpace($0.sender) && $0.sender == chatterId) }.sorted(by: { (a, b) -> Bool in
            a.ts < b.ts
        })
    }
    
    
}

//MARK: Send Vessage
extension VessageService{
    fileprivate func sendVessageToMobile(_ receiverMobile:String,vessage:Vessage,callback:@escaping (_ vessageId:String?)->Void){
        let req = SendNewVessageToMobileRequest()
        req.receiverMobile = receiverMobile
        sendVessage(req, vessage: vessage) { (vessageId) -> Void in
            callback(vessageId)
        }
    }
    
    func sendVessageToUser(_ receiverId:String?,vessage:Vessage, callback:@escaping (_ vessageId:String?)->Void){
        let req = SendNewVessageToUserRequest()
        req.receiverId = receiverId
        req.isGroup = vessage.isGroup
        sendVessage(req, vessage: vessage) { (vessageId) -> Void in
            callback(vessageId)
        }
    }
    
    fileprivate func sendVessage(_ req:SendNewVessageRequestBase,vessage:Vessage,callback:@escaping (_ vessageId:String?)->Void){
        req.extraInfo = vessage.extraInfo
        req.fileId = vessage.fileId
        req.typeId = vessage.typeId
        req.body = vessage.body
        req.ready = true
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<SendVessageResultModel>) -> Void in
            if let vrm = result.returnObject{
                vrm.saveModel()
                callback(vrm.vessageId)
            }else{
                callback(nil)
            }
        }
    }
    
    fileprivate func getSendVessageResult(_ vessageId:String) -> SendVessageResultModel?{
        return PersistentManager.sharedInstance.getModel(SendVessageResultModel.self, idValue: vessageId)
    }
    
    func finishSendVessage(_ vessageId:String,callback:(_ finished:Bool,_ sendVessageResultModel:SendVessageResultModel?)->Void) {
        let m = getSendVessageResult(vessageId)
        callback(true, m)
        var userInfo = [AnyHashable: Any]()
        if m != nil {
            PersistentManager.sharedInstance.removeModel(m!)
            userInfo.updateValue(m!, forKey: SendedVessageResultModelValue)
        }
        self.postNotificationNameWithMainAsync(VessageService.onNewVessagePostFinished, object: self, userInfo: userInfo)
        MobClick.event("Vege_TotalPostVessages")
    }
    
    func cancelSendVessage(_ vessageId:String){
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
    fileprivate func finishSendVessage(_ vessageId:String,fileId:String,callback:@escaping (_ finished:Bool,_ sendVessageResultModel:SendVessageResultModel?)->Void) {
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
                    callback(true, m)
                    self.postNotificationNameWithMainAsync(VessageService.onNewVessagePostFinished, object: self, userInfo:userInfo)
                }else{
                    callback(false, m)
                    self.postNotificationNameWithMainAsync(VessageService.onNewVessagePostFinishError, object: self, userInfo:userInfo)
                }
            })
        }
    }
}
