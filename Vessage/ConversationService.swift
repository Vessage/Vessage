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
    static let typeSelfChat = -1
    static let typeSingleChat = 1
    static let typeGroupChat = 2
    static let typeMultiChat = 3
    static let typeSubscription = 4
    
    override func getObjectUniqueIdName() -> String {
        return "conversationId"
    }
    var conversationId:String!
    var chatterId:String!
    var type = 0
    var lstTs:Int64 = 0
    var pinned = false
    
    var acId:String?
    
    //MARK: Deprecated
    var isGroup = false //use type instead
}

extension Conversation{
    var isGroupChat:Bool{
        if type == 0 {
            type = isGroup ? Conversation.typeGroupChat : Conversation.typeSingleChat
            saveModel()
        }
        return type == Conversation.typeGroupChat
    }
}

extension Conversation{
    
    func getDisappearString() -> String {
        
        if pinned {
            if type == Conversation.typeSubscription {
                return "SUBSCRIPTION_PINNED".localizedString()
            }else{
                return getLastUpdatedTime().toFriendlyString()
            }
        }else{
            let minLeft = NSNumber(value: getConversationTimeUpMinutesLeft() as Double).intValue
            
            if minLeft < Int(ConversationMaxTimeUpMinutes / 2) || minLeft % 3 != 0 {
                if minLeft > 24 * 60 {
                    let daysLeft = Int(minLeft / 24 / 60)
                    let format = Conversation.typeSubscription == type ? "SUBSCRIPTION_X_DAYS_DISAPPEAR".localizedString(): "X_DAYS_DISAPPEAR".localizedString()
                    return String(format:format , daysLeft)
                }else if minLeft > 60 {
                    let format = Conversation.typeSubscription == type ? "SUBSCRIPTION_X_HOURS_DISAPPEAR".localizedString(): "X_DAYS_DISAPPEAR".localizedString()
                    let hoursLeft = Int(minLeft / 60)
                    return String(format: format, hoursLeft)
                }else{
                    return VessageUser.typeSubscription == type ? "SUBSCRIPTION_WILL_DISAPPEAR".localizedString() : "DISAPPEAR_IN_ONE_HOUR".localizedString()
                }
            }else{
                return getLastUpdatedTime().toFriendlyString()
            }
        }
        
    }
    
    func getLastUpdatedTime() -> Date {
        if lstTs <= 0 {
            lstTs = DateHelper.UnixTimeSpanTotalMilliseconds
            saveModel()
        }
        return Date(timeIntervalSince1970: Double(lstTs) / 1000)
    }
    
    func getConversationTimeUpMinutesLeft() -> Double{
        return ConversationMaxTimeUpMinutes + getLastUpdatedTime().totalMinutesSinceNow.doubleValue
    }
    
    func getConversationTimeUpProgressLeft() -> Float? {
        let minLeft = getConversationTimeUpMinutesLeft()
        return Float(minLeft / ConversationMaxTimeUpMinutes)
    }
}

let ConversationMaxTimeUpMinutes = 30.0 * 24 * 60
let ConversationUpdatedValue = "ConversationUpdatedValue"
let ConversationMaxTimeUpMS = Int64(ConversationMaxTimeUpMinutes * 60 * 1000)

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getConversationService() -> ConversationService{
        return ServiceContainer.getService(ConversationService.self)
    }
}

//MARK:ConversationService
class ConversationService:NotificationCenter, ServiceProtocol {
    static let conversationMaxPinNumber = 20
    static let conversationListUpdated = "conversationListUpdated".asNotificationName()
    static let conversationUpdated = "conversationUpdated".asNotificationName()
    
    @objc static var ServiceName:String {return "Conversation Service"}
    
    @objc func appStartInit(_ appName: String) {
        
    }
    
    @objc func userLoginInit(_ userId: String) {
        DispatchQueue.main.async { 
            self.setServiceReady()
            self.refreshConversations()
        }
    }
    
    @objc func userLogout(_ userId: String) {
        conversations.removeAll()
        setServiceNotReady()
    }
    
    fileprivate(set) var conversations = [Conversation]()
    fileprivate(set) var timeupedConversations = [Conversation]()
    
    func indexOfConversationOfUser(_ user:VessageUser) -> Int?{
        let updatedIndex = conversations.index { (c) -> Bool in
            return ConversationService.isConversationWithUser(c, user: user)
        }
        return updatedIndex
    }
    
    static func isConversationWithUser(_ c:Conversation,user:VessageUser) -> Bool{
        let cu = VessageUser()
        cu.userId = c.chatterId
        return VessageUser.isTheSameUser(cu, userb: user)
    }
    
    static func isConversationWithChatGroup(_ c:Conversation,group:ChatGroup) -> Bool{
        return c.isGroupChat && c.chatterId == group.groupId
    }
    
    static func isConversationVessage(_ c:Conversation,vsg:Vessage) -> Bool{
        if let chatterId = c.chatterId{
            if vsg.sender == chatterId{
                if vsg.ts > c.lstTs {
                    c.lstTs = vsg.ts
                }
                return true
            }
        }
        return false
    }
    
    @discardableResult
    fileprivate func updateConversationWithVessage(_ vsg:Vessage) -> Int?{
        if let index = (conversations.index { ConversationService.isConversationVessage($0, vsg: vsg)}){
            let conversation = conversations[index]
            if !conversation.isGroupChat {
                if conversation.chatterId == nil{
                    conversation.chatterId = vsg.sender
                }
                if vsg.ts > conversation.lstTs {
                    conversation.lstTs = vsg.ts
                }
                
                if !String.isNullOrWhiteSpace(conversation.acId) {
                    conversation.acId = nil
                }
                
                conversation.saveModel()
                self.postNotificationNameWithMainAsync(ConversationService.conversationUpdated, object: self, userInfo: [ConversationUpdatedValue:conversation])
            }
            
            return index
        }else{
            return nil
        }
    }
    
    func expireConversation(_ chatterId:String){
        let index = conversations.index { (c) -> Bool in
            if let chatter = c.chatterId{
                if chatter == chatterId{
                    return true
                }
            }
            return false
        }
        setConversationNewestModifiedAt(index)
    }
    
    fileprivate func setConversationNewestModifiedAt(_ index:Int?){
        if let i = index{
            let c = conversations.remove(at: i)
            c.lstTs = DateHelper.UnixTimeSpanTotalMilliseconds
            c.saveModel()
            conversations.insert(c, at: 0)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
        }
    }
    
    @discardableResult
    func updateConversationListWithVessagesReturnNewConversations(_ vsgs:[Vessage]) -> [Conversation] {
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
    
    @discardableResult
    fileprivate func createConverationWithVessage(_ vsg:Vessage) -> Conversation{
        if vsg.isGroup {
            return self.addNewConversationWithGroupVessage(vsg,beforeRemoveTs: ConversationMaxTimeUpMS,createByActivityId: nil)
        }else{
            return self.addNewConversationWithUserId(vsg.sender,beforeRemoveTs: ConversationMaxTimeUpMS,createByActivityId: nil,type: Conversation.typeSingleChat)
        }
    }
    
    fileprivate func refreshConversations(){
        conversations.removeAll()
        timeupedConversations.removeAll()
        var cons = PersistentManager.sharedInstance.getAllModel(Conversation.self)
        let timeUpCons = cons.removeElement { c -> Bool in
            return c.getConversationTimeUpMinutesLeft() < 3
        }
        timeupedConversations.append(contentsOf: timeUpCons)
        PersistentManager.sharedInstance.removeModels(timeUpCons)
        conversations.append(contentsOf: cons)
        sortConversationList()
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
    }
    
    func clearTimeUpConversations() {
        let timeUpCons = conversations.removeElement { c -> Bool in
            if c.pinned{
                return false
            }
            return c.getConversationTimeUpMinutesLeft() < 3
        }
        timeupedConversations.append(contentsOf: timeUpCons)
        PersistentManager.sharedInstance.removeModels(timeUpCons)
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
    }
    
    func getConversationWithChatterId(_ chatterId:String) -> Conversation? {
        return conversations.filter{$0.chatterId == chatterId}.first
    }
    
    func getChattingNormalUserIds() -> [String] {
        return conversations.filter{!$0.isGroupChat && !String.isNullOrWhiteSpace($0.chatterId) && String.isNullOrWhiteSpace($0.acId)}.map{$0.chatterId}
    }
    
    func getChattingUserIds() -> [String] {
        return conversations.filter{!$0.isGroupChat && !String.isNullOrWhiteSpace($0.chatterId)}.map{$0.chatterId!}
    }
    
    func removeTimeupedConversations() {
        timeupedConversations.removeAll()
    }
    
    fileprivate func sortConversationList(){
        conversations.sort { (a, b) -> Bool in
            a.lstTs > b.lstTs
        }
    }
 
    
    func existsConversationOfUserId(_ userId:String) -> Bool {
        return (conversations.filter{userId == $0.chatterId ?? ""}).count > 0
    }
    
    @discardableResult
    func openConversationByUserId(_ userId:String,beforeRemoveTs:Int64 = ConversationMaxTimeUpMS,createByActivityId:String? = nil,type:Int = Conversation.typeSingleChat) -> Conversation {
        
        if let conversation = (conversations.filter{userId == $0.chatterId ?? ""}).first{
            return conversation
        }else{
            let conversation = addNewConversationWithUserId(userId,beforeRemoveTs: beforeRemoveTs,createByActivityId: createByActivityId,type: type)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
    
    func openConversationByGroup(_ group:ChatGroup,beforeRemoveTs:Int64 = ConversationMaxTimeUpMS,createByActivityId:String? = nil) -> Conversation {
        if let conversation = (conversations.filter{group.groupId == $0.chatterId ?? ""}).first{
            return conversation
        }
        let conversation = Conversation()
        conversation.chatterId = group.groupId
        conversation.type = Conversation.typeGroupChat
        conversation.conversationId = IdUtil.generateUniqueId()
        conversation.lstTs = DateHelper.UnixTimeSpanTotalMilliseconds + beforeRemoveTs - ConversationMaxTimeUpMS
        conversation.acId = createByActivityId
        conversation.saveModel()
        conversations.append(conversation)
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
        return conversation
    }
    
    fileprivate func addNewConversationWithGroupVessage(_ vsg:Vessage,beforeRemoveTs:Int64,createByActivityId:String?) -> Conversation{
        let conversation = Conversation()
        conversation.chatterId = vsg.sender
        conversation.type = Conversation.typeGroupChat
        conversation.conversationId = IdUtil.generateUniqueId()
        conversation.lstTs = DateHelper.UnixTimeSpanTotalMilliseconds + beforeRemoveTs - ConversationMaxTimeUpMS
        conversation.acId = createByActivityId
        conversation.saveModel()
        conversations.append(conversation)
        return conversation
    }
    
    fileprivate func addNewConversationWithUserId(_ userId:String,beforeRemoveTs:Int64,createByActivityId:String?,type:Int) -> Conversation {
        let conversation = Conversation()
        conversation.conversationId = IdUtil.generateUniqueId()
        conversation.chatterId = userId
        conversation.type = type
        conversation.lstTs = DateHelper.UnixTimeSpanTotalMilliseconds + beforeRemoveTs - ConversationMaxTimeUpMS
        conversation.acId = createByActivityId
        conversation.saveModel()
        conversations.append(conversation)
        return conversation
    }
    
    @discardableResult
    func removeConversation(_ conversationId:String) -> Bool{
        if let c = (self.conversations.removeElement{$0.conversationId == conversationId}).first{
            PersistentManager.sharedInstance.removeModel(c)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return true
        }else{
            return false
        }
    }
    
    func searchConversation(_ keyword:String)->[Conversation]{
        let result = conversations.filter{ c in
            return false
        }
        return result
    }
}

//MARK:Pin Conversation
extension ConversationService{
    func pinConversation(_ conversation:Conversation) -> Bool {
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
    
    func unpinConversation(_ conversation:Conversation) -> Bool {
        if !conversation.pinned {
            return true
        }
        conversation.lstTs = DateHelper.UnixTimeSpanTotalMilliseconds
        conversation.pinned = false
        if let c = (conversations.filter{$0.conversationId == conversation.conversationId}.first){
            c.pinned = false
            c.lstTs = conversation.lstTs
        }
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
