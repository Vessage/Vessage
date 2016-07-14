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
    var extraInfo:String!
    var isGroup = false
    
    
    func getSendTime()->NSDate!{
        return sendTime.dateTimeOfAccurateString
    }
}

class VessageExtraInfoModel:BahamutObject{
    var accountId:String!
    var nickName:String!
    var mobileHash:String!
}

class SendVessageResultModel:BahamutObject{
    override func getObjectUniqueIdName() -> String {
        return "vessageId"
    }
    var vessageId:String!
    var vessageBoxId:String!
}

extension Vessage{
    func getExtraInfoObject() -> VessageExtraInfoModel?{
        if String.isNullOrWhiteSpace(self.extraInfo) == false{
            return VessageExtraInfoModel(json: self.extraInfo)
        }
        return nil
    }
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

class SendNewVessageRequestBase:BahamutRFRequestBase{
    
    override init() {
        super.init()
        self.method = .POST
    }
    
    var extraInfo:String!{
        didSet{
            self.paramenters["extraInfo"] = extraInfo
        }
    }
}

class SendNewVessageToMobileRequest: SendNewVessageRequestBase {
    override init() {
        super.init()
        self.api = "/Vessages/ForMobile"
    }
    
    var receiverMobile:String!{
        didSet{
            if String.isNullOrWhiteSpace(receiverMobile) == false{
                self.paramenters["receiverMobile"] = receiverMobile
            }
        }
    }

}

class SendNewVessageToUserRequest: SendNewVessageRequestBase {
    override init() {
        super.init()
        self.api = "/Vessages/ForUser"
    }
    
    var receiverId:String!{
        didSet{
            if String.isNullOrWhiteSpace(receiverId) == false{
                self.paramenters["receiverId"] = receiverId
            }
        }
    }
    
    var isGroup = false{
        didSet{
            self.paramenters["isGroup"] = "\(isGroup)"
        }
    }
    

}

class CancelSendVessageRequest:BahamutRFRequestBase{
    
    override init() {
        super.init()
        self.method = .PUT
        self.api = "/Vessages/CancelSendVessage"
    }
    
    var vessageId:String!{
        didSet{
            self.paramenters["vessageId"] = vessageId
        }
    }
    
    var vessageBoxId:String!{
        didSet{
            self.paramenters["vessageBoxId"] = vessageBoxId
        }
    }
}

class FinishSendVessageRequest:CancelSendVessageRequest{
    
    override init() {
        super.init()
        self.method = .PUT
        self.api = "/Vessages/FinishSendVessage"
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