//
//  PaperAirplaneRF.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/14.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

class PaperAirplaneMessage: EVObject{
    var usrId:String!
    var nick:String!
    var avatar:String!
    var msg:String!
    var ts:Int64 = 0
    var loc:[Double]!
    
}

class PaperAirplane: EVObject {
    var id:String!
    var msgs = [PaperAirplaneMessage]()
}

class NewPaperAirplaneRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/PaperAirplane/New"
        self.method = .POST
    }
    
    var nick:String!{
        didSet{
            paramenters.updateValue(nick, forKey: "nick")
        }
    }
    
    var avatar:String!{
        didSet{
            paramenters.updateValue(avatar, forKey: "avatar")
        }
    }
    
    var msg:String!{
        didSet{
            paramenters.updateValue(msg, forKey: "msg")
        }
    }
    
    var location:String!{
        didSet{
            paramenters.updateValue(msg, forKey: "location")
        }
    }
}

class NewPaperAirplaneMessageRequest: NewPaperAirplaneRequest {
    override init() {
        super.init()
        self.api = "/PaperAirplane/Messages"
        self.method = .POST
    }
    
    var paId:String!{
        didSet{
            paramenters.updateValue(paId, forKey: "paId")
        }
    }
}

class GetMyPaperAirplanesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/PaperAirplane/Box"
        self.method = .GET
    }
}

class TryCatchPaperAirplaneRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/PaperAirplane/Catch"
        self.method = .POST
    }
}

class DestroyPaperAirplaneRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/PaperAirplane"
        self.method = .DELETE
    }
    
    var paId:String!{
        didSet{
            paramenters.updateValue(paId, forKey: "paId")
        }
    }
}
