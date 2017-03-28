//
//  GroupChatRF.swift
//  Vessage
//
//  Created by AlexChow on 16/7/12.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class ChatGroup: BahamutObject {
    
    override func getObjectUniqueIdName() -> String {
        return "groupId"
    }
    
    var groupId:String!
    var hosters:[String]!
    var chatters:[String]!
    var inviteCode:String!
    var groupName:String!
}

class GetGroupChatRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/GroupChats"
        self.method = .get
    }
    
    override func getMaxRequestCount() -> Int32 {
        return 10
    }
    
    var groupId:String!{
        didSet{
            self.paramenters["groupId"] = groupId
        }
    }
}

class CreateGroupChatRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/GroupChats/CreateGroupChat"
        self.method = .post
    }
    
    var groupName:String!{
        didSet{
            self.paramenters["groupName"] = groupName
        }
    }
    
    var groupUsers:[String]!{
        didSet{
            self.paramenters["groupUsers"] = groupUsers.joined(separator: ",")
        }
    }
    
}

class AddUserJoinGroupChatRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/GroupChats/AddUserJoinGroupChat"
        self.method = .post
    }
    
    var groupId:String!{
        didSet{
            self.paramenters["groupId"] = groupId
        }
    }
    
    var userId:String!{
        didSet{
            self.paramenters["userId"] = userId
        }
    }
    
}

class JoinGroupChatRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/GroupChats/JoinGroupChat"
        self.method = .post
    }
    
    var groupId:String!{
        didSet{
            self.paramenters["groupId"] = groupId
        }
    }
    
    var inviteCode:String!{
        didSet{
            self.paramenters["inviteCode"] = inviteCode
        }
    }
    
}

class QuitGroupChatRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/GroupChats/QuitGroupChat"
        self.method = .delete
    }
    
    var groupId:String!{
        didSet{
            self.paramenters["groupId"] = groupId
        }
    }
    
}

class KickUserOutRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/GroupChats/KickUserOut"
        self.method = .delete
    }
    
    var groupId:String!{
        didSet{
            self.paramenters["groupId"] = groupId
        }
    }
    var userId:String!{
        didSet{
            self.paramenters["userId"] = userId
        }
    }
}


class EditGroupNameRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/GroupChats/EditGroupName"
        self.method = .put
    }
    
    var groupId:String!{
        didSet{
            self.paramenters["groupId"] = groupId
        }
    }
    
    var inviteCode:String!{
        didSet{
            self.paramenters["inviteCode"] = inviteCode
        }
    }
    
    var newGroupName:String!{
        didSet{
            self.paramenters["newGroupName"] = newGroupName
        }
    }
}
