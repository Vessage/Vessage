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
    static private(set) var inited = false
    static func initManager(){
        if instance == nil {
            instance = LittlePaperManager()
        }
        instance.loadCachedData()
        inited = true
    }
    
    static func releaseManager(){
        inited = false
        PersistentManager.sharedInstance.saveAll()
        instance.paperMessagesList = nil
    }
    
    static let ACTIVITY_ID = "1000"
    
    static let TYPE_MY_SENDED = 3
    static let TYPE_MY_OPENED = 2
    static let TYPE_MY_POSTED = 1
    static let TYPE_MY_NOT_DEAL = 0
    
    private(set) var paperMessagesList:[[LittlePaperMessage]]!
    
    private(set) var mySendedMessages:[LittlePaperMessage]!{
        get{
            return paperMessagesList?[LittlePaperManager.TYPE_MY_SENDED]
        }
        set{
            paperMessagesList[LittlePaperManager.TYPE_MY_SENDED] = newValue
        }
    }
    private(set) var myOpenedMessages:[LittlePaperMessage]!{
        get{
            return paperMessagesList?[LittlePaperManager.TYPE_MY_OPENED]
        }
        set{
            paperMessagesList?[LittlePaperManager.TYPE_MY_OPENED] = newValue
        }
    }
    private(set) var myPostededMessages:[LittlePaperMessage]!{
        get{
            return paperMessagesList?[LittlePaperManager.TYPE_MY_POSTED]
        }
        set{
            paperMessagesList?[LittlePaperManager.TYPE_MY_POSTED] = newValue
        }
    }
    private(set) var myNotDealMessages:[LittlePaperMessage]!{
        get{
            return paperMessagesList?[LittlePaperManager.TYPE_MY_NOT_DEAL]
        }
        set{
            paperMessagesList?[LittlePaperManager.TYPE_MY_NOT_DEAL] = newValue
        }
    }
    
    private(set) var readPaperResponses = [LittlePaperReadResponse]()
    
    var notReadResponseCount:Int{
        return readPaperResponses.filter{!$0.isRead}.count
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
        paperMessagesList = [[LittlePaperMessage]](count: 4, repeatedValue: [LittlePaperMessage]())
        myUserId = UserSetting.userId
        var msgs = PersistentManager.sharedInstance.getAllModel(LittlePaperMessage)
        mySendedMessages.appendContentsOf(msgs.removeElement{$0.isMySended(self.myUserId)})
        myOpenedMessages.appendContentsOf(msgs.removeElement{$0.isMyOpened(self.myUserId)})
        myPostededMessages.appendContentsOf(msgs.removeElement{$0.isMyPosted(self.myUserId)})
        myNotDealMessages.appendContentsOf(msgs.removeElement{$0.isReceivedNotDeal(self.myUserId)})
        loadAskPapers()
    }
    
    private func loadAskPapers(){
        readPaperResponses.removeAll()
        let requests = PersistentManager.sharedInstance.getAllModel(LittlePaperReadResponse)
        readPaperResponses.appendContentsOf(requests)
    }
    
    func getReadPaperResponses(callback:()->Void) {
        let req = GetReadPaperResponsesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[LittlePaperReadResponse]>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
            if let objs = result.returnObject{
                objs.saveBahamutObjectModels()
                self.loadAskPapers()
                self.clearGotResponses()
                callback()
            }
        }
    }
    
    func clearGotResponses() {
        let req = ClearGotResponsesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
        }
    }
    
    func askReadPaper(paperId:String,callback:(sended:Bool,errorMsg:String?)->Void) {
        let req = AskSenderReadPaperRequest()
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req){ (result:SLResult<MsgResult>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
            if result.isSuccess{
                callback(sended: true, errorMsg: nil)
            }else{
                callback(sended: false, errorMsg: result.returnObject.msg ?? "UNKNOW_ERROR")
            }
        }
    }
    
    func removeReadResponse(paperId:String) {
        let resps = readPaperResponses.removeElement{$0.paperId == paperId}
        PersistentManager.sharedInstance.removeModels(resps)
    }
    
    func openAcceptLessPaper(paperId:String,callback:(openedMsg:LittlePaperMessage?,errorMsg:String?)->Void) {
        let req = OpenAcceptlessPaperRequest()
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<LittlePaperMessage>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
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
    
    func acceptReadPaperForReader(paperId:String,reader:String,callback:(isOk:Bool,errorMsg:String?)->Void) -> Void {
        let req = AcceptReadPaperRequest()
        req.setPaperId(paperId)
        req.setReader(reader)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
            if result.isSuccess{
                let reqs = self.readPaperResponses.removeElement{$0.paperId == paperId}
                PersistentManager.sharedInstance.removeModels(reqs)
                callback(isOk: true, errorMsg: nil)
            }else{
                callback(isOk: false, errorMsg: result.returnObject?.msg ?? "UNKNOW_ERROR")
            }
        }
    }
    
    func rejectReadPaperForReader(paperId:String,reader:String,callback:(isOk:Bool,errorMsg:String?)->Void) -> Void {
        let req = RejectReadPaperRequest()
        req.setPaperId(paperId)
        req.setReader(reader)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
            if result.isSuccess{
                let reqs = self.readPaperResponses.removeElement{$0.paperId == paperId}
                PersistentManager.sharedInstance.removeModels(reqs)
                callback(isOk: true, errorMsg: nil)
            }else{
                callback(isOk: false, errorMsg: result.returnObject?.msg ?? "UNKNOW_ERROR")
            }
        }
    }
    
    func postPaperToNextUser(paperId:String,userId:String,isAnonymous: Bool,callback:(suc:Bool,msg:String?)->Void) -> Void {
        let req = PostPaperMessageRequest()
        req.setIsAnonymous(isAnonymous)
        req.setNextReceiver(userId)
        req.setPaperId(paperId)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
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
    
    private func refreshPaperMessage(messages:[LittlePaperMessage],callback:(updated:Int)->Void){
        let ids = messages.map{$0.paperId!}
        if ids.count == 0{
            callback(updated: 0)
            return
        }
        let req = GetPaperMessagesStatusRequest()
        req.setPaperId(ids)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[LittlePaperMessage]>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
            var updated = 0
            if let resultMsgs = result.returnObject{
                for m in resultMsgs{
                    if let msg = (messages.filter{$0.paperId == m.paperId}).first{
                        if msg.uTs < m.uTs{
                            m.isUpdated = true
                            updated += 1
                            m.saveModel()
                            if (self.mySendedMessages.removeElement{$0.paperId == m.paperId}).count > 0{
                                self.mySendedMessages.insert(m, atIndex: 0)
                            }else if(self.myPostededMessages.removeElement{$0.paperId == m.paperId}).count > 0{
                                self.myPostededMessages.insert(m, atIndex: 0)
                            }
                            if m.isMyOpened(self.myUserId){
                                self.myOpenedMessages.removeElement{$0.paperId == m.paperId}
                                self.myOpenedMessages.insert(m, atIndex: 0)
                            }
                        }
                    }
                }
            }
            callback(updated:updated)
        }
    }
    
    func refreshOpenedPaper(paperMessage:LittlePaperMessage,callback:(updatedPaper:LittlePaperMessage?)->Void) {
        refreshPaperMessage([paperMessage]) { (updated) in
            if updated > 0{
                let paper = PersistentManager.sharedInstance.getModel(LittlePaperMessage.self, idValue: paperMessage.paperId)
                callback(updatedPaper: paper)
            }else{
                callback(updatedPaper: nil)
            }
        }
    }
    
    func refreshPaperMessage(callback:(updated:Int)->Void) {
        var msgs = [LittlePaperMessage]()
        msgs.appendContentsOf(mySendedMessages.filter{!$0.isOpened})
        msgs.appendContentsOf(myPostededMessages.filter{!$0.isOpened})
        refreshPaperMessage(msgs, callback: callback)
    }
    
    func openPaperMessage(paperId:String) -> LittlePaperMessage? {
        return PersistentManager.sharedInstance.getModel(LittlePaperMessage.self, idValue: paperId)
    }
    
    func clearPaperMessageUpdated(paperMessage:LittlePaperMessage) {
        paperMessagesList.forEach { (list) in
            list.forEach({ (msg) in
                if msg.paperId == paperMessage.paperId{
                    if paperMessage.isUpdated{
                        paperMessage.isUpdated = false
                        paperMessage.saveModel()
                        if msg != paperMessage{
                            msg.isUpdated = false
                        }
                    }
                }
            })
        }
        if paperMessage.isUpdated {
            paperMessage.isUpdated = false
            paperMessage.saveModel()
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
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
            if let msgs = result.returnObject{
                msgs.saveBahamutObjectModels()
                self.myNotDealMessages = msgs
            }
            callback(suc: result.isSuccess)
        }
    }
    
    func newPaperMessage(message:String,receiverInfo:String,nextReceiver:String,openNeedAccept:Bool,callback:(suc:Bool)->Void) -> Void {
        let req = NewPaperMessageRequest()
        req.setMessage(message)
        req.setOpenNeedAccept(openNeedAccept)
        req.setNextReceiver(nextReceiver)
        req.setReceiverInfo(receiverInfo)
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<LittlePaperMessage>) in
            if !LittlePaperManager.inited {print("LittlePaperManager Released");return}
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
