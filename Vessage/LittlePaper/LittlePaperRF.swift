//
//  LittlePaperRF.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class LittlePaperMessage: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "paperId"
    }
    
    var paperId:String!
    var sender:String!
    var receiver:String!
    var receiverInfo:String!
    var message:String!
    var postmen:String!
    var updatedTime:String!
    var isOpened = false
    
    var isUpdated = false
    
    func isMySended(myUserId:String!) -> Bool{
        return myUserId == sender
    }
    
    func isMyReceived(myUserId:String) -> Bool {
        return !isMySended(myUserId)
    }
    
    func isReceivedNotDeal(myUserId:String) -> Bool {
        return isMyReceived(myUserId) && !isMyOpened(myUserId) && !isMyPosted(myUserId)
    }
    
    func isMyPosted(myUserId:String!) -> Bool{
        return postmen != nil && postmen.containsString(myUserId)
    }
    
    func isMyOpened(myUserId:String!) -> Bool{
        return receiver != nil && myUserId == receiver
    }
}

class NewPaperMessageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages"
        self.method = .POST
    }
    
    func setReceiverInfo(receiverInfo:String){
        self.paramenters["receiverInfo"] = receiverInfo
    }
    
    func setMessage(message:String){
        self.paramenters["message"] = message
    }
    
    func setNextReceiver(receiver:String){
        self.paramenters["nextReceiver"] = receiver
    }
}

class PostPaperMessageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/PostMessage"
        self.method = .PUT
    }
    
    func setPaperId(paperId:String){
        self.paramenters["paperId"] = paperId
    }
    
    func setNextReceiver(receiver:String){
        self.paramenters["nextReceiver"] = receiver
    }
}

class GetReceivedPaperMessagesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages"
        self.method = .GET
    }
}

class GetPaperMessagesStatusRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages"
        self.method = .GET
    }
    
    func setPaperId(paperIds:String){
        self.paramenters["paperIds"] = paperIds
    }
}

class OpenPaperMessageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/OpenPaperId"
        self.method = .PUT
    }
    
    func setPaperId(paperId:String){
        self.api = "/LittlePaperMessages/OpenPaperId/\(paperId)"
    }
    
}