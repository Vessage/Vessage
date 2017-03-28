//
//  VessageTimeMachine.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class VessageTimeMachineItem {
    var vessage:Vessage!
    var chatter:String!
}

extension VessageTimeMachineItem{
    
    func getVessageTimeMachineTitle() -> String {
        let userService = ServiceContainer.getUserService()
        
        let dateString = self.vessage?.getSendTime()?.toFriendlyString() ?? "UNKNOW_TIME".localizedString()
        let nickString = (self.vessage?.isMySendingVessage() ?? false) ? "ME".localizedString() : userService.getUserNotedName(self.vessage.getVessageRealSenderId() ?? "")
        return String(format: "X_AT_D".localizedString(), nickString,dateString)
    }
    
    func getSubline() -> String {
        switch vessage?.typeId ?? -1 {
        case Vessage.typeFaceText:
            return self.vessage.getBodyDict()["textMessage"] as? String ?? "UNKNOW_TEXT".localizedString()
        case Vessage.typeImage:
            return "SEND_AN_IMAGE".localizedString()
        case Vessage.typeChatVideo:
            return "SEND_A_CHAT_VIDEO".localizedString()
        case Vessage.typeLittleVideo:
            return "SEND_A_LITTLE_VIDEO".localizedString()
        default:
            return "SEND_AN_UNKNOW_VESSAGE".localizedString()
        }
    }
}


class VessageTimeMachine :NSObject{
    
    static let coreDataModelId = "VessageTimeMachine"
    static let recordEntityName = "VTMRecord"
    
    fileprivate var coreDb:CoreDataManager!
    
    static var instance:VessageTimeMachine = {
       return VessageTimeMachine()
    }()
    
    func initWithUserId(_ userId:String){
        coreDb = CoreDataManager()
        let url = ServiceContainer.getFileService().documentsPathUrl.appendingPathComponent("vtimemachine.sqlite")
        coreDb.initManager(VessageTimeMachine.coreDataModelId, dbFileUrl: url, momdBundle: Bundle.main)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(VessageTimeMachine.onVessagesRemoved(_:)), name: VessageService.onVessagesRemoved, object: nil)
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(VessageTimeMachine.onNewVessagePushed(_:)), name: VessageQueue.onPushNewVessageTask, object: nil)
        
    }
    
    func releaseManager(){
        ServiceContainer.getVessageService().removeObserver(self)
        VessageQueue.sharedInstance.removeObserver(self)
        coreDb.deinitManager()
    }
    
    func onNewVessagePushed(_ a:Notification) {
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if let vsg = task.vessage {
                pushRecord(task.receiverId, vessage: vsg)
                coreDb.saveNow()
            }
        }
    }
    
    func onVessagesRemoved(_ a:Notification) {
        if let vsgs = a.userInfo?[VessageServiceNotificationValues] as? [Vessage]{
            for vsg in vsgs {
                pushRecord(vsg.sender, vessage: vsg)
            }
            coreDb.saveNow()
        }
    }
    
    func getVessageBefore(_ chatter:String,ts:Int64,limit:Int = 20) -> [VessageTimeMachineItem] {
        let predict = NSPredicate(format: "chatterId = '\(chatter)' and mtime < \(ts)")
        let sort = NSSortDescriptor(key: "mtime", ascending: false)
        let resultSet = coreDb.getCells(VessageTimeMachine.recordEntityName, predicate: predict,limit: limit,sortDescriptors:[sort]).map { (model) -> VTMRecord in
            return model as! VTMRecord
            }.sorted(by: { (a, b) -> Bool in
                a.mtime.int64Value < b.mtime.int64Value
            }).map { (record) -> VessageTimeMachineItem in
                let item = VessageTimeMachineItem()
                item.chatter = record.chatterId
                item.vessage = Vessage(json: record.modelValue)
                return item
        }
        return resultSet
    }
    
    fileprivate func pushRecord(_ chatter:String,vessage:Vessage) {
        let mobj = coreDb.insertNewCell(VessageTimeMachine.recordEntityName)
        if let obj = mobj as? VTMRecord{
            obj.chatterId = chatter
            obj.ctime = NSNumber(value: DateHelper.UnixTimeSpanTotalMilliseconds as Int64)
            obj.mtime = NSNumber(value: vessage.ts as Int64)
            obj.modelValue = vessage.toMiniJsonString()
        }
    }
}
