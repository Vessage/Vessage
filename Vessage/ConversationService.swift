//
//  ConversationService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let ConversationUpdatedValue = "ConversationUpdatedValue"

//MARK:ConversationService
class ConversationService:NSNotificationCenter, ServiceProtocol {
    static let conversationListUpdated = "conversationListUpdated"
    static let conversationUpdated = "conversationUpdated"
    @objc static var ServiceName:String {return "Conversation Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        self.setServiceReady()
        refreshConversations()
        if conversations.count == 0{
            getConversationListFromServer()
        }
    }
    
    @objc func userLogout(userId: String) {
        
    }
    
    private(set) var conversations = [Conversation]()
    
    private func refreshConversations(){
        conversations.removeAll()
        conversations.appendContentsOf(PersistentManager.sharedInstance.getAllModel(Conversation))
        conversations.sortInPlace { (a, b) -> Bool in
            a.lastMessageTime.dateTimeOfAccurateString.timeIntervalSince1970 > b.lastMessageTime.dateTimeOfAccurateString.timeIntervalSince1970
        }
        self.postNotificationName(ConversationService.conversationListUpdated, object: self,userInfo: nil)
    }
    
    func getConversationListFromServer(callback:(()->Void)! = nil){
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            conversations.append(testConversation)
            return
        }
        
        let req = GetConversationListRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[Conversation]>) -> Void in
            if let returns = result.returnObject{
                Conversation.saveObjectOfArray(returns)
                self.refreshConversations()
                if let handler = callback{
                    handler()
                }
            }
        }
    }
    
    func openConversationByMobile(mobile:String,callback:(updatedConversation:Conversation?)->Void) -> Conversation? {
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            callback(updatedConversation: testConversation)
            return testConversation
        }
        
        if let conversation = (conversations.filter{$0.chatterMobile == mobile}).first{
            return conversation
        }else{
            let req = CreateConversationRequest()
            req.mobile = mobile
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<Conversation>) -> Void in
                if let c = result.returnObject{
                    c.saveModel()
                    callback(updatedConversation: c)
                }else{
                    callback(updatedConversation: nil)
                }
            }
        }
        return nil
    }
    
    func openConversationByUserId(userId:String,callback:(updatedConversation:Conversation?)->Void) -> Conversation? {
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            return testConversation
        }
        
        
        if let conversation = (conversations.filter{$0.chatterId == userId}).first{
            return conversation
        }else{
            let req = CreateConversationRequest()
            req.userId = userId
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<Conversation>) -> Void in
                if let c = result.returnObject{
                    c.saveModel()
                    callback(updatedConversation: c)
                }else{
                    callback(updatedConversation: nil)
                }
            }
        }
        return nil
    }
    
    //MARK:TODO: delete test
    var testConversation:Conversation{
        let conversation = Conversation()
        conversation.chatterId = "asdfasd"
        conversation.chatterMobile = "15800038672"
        conversation.chatterNoteName = "xxx"
        conversation.conversationId = "asdfasdddd"
        conversation.lastMessageTime = NSDate().toFriendlyString()
        return conversation
    }
    
    func removeConversation(conversationId:String,callback:(suc:Bool)->Void){
        let req = RemoveConversationRequest()
        req.conversationId = conversationId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) -> Void in
            if result.isSuccess{
                if let c = (self.conversations.removeElement{$0.conversationId == conversationId}).first{
                    PersistentManager.sharedInstance.removeModel(c)
                }
            }
            callback(suc: result.isSuccess)
        }
    }
    
    func searchConversation(keyword:String)->[Conversation]{
        let result = conversations.filter{$0.chatterNoteName.containsString(keyword) || $0.chatterMobile == keyword}
        return result
    }
    
    func noteConversation(conversationId:String,noteName:String,callback:(suc:Bool)->Void){
        let req = NoteConversationRequest()
        req.conversationId = conversationId
        req.noteName = noteName
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) -> Void in
            if result.isSuccess{
                if let c = PersistentManager.sharedInstance.getModel(Conversation.self, idValue: conversationId){
                    c.chatterNoteName = noteName
                }
            }
            callback(suc: result.isSuccess)
        }
    }
}