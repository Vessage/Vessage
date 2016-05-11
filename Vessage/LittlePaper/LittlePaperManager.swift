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
    
    static let TYPE_MY_SENDED = 3
    static let TYPE_MY_OPENED = 2
    static let TYPE_MY_POSTED = 1
    static let TYPE_MY_NOT_DEAL = 0
    
    private(set) var paperMessagesList = [[LittlePaperMessage]](count: 4, repeatedValue: [LittlePaperMessage]())
    
    private(set) var mySendedMessages:[LittlePaperMessage]{
        get{
            return paperMessagesList[LittlePaperManager.TYPE_MY_SENDED]
        }
        set{
            paperMessagesList[LittlePaperManager.TYPE_MY_SENDED] = newValue
        }
    }
    private(set) var myOpenedMessages:[LittlePaperMessage]{
        get{
            return paperMessagesList[LittlePaperManager.TYPE_MY_OPENED]
        }
        set{
            paperMessagesList[LittlePaperManager.TYPE_MY_OPENED] = newValue
        }
    }
    private(set) var myPostededMessages:[LittlePaperMessage]{
        get{
            return paperMessagesList[LittlePaperManager.TYPE_MY_POSTED]
        }
        set{
            paperMessagesList[LittlePaperManager.TYPE_MY_POSTED] = newValue
        }
    }
    private(set) var myNotDealMessages:[LittlePaperMessage]{
        get{
            return paperMessagesList[LittlePaperManager.TYPE_MY_NOT_DEAL]
        }
        set{
            paperMessagesList[LittlePaperManager.TYPE_MY_NOT_DEAL] = newValue
        }
    }
    
    private var myUserId:String!
    
    private func loadCachedData(){
        myUserId = ServiceContainer.getUserService().myProfile.userId
        
        var msgs = PersistentManager.sharedInstance.getAllModel(LittlePaperMessage)
        
        //TODO:Delete Test
        msgs = test()
        
        mySendedMessages.appendContentsOf(msgs.removeElement{$0.isMySended(self.myUserId)})
        myOpenedMessages.appendContentsOf(msgs.removeElement{$0.isMyOpened(self.myUserId)})
        myPostededMessages.appendContentsOf(msgs.removeElement{$0.isMyPosted(self.myUserId)})
        myNotDealMessages.appendContentsOf(msgs.removeElement{$0.isReceivedNotDeal(self.myUserId)})
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
    
    func postPaperToNextUser(paperId:String,userId:String,isAnonymous: Bool,callback:(suc:Bool)->Void) -> Void {
        let req = PostPaperMessageRequest()
        req.setIsAnonymous(isAnonymous)
        req.setNextReceiver(userId)
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                if let msg = (self.myNotDealMessages.removeElement{$0.paperId == paperId}).first{
                    if String.isNullOrWhiteSpace(msg.postmen){
                        msg.postmen.appendContentsOf(self.myUserId)
                    }else{
                        msg.postmen.appendContentsOf(",\(self.myUserId)")
                    }
                    self.myPostededMessages.insert(msg, atIndex: 0)
                }
            }
            callback(suc: result.isSuccess)
        }
    }
    
    func refreshPaperMessage(callback:(updated:Int)->Void) {
        let req = GetPaperMessagesStatusRequest()
        var msgs = [LittlePaperMessage]()
        msgs.appendContentsOf(mySendedMessages.filter{!$0.isOpened})
        msgs.appendContentsOf(myPostededMessages.filter{!$0.isOpened})
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
    
    func removePaperMessage(type:Int,index:Int) {
        if paperMessagesList.count > type && paperMessagesList[type].count > index  {
            BahamutObject.deleteObjectArray([paperMessagesList[type][index]])
            paperMessagesList[type].removeAtIndex(index)
        }
    }
    
    func clearPaperMessageList(type:Int) {
        if paperMessagesList.count > type {
            BahamutObject.deleteObjectArray(paperMessagesList[type])
            paperMessagesList[type].removeAll()
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
    
    //TODO:Delete Test
    private func test() -> [LittlePaperMessage]{
        
//        AccountId=147258,UserId=56e659cbdba47c3604b1384e
//        AccountId=147259,UserId=56e6c6b0dba47c0d58cb6429
//        AccountId=147260,UserId=56ee6cd3fa1de5319005954a
//        AccountId=147261,UserId=56ee7110fa1de5319005954b
//        AccountId=147262,UserId=56f01076fa1de5617886a889
//        AccountId=147263,UserId=56f00ea7fa1de5617886a888
        
        var msgs = [LittlePaperMessage]()
        let sendedmsg = LittlePaperMessage()
        sendedmsg.isOpened = false
        sendedmsg.sender = myUserId
        sendedmsg.message = "Test"
        sendedmsg.paperId = "123456"
        sendedmsg.receiverInfo = "Test Receiver Send Not Open"
        sendedmsg.updatedTime = NSDate().toAccurateDateTimeString()
        msgs.append(sendedmsg)
        
        let sendedOpedMsg = LittlePaperMessage()
        sendedOpedMsg.paperId = "dddd"
        sendedOpedMsg.isOpened = true
        sendedOpedMsg.sender = myUserId
        sendedOpedMsg.postmen = "\(myUserId),56ee7110fa1de5319005954b,56ee6cd3fa1de5319005954a,56e6c6b0dba47c0d58cb6429"
        sendedOpedMsg.receiver = "56f00ea7fa1de5617886a888"
        sendedOpedMsg.receiverInfo = "Test Receiver Send Opened"
        sendedOpedMsg.updatedTime = NSDate().toAccurateDateTimeString()
        msgs.append(sendedOpedMsg)
        
        var notDealMsg = LittlePaperMessage()
        notDealMsg.isOpened = false
        notDealMsg.message = "Test"
        notDealMsg.paperId = "sdfasdfs"
        notDealMsg.postmen = "56ee7110fa1de5319005954b"
        notDealMsg.receiverInfo = "Test Receiver Not Deal"
        notDealMsg.updatedTime = NSDate().toAccurateDateTimeString()
        msgs.append(notDealMsg)
        
        notDealMsg = LittlePaperMessage()
        notDealMsg.isOpened = false
        notDealMsg.message = "Test"
        notDealMsg.paperId = "sdfasdfsss"
        notDealMsg.postmen = "56ee7110fa1de5319005954b,\(myUserId)"
        notDealMsg.receiverInfo = "Test Receiver Posted"
        notDealMsg.updatedTime = NSDate().toAccurateDateTimeString()
        msgs.append(notDealMsg)
        
        notDealMsg = LittlePaperMessage()
        notDealMsg.isOpened = true
        notDealMsg.message = "Test"
        notDealMsg.paperId = "sdfddasdfsss"
        notDealMsg.postmen = "56ee7110fa1de5319005954b,\(myUserId)"
        notDealMsg.receiverInfo = "Test Receiver Posted Opened"
        notDealMsg.updatedTime = NSDate().toAccurateDateTimeString()
        msgs.append(notDealMsg)
        
        notDealMsg = LittlePaperMessage()
        notDealMsg.isOpened = true
        notDealMsg.message = "Test My Opened"
        notDealMsg.paperId = "sdfasdfsssss"
        notDealMsg.sender = "56f01076fa1de5617886a889"
        notDealMsg.postmen = "56ee7110fa1de5319005954b,56e6c6b0dba47c0d58cb6429"
        notDealMsg.receiverInfo = "Test Receiver I Opened"
        notDealMsg.receiver = myUserId
        notDealMsg.updatedTime = NSDate().toAccurateDateTimeString()
        msgs.append(notDealMsg)
        
        return msgs
    }
}