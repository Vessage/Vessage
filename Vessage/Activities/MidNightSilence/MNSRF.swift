//
//  MNSRF.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

class MNSUser :EVObject{
    var userId:String!
    var nick:String!
    var annc:String!
    var avatar:String!
    var aTs:Int64 = 0
}

class MNSMainInfo :EVObject{
    var annc:String!
    var newer = false
    var acUsers:[MNSUser]!
}


class GetMNSMainInfoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/MNS/MainInfo"
        self.method = .get
    }
    
    var location:String!{
        didSet{
            if let p = location{
                self.paramenters["location"] = p
            }
        }
    }
}

class UpdateMNSAnnounceRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/MNS/MidNightAnnc"
        self.method = .put
    }
    
    var midNightAnnounce:String!{
        didSet{
            if let p = midNightAnnounce{
                self.paramenters["mnannc"] = p
            }
        }
    }
}
