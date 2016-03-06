//
//  VessageRF.swift
//  Vessage
//
//  Created by AlexChow on 16/3/6.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class Vessage: BahamutObject {
    var vessageId:String!
    var fileId:String!
    var sender:String!
    var conversationId:String!
    var isRead = false
    var sendTime:String!
}

class GetNewVessagesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
        self.api = "/Vessage/New"
    }
}

class NotifyGotNewVessagesRequest:BahamutRFRequestBase{
    override init() {
        super.init()
        self.method = .PUT
        self.api = "/Vessage/Got"
    }
}

class GetConversationVessagesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
        self.api = "/Vessage/Conversation"
    }
    
    var conversationId:String!{
        didSet{
            self.api = "/Vessage/Conversation/\(conversationId)"
        }
    }
}

class SendNewVessageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .POST
        self.api = "/Vessage"
    }
    
    var conversationId:String!{
        didSet{
            self.paramenters["conversationId"] = conversationId
        }
    }
    
    var fileId:String!{
        didSet{
            self.paramenters["fileId"] = fileId
        }
    }
}

class SetVessageRead:BahamutRFRequestBase{
    override init() {
        super.init()
        self.method = .PUT
        self.api = "/Vessage/Read"
    }
    
    var vessageId:String!{
        didSet{
            self.api = "/Vessage/Read/\(vessageId)"
        }
    }
}