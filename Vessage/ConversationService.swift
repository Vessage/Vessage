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
    
    func indexOfConversationOfUser(user:VessageUser) -> Int?{
        let updatedIndex = conversations.indexOf { (c) -> Bool in
            return ConversationService.isConversationWithUser(c, user: user)
        }
        return updatedIndex
    }
    
    static func isConversationWithUser(c:Conversation,user:VessageUser) -> Bool{
        if !String.isNullOrWhiteSpace(c.chatterId) && user.userId == c.chatterId{
            return true
        }else if let mobileHash = user.mobile{
            if let cMobile = c.chatterMobile?.md5{
                if mobileHash == cMobile{
                    return true
                }
            }
        }
        return false
    }
    
    static func isConversationVessage(c:Conversation,vsg:Vessage) -> Bool{
        if let chatterId = c.chatterId{
            if vsg.sender == chatterId{
                c.lastMessageTime = vsg.sendTime
                return true
            }
        }
        if let ei = vsg.getExtraInfoObject(){
            if ei.mobileHash != nil && ei.mobileHash == c.chatterMobile?.md5{
                if String.isNullOrWhiteSpace(c.chatterId){
                    c.chatterId = vsg.sender
                    c.saveModel()
                }
                return true
            }
        }
        return false
    }
    
    private func updateConversationWithVessage(vsg:Vessage) -> Int?{
        if let index = (conversations.indexOf { ConversationService.isConversationVessage($0, vsg: vsg)}){
            let conversation = conversations[index]
            if let ei = vsg.getExtraInfoObject(){
                if conversation.chatterId == nil{
                    conversation.chatterId = vsg.sender
                }
                if conversation.lastMessageTime.dateTimeOfAccurateString.isBefore(vsg.sendTime.dateTimeOfAccurateString){
                    conversation.lastMessageTime = vsg.sendTime
                }
                if conversation.noteName?.md5 == ei.mobileHash || conversation.noteName == ei.accountId{
                    conversation.noteName = ei.nickName ?? conversation.noteName
                }
                conversation.saveModel()
                self.postNotificationNameWithMainAsync(ConversationService.conversationUpdated, object: self, userInfo: [ConversationUpdatedValue:conversation])
            }
            return index
        }else{
            return nil
        }
    }
    
    func setConversationNewestModified(chatterId:String){
        let index = conversations.indexOf { (c) -> Bool in
            if let chatter = c.chatterId{
                if chatter == chatterId{
                    return true
                }
            }
            return false
        }
        setConversationNewestModifiedAt(index)
    }
    
    func setConversationNewestModifiedByMobile(mobile:String){
        let index = conversations.indexOf { (c) -> Bool in
            if let cmobile = c.chatterMobile{
                if cmobile == mobile{
                    return true
                }
            }
            return false
        }
        setConversationNewestModifiedAt(index)
    }
    
    private func setConversationNewestModifiedAt(index:Int?){
        if let i = index{
            let c = conversations.removeAtIndex(i)
            c.lastMessageTime = NSDate().toAccurateDateTimeString()
            c.saveModel()
            conversations.insert(c, atIndex: 0)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
        }
    }
    
    func updateConversationListWithVessagesReturnNewConversations(vsgs:[Vessage]) -> [Conversation] {
        var newConversations = [Conversation]()
        vsgs.forIndexEach { (i, element) in
            if let _ = self.updateConversationWithVessage(element){
                
            }else{
                let conversation = self.createConverationWithVessage(element)
                newConversations.append(conversation)
            }
        }
        sortConversationList()
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
        return newConversations
    }
    
    private func createConverationWithVessage(vsg:Vessage) -> Conversation{
        let ei = vsg.getExtraInfoObject()
        return self.addNewConversationWithUserId(vsg.sender, noteName: ei?.nickName ?? ei?.accountId ?? "UNKNOW_USER".localizedString())
    }
    
    private func refreshConversations(){
        conversations.removeAll()
        conversations.appendContentsOf(PersistentManager.sharedInstance.getAllModel(Conversation))
        sortConversationList()
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
    }
    
    private func sortConversationList(){
        conversations.sortInPlace { (a, b) -> Bool in
            a.lastMessageTime.dateTimeOfAccurateString.isAfter(b.lastMessageTime.dateTimeOfAccurateString)
        }
    }
    
    func openConversationByMobile(mobile:String, noteName:String?) -> Conversation {
        
        if let conversation = (conversations.filter{!String.isNullOrWhiteSpace($0.chatterMobile) && $0.chatterMobile == mobile}).first{
            return conversation
        }else{
            let conversation = Conversation()
            conversation.conversationId = IdUtil.generateUniqueId()
            conversation.noteName = String.isNullOrWhiteSpace(noteName) ? mobile : noteName
            conversation.chatterMobile = mobile
            conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
            conversation.saveModel()
            conversations.append(conversation)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
    
    func openConversationByUserId(userId:String,noteName:String?) -> Conversation {
        
        if let conversation = (conversations.filter{userId == $0.chatterId ?? ""}).first{
            return conversation
        }else{
            let conversation = addNewConversationWithUserId(userId, noteName: noteName)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
    
    private func addNewConversationWithUserId(userId:String,noteName:String?) -> Conversation {
        let conversation = Conversation()
        conversation.conversationId = IdUtil.generateUniqueId()
        conversation.chatterId = userId
        conversation.noteName = noteName
        conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
        conversation.saveModel()
        conversations.append(conversation)
        return conversation
    }
    
    func updateConversationChatterIdWithMobile(chatterId:String,mobile:String){
        self.conversations.forEach { (con) -> () in
            if String.isNullOrWhiteSpace(con.chatterId) && con.chatterMobile == mobile{
                con.chatterId = chatterId
                con.saveModel()
                self.postNotificationNameWithMainAsync(ConversationService.conversationUpdated, object: self, userInfo: [ConversationUpdatedValue:con])
            }
        }
        PersistentManager.sharedInstance.saveAll()
    }
    
    func removeConversation(conversationId:String) -> Bool{
        if let c = (self.conversations.removeElement{$0.conversationId == conversationId}).first{
            PersistentManager.sharedInstance.removeModel(c)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return true
        }else{
            return false
        }
    }
    
    func searchConversation(keyword:String)->[Conversation]{
        let result = conversations.filter{ c in
            if let noteName = c.noteName{
                if noteName.containsString(keyword){
                    return true
                }
            }
            if let mobile = c.chatterMobile{
                if mobile.hasBegin(keyword){
                    return true
                }
            }
            return false
        }
        return result
    }
    
    func noteConversation(conversationId:String,noteName:String) -> Bool{
        if let conversation = (self.conversations.filter{$0.conversationId == conversationId}).first{
            conversation.noteName = noteName
            conversation.saveModel()
            self.postNotificationNameWithMainAsync(ConversationService.conversationUpdated, object: self, userInfo: [ConversationUpdatedValue:conversation])
            return true
        }
        return false
    }
}