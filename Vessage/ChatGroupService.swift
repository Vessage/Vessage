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
        return ServiceContainer.getService(ChatGroupService)
    }
}

//Constants
let kChatGroupValue = "kChatGroupValue"

//MARK: ChatGroupService
class ChatGroupService: NSNotificationCenter,ServiceProtocol
{
    @objc static var ServiceName:String{return "ChatGroup Service"}
    static let OnChatGroupUpdated = "OnChatGroupUpdated"
    static let OnQuitChatGroup = "OnQuitChatGroup"
    @objc func appStartInit(appName: String) {
        self.setServiceReady()
    }
    @objc func userLoginInit(userId:String)
    {
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        self.setServiceNotReady()
    }
    
    func fetchChatGroup(groupId:String) {
        let req = GetGroupChatRequest()
        req.groupId = groupId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ChatGroup>) in
            if result.isSuccess{
                if let g = result.returnObject{
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:g])
                }
            }
        }
    }
    
    func createChatGroup(userIds:[String]) {
        let req = CreateGroupChatRequest()
        req.groupUsers = userIds
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ChatGroup>) in
            if result.isSuccess{
                if let g = result.returnObject{
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:g])
                }
            }
        }
    }
    
    func joinChatGroup(groupId:String,inviteCode:String) {
        let req = JoinGroupChatRequest()
        req.groupId = groupId
        req.inviteCode = inviteCode
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<ChatGroup>) in
            if result.isSuccess{
                if let g = result.returnObject{
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnChatGroupUpdated, object: self, userInfo: [kChatGroupValue:g])
                }
            }
        }
    }
    
    func quitChatGroup(groupId:String) {
        let req = QuitGroupChatRequest()
        req.groupId = groupId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                if let group = PersistentManager.sharedInstance.getModel(ChatGroup.self, idValue: groupId){
                    self.postNotificationNameWithMainAsync(ChatGroupService.OnQuitChatGroup, object: self, userInfo: [kChatGroupValue:group])
                }
            }
        }
    }
    
    //Unavailable
    private func kickUserFromChatGroup(groupId:String,userId:String) {
        let req = KickUserOutRequest()
        req.groupId = groupId
        req.userId = userId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            if result.isSuccess{
                
            }
        }
    }
    
    func editChatGroupName(groupId:String,inviteCode:String,newName:String) {
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
        }
    }
}