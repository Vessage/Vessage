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
    
    var mySendedMessageUpdatedCount:Int{
        return mySendedMessages.filter{$0.isUpdated}.count
    }
    
    var myPostededMessageUpdatedCount:Int{
        return myPostededMessages.filter{$0.isUpdated}.count
    }
    
    var myNotDealMessageUpdatedCount:Int{
        return myNotDealMessages.count
    }
    
    var myOpenedMessageUpdatedCount:Int{
        return myOpenedMessages.filter{$0.isUpdated}.count
    }
    
    var totalBadgeCount:Int{
        return mySendedMessageUpdatedCount + myPostededMessageUpdatedCount + myNotDealMessageUpdatedCount + myOpenedMessageUpdatedCount
    }
    
    private var myUserId:String!
    
    private func loadCachedData(){
        myUserId = ServiceContainer.getUserService().myProfile.userId
        var msgs = PersistentManager.sharedInstance.getAllModel(LittlePaperMessage)
        mySendedMessages.appendContentsOf(msgs.removeElement{$0.isMySended(self.myUserId)})
        myOpenedMessages.appendContentsOf(msgs.removeElement{$0.isMyOpened(self.myUserId)})
        myPostededMessages.appendContentsOf(msgs.removeElement{$0.isMyPosted(self.myUserId)})
        myNotDealMessages.appendContentsOf(msgs.removeElement{$0.isReceivedNotDeal(self.myUserId)})
    }
    
    func openPaperMessage(paperId:String,callback:(openedMsg:LittlePaperMessage?,errorMsg:String?)->Void) -> Void {
        let req = OpenPaperMessageRequest()
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<LittlePaperMessage>) in
            if result.isSuccess{
                let paper = result.returnObject
                paper.saveModel()
                self.myNotDealMessages.removeElement{$0.paperId == paperId}
                self.myOpenedMessages.insert(paper, atIndex: 0)
                callback(openedMsg: paper,errorMsg: nil)
            }else if result.statusCode == 400{
                callback(openedMsg: nil, errorMsg: "NO_SUCH_PAPER_ID")
            }else if result.statusCode == 403{
                callback(openedMsg: nil, errorMsg: "PAPER_OPENED")
            }else{
                callback(openedMsg: nil, errorMsg: "UNKNOW_ERROR")
            }
        }
    }
    
    func postPaperToNextUser(paperId:String,userId:String,isAnonymous: Bool,callback:(suc:Bool,msg:String?)->Void) -> Void {
        let req = PostPaperMessageRequest()
        req.setIsAnonymous(isAnonymous)
        req.setNextReceiver(userId)
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            var msg = "SUCCESS"
            if result.statusCode == 400{
                msg = "NO_SUCH_PAPER_ID"
            }else if result.statusCode == 403{
                msg = "USER_POSTED_THIS_PAPER"
            }
            if result.isSuccess{
                if let paper = (self.myNotDealMessages.removeElement{$0.paperId == paperId}).first{
                    if paper.postmen == nil{
                        paper.postmen = [self.myUserId]
                    }else{
                        paper.postmen.append(self.myUserId)
                    }
                    self.myPostededMessages.insert(paper, atIndex: 0)
                }
            }
            callback(suc: result.isSuccess,msg: msg)
        }
    }
    
    func refreshPaperMessage(callback:(updated:Int)->Void) {
        let req = GetPaperMessagesStatusRequest()
        var msgs = [LittlePaperMessage]()
        msgs.appendContentsOf(mySendedMessages.filter{!$0.isOpened})
        msgs.appendContentsOf(myPostededMessages.filter{!$0.isOpened})
        let ids = msgs.map{$0.paperId!}
        if ids.count == 0{
            return
        }
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
    
    func clearPaperMessageUpdated(type:Int,index:Int) {
        if paperMessagesList.count > type && paperMessagesList[type].count > index  {
            let msg = paperMessagesList[type][index]
            if msg.isUpdated {
                msg.isUpdated = false
                msg.saveModel()
            }
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
}