//
//  SNSGodRF.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class SNSGodLikePostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/GodLikePost"
        self.method = .POST
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "pstId")
        }
    }
}

class SNSGodDeletePostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/GodDeletePost"
        self.method = .DELETE
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "pstId")
        }
    }
}

class SNSGodBlockMemberRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/GodBlockMember"
        self.method = .POST
    }
    
    var memberId:String!{
        didSet{
            paramenters.updateValue(memberId, forKey: "mbId")
        }
    }
}
