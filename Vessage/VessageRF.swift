//
//  VessageRF.swift
//  Vessage
//
//  Created by AlexChow on 16/3/6.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class Vessage: BahamutObject {
    static let sendingVessageId = "sendingVessageId"
    static let vgRandomVessageId = "vgRandomVessageId"
    
    static let typeNoVessage = -2
    static let typeUnknow = -1
    static let typeChatVideo = 0
    static let typeFaceText = 1
    static let typeImage = 2
    static let typeLittleVideo = 3
    
    override func getObjectUniqueIdName() -> String {
        return "vessageId"
    }
    var vessageId:String!
    var fileId:String!
    var sender:String! //groupid if is group vessage
    var isRead = false
    var ts:Int64 = 0
    var extraInfo:String!
    var isGroup = false
    var typeId = 0
    var body:String!
    
    var gSender:String! //vessage sender of group if is group vessage
    
    //MARK: local properties
    var isReady:Bool!
    
    func getVessageRealSenderId() -> String? {
        if isMySendingVessage() {
            return UserSetting.userId
        }else if isGroup{
            return gSender
        }else{
            return sender
        }
    }
    
    func isReceivedVessage() -> Bool {
        return !isVGRandomVessage() && !isMySendingVessage()
    }
    
    func isVGRandomVessage() -> Bool {
        return self.vessageId == Vessage.vgRandomVessageId
    }
    
    func isMySendingVessage() -> Bool {
        return self.vessageId == Vessage.sendingVessageId
    }
    
    func getSendTime()->NSDate!{
        if ts > 0 {
            return NSDate(timeIntervalSince1970: Double(ts) / 1000)
        }else{
            return nil
        }
    }
    
    func getBodyDict() -> [String:AnyObject] {
        if let data = self.body?.toUTF8EncodingData(){
            do{
                if let dict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String : AnyObject]{
                    return dict
                }
            }catch{
                
            }
        }
        return [String:AnyObject]()
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
    
    var fileId:String!{
        didSet{
            if !String.isNullOrEmpty(fileId) {
                self.paramenters["fileId"] = fileId
            }
        }
    }
    
    var typeId:Int = 0{
        didSet{
            self.paramenters["typeId"] = "\(typeId)"
        }
    }
    
    var body:String!{
        didSet{
            if !String.isNullOrEmpty(body) {
                self.paramenters["body"] = body
            }
        }
    }
    
    var ready:Bool = false{
        didSet{
            self.paramenters["ready"] = "\(ready)"
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
    
    override func getMaxRequestCount() -> Int32 {
        return SendNewVessageRequestBase.maxRequestNoLimitCount
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
