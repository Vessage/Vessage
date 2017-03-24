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
            let minLeft = NSNumber(double: getConversationTimeUpMinutesLeft()).integerValue
            
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
    
    func getLastUpdatedTime() -> NSDate {
        if lstTs <= 0 {
            lstTs = DateHelper.UnixTimeSpanTotalMilliseconds
            saveModel()
        }
        return NSDate(timeIntervalSince1970: Double(lstTs) / 1000)
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
        return ServiceContainer.getService(ConversationService)
    }
}

//MARK:ConversationService
class ConversationService:NSNotificationCenter, ServiceProtocol {
    static let conversationMaxPinNumber = 20
    static let conversationListUpdated = "conversationListUpdated"
    static let conversationUpdated = "conversationUpdated"
    
    @objc static var ServiceName:String {return "Conversation Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        dispatch_async(dispatch_get_main_queue()) { 
            self.setServiceReady()
            self.refreshConversations()
        }
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
        cu.userId = c.chatterId
        return VessageUser.isTheSameUser(cu, userb: user)
    }
    
    static func isConversationWithChatGroup(c:Conversation,group:ChatGroup) -> Bool{
        return c.isGroupChat && c.chatterId == group.groupId
    }
    
    static func isConversationVessage(c:Conversation,vsg:Vessage) -> Bool{
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
    
    private func updateConversationWithVessage(vsg:Vessage) -> Int?{
        if let index = (conversations.indexOf { ConversationService.isConversationVessage($0, vsg: vsg)}){
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
    
    func expireConversation(chatterId:String){
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
    
    private func setConversationNewestModifiedAt(index:Int?){
        if let i = index{
            let c = conversations.removeAtIndex(i)
            c.lstTs = DateHelper.UnixTimeSpanTotalMilliseconds
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
            return self.addNewConversationWithGroupVessage(vsg,beforeRemoveTs: ConversationMaxTimeUpMS,createByActivityId: nil)
        }else{
            return self.addNewConversationWithUserId(vsg.sender,beforeRemoveTs: ConversationMaxTimeUpMS,createByActivityId: nil,type: Conversation.typeSingleChat)
        }
    }
    
    private func refreshConversations(){
        conversations.removeAll()
        timeupedConversations.removeAll()
        var cons = PersistentManager.sharedInstance.getAllModel(Conversation)
        let timeUpCons = cons.removeElement { c -> Bool in
            return c.getConversationTimeUpMinutesLeft() < 3
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
            return c.getConversationTimeUpMinutesLeft() < 3
        }
        timeupedConversations.appendContentsOf(timeUpCons)
        PersistentManager.sharedInstance.removeModels(timeUpCons)
        self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
    }
    
    func getConversationWithChatterId(chatterId:String) -> Conversation? {
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
    
    private func sortConversationList(){
        conversations.sortInPlace { (a, b) -> Bool in
            a.lstTs > b.lstTs
        }
    }
 
    
    func existsConversationOfUserId(userId:String) -> Bool {
        return (conversations.filter{userId == $0.chatterId ?? ""}).count > 0
    }
    
    func openConversationByUserId(userId:String,beforeRemoveTs:Int64 = ConversationMaxTimeUpMS,createByActivityId:String? = nil,type:Int = Conversation.typeSingleChat) -> Conversation {
        
        if let conversation = (conversations.filter{userId == $0.chatterId ?? ""}).first{
            return conversation
        }else{
            let conversation = addNewConversationWithUserId(userId,beforeRemoveTs: beforeRemoveTs,createByActivityId: createByActivityId,type: type)
            self.postNotificationNameWithMainAsync(ConversationService.conversationListUpdated, object: self,userInfo: nil)
            return conversation
        }
    }
    
    func openConversationByGroup(group:ChatGroup,beforeRemoveTs:Int64 = ConversationMaxTimeUpMS,createByActivityId:String? = nil) -> Conversation {
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
    
    private func addNewConversationWithGroupVessage(vsg:Vessage,beforeRemoveTs:Int64,createByActivityId:String?) -> Conversation{
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
    
    private func addNewConversationWithUserId(userId:String,beforeRemoveTs:Int64,createByActivityId:String?,type:Int) -> Conversation {
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
