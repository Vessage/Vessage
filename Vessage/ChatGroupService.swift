//
//  ChatGroupService.swift
//  Vessage
//
//  Created by AlexChow on 16/7/12.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getChatGroupService() -> ChatGroupService{
        return ServiceContainer.getService(ChatGroupService.self)
    }
}

//Constants
let kChatGroupValue = "kChatGroupValue"

//MARK: ChatGroupService
class ChatGroupService: NotificationCenter,ServiceProtocol
{
    @objc static var ServiceName:String{return "ChatGroup Service"}
    static let OnChatGroupUpdated = "OnChatGroupUpdated".asNotificationName()
    static let OnQuitChatGroup = "OnQuitChatGroup".asNotificationName()
    @objc func appStartInit(_ appName: String) {
    }
    @objc func userLoginInit(_ userId:String)
    {
        self.setServiceReady()
    }
    
    @objc func userLogout(_ userId: String) {
        self.setServiceNotReady()
    }
    
    func getChatGroup(_ groupId:String) -> ChatGroup? {
        return PersistentManager.sharedInstance.getModel(ChatGroup.self, idValue: groupId)
    }
    
    func fetchChatGroup(_ groupId:String,callback:((ChatGroup?)->Void)? = nil) {
        let req = GetGroupChatRequest()
        req.groupId = groupId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ChatGroup>) in
            if result.isSuccess{
                var group:ChatGroup? = nil
                if let g = result.returnObject{
                    g.saveModel()
                    PersistentManager.sharedInstance.saveAll()
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:g])
                    group = g
                }
                if let handler = callback{
                    handler(group)
                }
            }
        }
    }
    
    func createChatGroup(_ groupName:String,userIds:[String],callback:@escaping ((ChatGroup?)->Void)) {
        let req = CreateGroupChatRequest()
        req.groupName = groupName
        req.groupUsers = userIds
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ChatGroup>) in
            if result.isSuccess{
                if let g = result.returnObject{
                    g.saveModel()
                    PersistentManager.sharedInstance.saveAll()
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:g])
                    callback(g)
                    return
                }
            }
            callback(nil)
        }
    }
    
    func addUserJoinChatGroup(_ groupId:String,userId:String,callback:@escaping (Bool)->Void) {
        let req = AddUserJoinGroupChatRequest()
        req.groupId = groupId
        req.userId = userId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ChatGroup>) in
            if result.isSuccess{
                if let g = self.getChatGroup(groupId){
                    if !g.chatters.contains(userId){
                        g.chatters.append(userId)
                        g.saveModel()
                        self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:g])
                    }
                }
            }
            callback(result.isSuccess)
        }
    }
    
    func joinChatGroup(_ groupId:String,inviteCode:String) {
        let req = JoinGroupChatRequest()
        req.groupId = groupId
        req.inviteCode = inviteCode
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ChatGroup>) in
            if result.isSuccess{
                if let g = result.returnObject{
                    g.saveModel()
                    PersistentManager.sharedInstance.saveAll()
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:g])
                }
            }
        }
    }
    
    func quitChatGroup(_ groupId:String,callback:@escaping (Bool)->Void) {
        let req = QuitGroupChatRequest()
        req.groupId = groupId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                if let group = PersistentManager.sharedInstance.getModel(ChatGroup.self, idValue: groupId){
                    group.chatters.removeAll()
                    group.saveModel()
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnQuitChatGroup, object: self, userInfo: [kChatGroupValue:group])
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:group])
                }
            }
            callback(result.isSuccess)
        }
    }
    
    func editChatGroupName(_ groupId:String,inviteCode:String,newName:String,callback:@escaping (Bool)->Void) {
        let req = EditGroupNameRequest()
        req.groupId = groupId
        req.inviteCode = inviteCode
        req.newGroupName = newName
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                if let group = PersistentManager.sharedInstance.getModel(ChatGroup.self, idValue: groupId){
                    group.groupName = newName
                    group.saveModel()
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:group])
                }
            }
            callback(result.isSuccess)
        }
    }
    
    
    //Unavailable
    fileprivate func kickUserFromChatGroup(_ groupId:String,userId:String) {
        let req = KickUserOutRequest()
        req.groupId = groupId
        req.userId = userId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                if let group = PersistentManager.sharedInstance.getModel(ChatGroup.self, idValue: groupId){
                    group.chatters.removeElement{$0 == userId}
                    group.saveModel()
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:group])
                }
            }
        }
    }
}
