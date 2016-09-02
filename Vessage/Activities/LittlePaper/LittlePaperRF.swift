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
    var postmen:[String]!
    var updatedTime:String!
    var isOpened = false
    var openNeedAccept = false
    
    var isUpdated = false
    
    func isMySended(myUserId:String!) -> Bool{
        return !String.isNullOrWhiteSpace(sender) && myUserId == sender
    }
    
    func isMyReceived(myUserId:String) -> Bool {
        return !isMySended(myUserId)
    }
    
    func isReceivedNotDeal(myUserId:String) -> Bool {
        return isMyReceived(myUserId) && !isMyOpened(myUserId) && !isMyPosted(myUserId)
    }
    
    func isMyPosted(myUserId:String) -> Bool{
        if let pms = postmen{
            return pms.contains(myUserId)
        }
        return false
    }
    
    func isMyOpened(myUserId:String!) -> Bool{
        return !String.isNullOrWhiteSpace(receiver) && myUserId == receiver
    }
}

class LittlePaperReadResponse: BahamutObject {
    static let TYPE_ASK_SENDER = 1
    static let TYPE_RETURN_ASKER = 2
    static let CODE_ACCEPT_READ = 1
    static let CODE_REJECT_READ = 2
    
    override func getObjectUniqueIdName() -> String {
        return "paperId"
    }
    
    var paperId:String!
    var asker:String!
    var askerNick:String!
    var paperReceiver:String!
    
    var type:Int = 0
    var code:Int = 0
    
    //Local Properties
    var isRead = false
    
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
    
    func setOpenNeedAccept(openNeedAccept:Bool){
        self.paramenters["openNeedAccept"] = "\(openNeedAccept)"
    }
}

class PostPaperMessageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/PostMessage"
        self.method = .PUT
    }
    
    func setIsAnonymous(isAnonymous:Bool) {
        self.paramenters["isAnonymousPost"] = "\(isAnonymous)"
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
        self.api = "/LittlePaperMessages/Received"
        self.method = .GET
    }
}

class GetPaperMessagesStatusRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages"
        self.method = .GET
    }
    
    func setPaperId(paperIds:[String]){
        self.paramenters["paperIds"] = paperIds.joinWithSeparator(",")
    }
}

class OpenAcceptlessPaperRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/OpenPaperId"
        self.method = .PUT
    }
    
    func setPaperId(paperId:String){
        self.paramenters["paperId"] = paperId
    }
}

class AcceptReadPaperRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/AcceptReadPaper"
        self.method = .POST
    }
    
    func setReader(reader:String) {
        self.paramenters["reader"] = reader
    }
    
    func setPaperId(paperId:String){
        self.paramenters["paperId"] = paperId
    }
    
}

class RejectReadPaperRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/RejectReadPaper"
        self.method = .POST
    }
    
    func setReader(reader:String) {
        self.paramenters["reader"] = reader
    }
    
    func setPaperId(paperId:String){
        self.paramenters["paperId"] = paperId
    }
    
}

class ClearGotResponsesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/ClearGotResponses"
        self.method = .DELETE
    }
}

class GetReadPaperResponsesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/ReadPaperResponses"
        self.method = .GET
    }
}

class AskSenderReadPaperRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/LittlePaperMessages/AskReadPaper"
        self.method = .POST
    }
    
    func setPaperId(paperId:String){
        self.paramenters["paperId"] = paperId
    }
}