//
//  ConversationService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: Conversation
class Conversation:BahamutObject
{
    override func getObjectUniqueIdName() -> String {
        return "conversationId"
    }
    var conversationId:String!
    var chatterId:String!
    var chatterMobile:String!
    var noteName:String!
    var lastMessageTime:String!
}

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
    
    func openConversationByMobile(mobile:String, noteName:String?) -> Conversation {
        
        if let conversation = (conversations.filter{$0.chatterMobile == mobile}).first{
            return conversation
        }else{
            let conversation = Conversation()
            conversation.conversationId = IdUtil.generateUniqueId()
            conversation.noteName = String.isNullOrWhiteSpace(noteName) ? mobile : noteName
            conversation.chatterMobile = mobile
            conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
            conversation.saveModel()
            conversations.append(conversation)
            self.postNotificationName(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
    
    func openConversationByUserId(userId:String,noteName:String?) -> Conversation {
        
        if let conversation = (conversations.filter{userId == $0.chatterId ?? ""}).first{
            return conversation
        }else{
            let conversation = Conversation()
            conversation.conversationId = IdUtil.generateUniqueId()
            conversation.chatterId = userId
            conversation.noteName = noteName
            conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
            conversations.append(conversation)
            self.postNotificationName(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
    
    func updateConversationChatterIdWithMobile(chatterId:String,mobile:String){
        self.conversations.forEach { (con) -> () in
            if String.isNullOrWhiteSpace(con.chatterId) && con.chatterMobile == mobile{
                con.chatterId = chatterId
                con.saveModel()
            }
        }
        PersistentManager.sharedInstance.saveAll()
    }
    
    func removeConversation(conversationId:String) -> Bool{
        if let c = (self.conversations.removeElement{$0.conversationId == conversationId}).first{
            PersistentManager.sharedInstance.removeModel(c)
            self.postNotificationName(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return true
        }else{
            return false
        }
    }
    
    func searchConversation(keyword:String)->[Conversation]{
        let result = conversations.filter{
            ($0.noteName ?? "").containsString(keyword) || keyword == $0.chatterMobile
        }
        return result
    }
    
    func noteConversation(conversationId:String,noteName:String) -> Bool{
        if let conversation = PersistentManager.sharedInstance.getModel(Conversation.self, idValue: conversationId){
            conversation.noteName = noteName
            conversation.saveModel()
            return true
        }else{
            return false
        }
    }
}