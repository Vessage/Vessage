//
//  Conversation.swift
//  Vessage
//
//  Created by AlexChow on 16/3/6.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class Conversation: BahamutObject {
    var conversationId:String!
    var chatterNoteName:String!
    var chatterId:String!
    var chatterMobile:String!
    var lastMessageTime:String!
}

class GetConversationListRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
        self.api = "/Conversations/ConversationList"
    }
}

class CreateConversationRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .POST
        self.api = "/Conversations"
    }
    
    var userId:String!{
        didSet{
            self.paramenters["userId"] = userId
        }
    }
    
    var mobile:String!{
        didSet{
            self.paramenters["mobile"] = mobile
        }
    }
}