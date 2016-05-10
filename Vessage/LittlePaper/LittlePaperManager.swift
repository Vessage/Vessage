//
//  LittlePaperManager.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class LittlePaperManager {
    static private(set) var instance:LittlePaperManager!
    static func initManager(){
        instance = LittlePaperManager()
        instance.loadCachedData()
    }
    
    static func releaseManager(){
        instance = nil
    }
    
    private(set) var mySendedMessages = [LittlePaperMessage]()
    private(set) var myOpenedMessages = [LittlePaperMessage]()
    private(set) var myPostededMessages = [LittlePaperMessage]()
    private(set) var myNotDealMessages = [LittlePaperMessage]()
    
    private func loadCachedData(){
        let myUserId = ServiceContainer.getUserService().myProfile.userId
        var msgs = PersistentManager.sharedInstance.getAllModel(LittlePaperMessage)
        mySendedMessages.appendContentsOf(msgs.removeElement{$0.isMySended(myUserId)})
        myOpenedMessages.appendContentsOf(msgs.removeElement{$0.isMyOpened(myUserId)})
        myPostededMessages.appendContentsOf(msgs.removeElement{$0.isMyPosted(myUserId)})
        myNotDealMessages.appendContentsOf(msgs.removeElement{$0.isReceivedNotDeal(myUserId)})
    }
    
    func openPaperMessage(paperId:String,callback:(openedMsg:LittlePaperMessage?)->Void) -> Void {
        let req = OpenPaperMessageRequest()
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<LittlePaperMessage>) in
            if result.isSuccess{
                let msg = self.myNotDealMessages.removeElement{$0.paperId == paperId}
                self.myOpenedMessages.insertContentsOf(msg, at: 0)
            }
            callback(openedMsg: result.returnObject)
        }
    }
    
    func postPaperToNextUser(paperId:String,userId:String,callback:(suc:Bool)->Void) -> Void {
        let req = PostPaperMessageRequest()
        req.setNextReceiver(userId)
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                let msg = self.myNotDealMessages.removeElement{$0.paperId == paperId}
                self.myPostededMessages.insertContentsOf(msg, at: 0)
            }
            callback(suc: result.isSuccess)
        }
    }
    
    func refreshPaperMessage(callback:(updated:Int)->Void) {
        let req = GetPaperMessagesStatusRequest()
        var msgs = [LittlePaperMessage]()
        msgs.appendContentsOf(mySendedMessages)
        msgs.appendContentsOf(myPostededMessages)
        let ids = msgs.map{$0.paperId!}
        req.setPaperId(ids.joinWithSeparator(","))
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[LittlePaperMessage]>) in
            var updated = 0
            if let resultMsgs = result.returnObject{
                for m in resultMsgs{
                    if let msg = (msgs.filter{$0.paperId == m.paperId}).first{
                        if msg.updatedTime.dateTimeOfAccurateString.isBefore(m.updatedTime.dateTimeOfAccurateString){
                            m.isUpdated = true
                            updated += 1
                            m.saveModel()
                            if (self.mySendedMessages.removeElement{$0.paperId == m.paperId}).count > 0{
                                self.mySendedMessages.insert(m, atIndex: 0)
                            }else if(self.myPostededMessages.removeElement{$0.paperId == m.paperId}).count > 0{
                                self.myPostededMessages.insert(m, atIndex: 0)
                            }
                        }
                    }
                }
            }
            callback(updated:updated)
        }
    }
    
    func getPaperMessages(callback:(suc:Bool)->Void){
        let req = GetReceivedPaperMessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[LittlePaperMessage]>) in
            if let msgs = result.returnObject{
                msgs.saveBahamutObjectModels()
                self.myNotDealMessages = msgs
            }
            callback(suc: result.isSuccess)
        }
    }
    
    func newPaperMessage(message:String,receiverInfo:String,nextReceiver:String,callback:(suc:Bool)->Void) -> Void {
        let req = NewPaperMessageRequest()
        req.setMessage(message)
        req.setNextReceiver(nextReceiver)
        req.setReceiverInfo(receiverInfo)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<LittlePaperMessage>) in
            if let msg = result.returnObject{
                msg.saveModel()
                self.mySendedMessages.insert(msg, atIndex: 0)
                callback(suc: true)
            }else{
                callback(suc: false)
            }
        }
    }
}