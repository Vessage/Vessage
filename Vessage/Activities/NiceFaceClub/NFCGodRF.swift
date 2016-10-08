//
//  NFCGodRF.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class GodLikePostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/GodLikePost"
        self.method = .POST
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "pstId")
        }
    }
}

class GodDeletePostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/GodDeletePost"
        self.method = .DELETE
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "pstId")
        }
    }
}

class GodBlockMemberRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/GodBlockMember"
        self.method = .POST
    }
    
    var memberId:String!{
        didSet{
            paramenters.updateValue(memberId, forKey: "mbId")
        }
    }
}
