//
//  VessageRF.swift
//  Vessage
//
//  Created by AlexChow on 16/3/6.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class Vessage: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "vessageId"
    }
    var vessageId:String!
    var fileId:String!
    var sender:String!
    var isRead = false
    var sendTime:String!
}

class GetNewVessagesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
        self.api = "/Vessages/New"
    }
}

class NotifyGotNewVessagesRequest:BahamutRFRequestBase{
    override init() {
        super.init()
        self.method = .PUT
        self.api = "/Vessages/Got"
    }
}

class SendNewVessageForMobileRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .POST
        self.api = "/Vessages/ForMobile"
    }
    
    var receiverMobile:String!{
        didSet{
            if String.isNullOrWhiteSpace(receiverMobile) == false{
                self.paramenters["receiverMobile"] = receiverMobile
            }
        }
    }
    
    var fileId:String!{
        didSet{
            self.paramenters["fileId"] = fileId
        }
    }
}

class SendNewVessageForUserRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .POST
        self.api = "/Vessages/ForUser"
    }
    
    var receiverId:String!{
        didSet{
            if String.isNullOrWhiteSpace(receiverId) == false{
                self.paramenters["receiverId"] = receiverId
            }
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
        self.api = "/Vessages/Read"
    }
    
    var vessageId:String!{
        didSet{
            self.api = "/Vessages/Read/\(vessageId)"
        }
    }
}