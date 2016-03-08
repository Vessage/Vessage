//
//  ConversationService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK:ConversationService
class ConversationService: ServiceProtocol {
    @objc static var ServiceName:String {return "Conversation Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        self.setServiceReady()
        
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            conversations.append(testConversation)
        }
    }
    
    @objc func userLogout(userId: String) {
        
    }
    
    private(set) var conversations = [Conversation]()
    
    func openConversationBy(accountId:String,callback:(updatedConversation:Conversation)->Void) -> Conversation {
        //TODO: delete test
        let conversation = Conversation()
        let testMark = "tn" + ""
        if testMark == "tn"{
            return testConversation
        }
        
        return conversation
    }
    
    func openConversationByMobile(mobile:String,callback:(updatedConversation:Conversation)->Void) -> Conversation {
        //TODO: delete test
        let conversation = Conversation()
        let testMark = "tn" + ""
        if testMark == "tn"{
            return testConversation
        }
        return conversation
    }
    
    func openConversationByUserId(mobile:String,callback:(updatedConversation:Conversation)->Void) -> Conversation {
        //TODO: delete test
        let conversation = Conversation()
        let testMark = "tn" + ""
        if testMark == "tn"{
            return testConversation
        }
        return conversation
    }
    
    //MARK:TODO: delete test
    var testConversation:Conversation{
        let conversation = Conversation()
        conversation.chatterId = "asdfasd"
        conversation.chatterMobile = "15800038672"
        conversation.chatterNoteName = "xxx"
        conversation.conversationId = "asdfasdddd"
        return conversation
    }
    
    func removeConversation(conversation:Conversation,callback:(suc:Bool)->Void){
        
    }
    
    func searchConversation(keyword:String)->[Conversation]{
        var result = [Conversation]()
        return result
    }
    
    func noteConversation(conversation:Conversation,noteName:String,callback:(suc:Bool)->Void){
        
    }
}