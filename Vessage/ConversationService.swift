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
    var isGroup = false
    var chatterId:String!
    var chatterMobile:String!
    var lastMessageTime:String!
    
    var pinned = false
    
}

extension Conversation{
    
    func getConversationTimeUpMinutesLeft() -> Double?{
        if let date = lastMessageTime?.dateTimeOfAccurateString {
            return ConversationMaxTimeUpMinutes - date.totalMinutesSinceNow.doubleValue * -1
        }
        return nil
    }
    
    func getConversationTimeUpProgressLeft() -> Float? {
        if let minLeft = getConversationTimeUpMinutesLeft() {
            return Float(minLeft / ConversationMaxTimeUpMinutes)
        }
        return nil
    }
}

let ConversationMaxTimeUpMinutes = 14.0 * 24 * 60
let ConversationUpdatedValue = "ConversationUpdatedValue"

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getConversationService() -> ConversationService{
        return ServiceContainer.getService(ConversationService)
    }
}

//MARK:ConversationService
class ConversationService:NSNotificationCenter, ServiceProtocol {
    static let conversationMaxPinNumber = 6
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
        conversations.removeAll()
        setServiceNotReady()
    }
    
    private(set) var conversations = [Conversation]()
    private(set) var timeupedConversations = [Conversation]()
    
    func indexOfConversationOfUser(user:VessageUser) -> Int?{
        let updatedIndex = conversations.indexOf { (c) -> Bool in
            return ConversationService.isConversationWithUser(c, user: user)
        }
        return updatedIndex
    }
    
    static func isConversationWithUser(c:Conversation,user:VessageUser) -> Bool{
        let cu = VessageUser()
        cu.mobile = c.chatterMobile
        cu.userId = c.chatterId
        return VessageUser.isTheSameUser(cu, userb: user)
    }
    
    static func isConversationWithChatGroup(c:Conversation,group:ChatGroup) -> Bool{
        return c.isGroup && c.chatterId == group.groupId
    }
    
    static func isConversationVessage(c:Conversation,vsg:Vessage) -> Bool{
        if let chatterId = c.chatterId{
            if vsg.sender == chatterId{
                c.lastMessageTime = vsg.sendTime
                return true
            }
        }
        if !c.isGroup {
            if let ei = vsg.getExtraInfoObject(){
                if ei.mobileHash != nil && ei.mobileHash == c.chatterMobile?.md5{
                    if String.isNullOrWhiteSpace(c.chatterId){
                        c.chatterId = vsg.sender
                        c.saveModel()
                    }
                    return true
                }
            }
        }
        return false
    }
    
    private func updateConversationWithVessage(vsg:Vessage) -> Int?{
        if let index = (conversations.indexOf { ConversationService.isConversationVessage($0, vsg: vsg)}){
            let conversation = conversations[index]
            if !conversation.isGroup {
                if conversation.chatterId == nil{
                    conversation.chatterId = vsg.sender
                }
                if let date = vsg.getSendTime() {
                    if conversation.lastMessageTime.dateTimeOfAccurateString.isBefore(date){
                        conversation.lastMessageTime = vsg.sendTime
                    }
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
        vsgs.forEach { (element) in
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
        if vsg.isGroup {
            return self.addNewConversationWithGroupVessage(vsg)
        }else{
            return self.addNewConversationWithUserId(vsg.sender)
        }
    }
    
    private func addNewConversationWithGroupVessage(vsg:Vessage) -> Conversation{
        let conversation = Conversation()
        conversation.chatterId = vsg.sender
        conversation.isGroup = true
        conversation.conversationId = IdUtil.generateUniqueId()
        conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
        conversation.saveModel()
        conversations.append(conversation)
        return conversation
    }
    
    private func refreshConversations(){
        conversations.removeAll()
        timeupedConversations.removeAll()
        var cons = PersistentManager.sharedInstance.getAllModel(Conversation)
        let timeUpCons = cons.removeElement { c -> Bool in
            if let p = c.getConversationTimeUpMinutesLeft(){
                return p < 3
            }
            return true
        }
        timeupedConversations.appendContentsOf(timeUpCons)
        PersistentManager.sharedInstance.removeModels(timeUpCons)
        conversations.appendContentsOf(cons)
        sortConversationList()
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
    }
    
    func clearTimeUpConversations() {
        let timeUpCons = conversations.removeElement { c -> Bool in
            if c.pinned{
                return false
            }
            if let p = c.getConversationTimeUpMinutesLeft(){
                return p < 3
            }
            return true
        }
        timeupedConversations.appendContentsOf(timeUpCons)
        PersistentManager.sharedInstance.removeModels(timeUpCons)
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
    }
    
    func removeTimeupedConversations() {
        timeupedConversations.removeAll()
    }
    
    private func sortConversationList(){
        conversations.sortInPlace { (a, b) -> Bool in
            a.lastMessageTime.dateTimeOfAccurateString.isAfter(b.lastMessageTime.dateTimeOfAccurateString)
        }
    }
    
    func openConversationByGroup(group:ChatGroup) -> Conversation {
        if let conversation = (conversations.filter{group.groupId == $0.chatterId ?? ""}).first{
            return conversation
        }
        let conversation = Conversation()
        conversation.chatterId = group.groupId
        conversation.isGroup = true
        conversation.conversationId = IdUtil.generateUniqueId()
        conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
        conversation.saveModel()
        conversations.append(conversation)
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
        return conversation
    }
    
    func openConversationByUserId(userId:String) -> Conversation {
        
        if let conversation = (conversations.filter{userId == $0.chatterId ?? ""}).first{
            return conversation
        }else{
            let conversation = addNewConversationWithUserId(userId)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
    
    private func addNewConversationWithUserId(userId:String) -> Conversation {
        let conversation = Conversation()
        conversation.conversationId = IdUtil.generateUniqueId()
        conversation.chatterId = userId
        conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
        conversation.saveModel()
        conversations.append(conversation)
        return conversation
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
            
            if let mobile = c.chatterMobile{
                if mobile.hasBegin(keyword){
                    return true
                }
            }
            return false
        }
        return result
    }
}

//MARK:Pin Conversation
extension ConversationService{
    func pinConversation(conversation:Conversation) -> Bool {
        if conversation.pinned  {
            return true
        }
        let pinnedCount = conversations.filter{$0.pinned}.count
        if pinnedCount >= ConversationService.conversationMaxPinNumber {
            return false
        }
        conversation.pinned = true
        conversation.saveModel()
        conversations.filter{$0.conversationId == conversation.conversationId}.first?.pinned = true
        return true
    }
    
    func unpinConversation(conversation:Conversation) -> Bool {
        if !conversation.pinned {
            return true
        }
        conversation.pinned = false
        conversations.filter{$0.conversationId == conversation.conversationId}.first?.pinned = false
        return true
    }
}

/*
extension ConversationService{
    
    @available(*,deprecated)
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
    
    @available(*,deprecated)
    func openConversationByMobile(mobile:String) -> Conversation {
        
        if let conversation = (conversations.filter{!String.isNullOrWhiteSpace($0.chatterMobile) && $0.chatterMobile == mobile}).first{
            return conversation
        }else{
            let conversation = Conversation()
            conversation.conversationId = IdUtil.generateUniqueId()
            conversation.chatterMobile = mobile
            conversation.lastMessageTime = NSDate().toAccurateDateTimeString()
            conversation.saveModel()
            conversations.append(conversation)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
}
 */