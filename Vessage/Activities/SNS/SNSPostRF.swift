//
//  SNSPostRF.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/17.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

//MARK: Models
class SNSPost: BahamutObject {
    
    static let typeNormalPost = 0
    static let typeMyPost = 1
    
    override func getObjectUniqueIdName() -> String {
        return "pid"
    }
    
    var pid:String! //Post Id
    
    var usrId:String! //Poster User Id
    
    var img:String! //Post Image
    
    var ts:Int64 = 0 //Post Timespan
    
    var lc:Int = 0 //Like Count
    
    var t:Int = SNSPost.typeNormalPost //Type
    
    var pster:String! //Poster
    
    var cmtCnt:Int = 0 //Comment Count
    
    var upTs:Int64 = 0 //Update Timespan
}

extension SNSPost{
    func getPostDateFriendString() -> String {
        if ts <= 0 {
            return "UNKNOW_DATE_TIME".SNSString
        }
        return NSDate(timeIntervalSince1970: Double(ts) / 1000).toFriendlyString()
    }
}

class SNSMainBoardData: EVObject {
    var nlks = 0 //New Likes
    var ncmt = 0 //New Comments
    var tlks = 0 //Total likes
    var annc:String! //Announcement
    var newer = false //first use sns
    var posts:[SNSPost]!
}

class SNSPostComment: EVObject {
    var cmt:String! //Comment Content
    var ts:Int64 = 0 //Time Span Create
    var psterNk:String! //Poster nick
    var pster:String! //Poster User Id
    var atNick:String! //@UserNick
    var postId:String! //SNS Post Id
    var img:String! //SNS post image
}

extension SNSPostComment{
    func getPostDateFriendString() -> String {
        if ts <= 0 {
            return "UNKNOW_DATE_TIME".SNSString
        }
        return NSDate(timeIntervalSince1970: Double(ts) / 1000).toFriendlyString()
    }
}

class SNSPostLike: EVObject {
    var ts:Int64 = 0 //time span create
    var usrId:String! //post like user id
    var nick:String! //post like user nick
    var img:String! //SNS post image
}

extension SNSPostLike{
    func getPostDateFriendString(formatter:NSDateFormatter! = nil) -> String {
        if ts <= 0 {
            return "UNKNOW_DATE_TIME".SNSString
        }
        var fmt = formatter
        if formatter == nil{
            fmt = NSDateFormatter()
            fmt.dateFormat = ""
        }
        return NSDate(timeIntervalSince1970: Double(ts) / 1000).toFriendlyString(fmt)
    }
}

//MARK: Requests
class GetSNSMainBoardDataRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/SNSMainBoardData"
        self.method = .GET
    }
    
    var postCnt:Int = 20{
        didSet{
            paramenters.updateValue("\(postCnt)", forKey: "postCnt")
        }
    }
    
    var location:String!{
        didSet{
            if let p = location{
                self.paramenters["location"] = p
            }
        }
    }
    
    var focusIds:[String]!{
        didSet{
            if let ids = focusIds{
                self.paramenters["focusIds"] = ids.joinWithSeparator(",")
            }
        }
    }
    
}

class GetSNSValuesRequestBase: BahamutRFRequestBase {
    var ts:Int64!{
        didSet{
            if let t = ts {
                paramenters.updateValue("\(t)", forKey: "ts")
            }
        }
    }
    
    var cnt:Int = 30{
        didSet{
            if cnt > 30 {
                paramenters.updateValue("30", forKey: "cnt")
            }else{
                paramenters.updateValue("\(cnt)", forKey: "cnt")
            }
        }
    }
}

class GetSNSPostReqeust: GetSNSValuesRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/Posts"
        self.method = .GET
    }
}

class GetSNSNewMemberPostRequest: GetSNSValuesRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/NewMemberPost"
        self.method = .GET
    }
}

class GetMySNSPostRequest: GetSNSValuesRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/MyPost"
        self.method = .GET
    }
}

class SNSPostNewRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/NewPost"
        self.method = .POST
    }
    
    var image:String!{
        didSet{
            paramenters.updateValue(image, forKey: "image")
        }
    }
    
    var nick:String!{
        didSet{
            paramenters.updateValue(nick, forKey: "nick")
        }
    }
    
    var body:String!{
        didSet{
            if !String.isNullOrEmpty(body) {
                paramenters.updateValue(body, forKey: "body")
            }
        }
    }
}

class SNSLikePostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/LikePost"
        self.method = .POST
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
    
    var nick:String!{
        didSet{
            paramenters.updateValue(nick, forKey: "nick")
        }
    }
    
}

class SNSNewCommentRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/PostComments"
        self.method = .POST
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
    
    var comment:String!{
        didSet{
            paramenters.updateValue(comment, forKey: "comment")
        }
    }
    
    var senderNick:String!{
        didSet{
            if let at = senderNick {
                if !String.isNullOrWhiteSpace(at) {
                    paramenters.updateValue(at, forKey: "senderNick")
                }
            }
        }
    }
    
    var atUser:String!{
        didSet{
            if let at = atUser {
                if !String.isNullOrWhiteSpace(at) {
                    paramenters.updateValue(at, forKey: "atUser")
                }
            }
        }
    }
    
    var atUserNick:String!{
        didSet{
            if let at = atUserNick {
                if !String.isNullOrWhiteSpace(at) {
                    paramenters.updateValue(at, forKey: "atNick")
                }
            }
        }
    }
}

class GetSNSPostCommentRequest: GetSNSValuesRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/PostComments"
        self.method = .GET
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
}

class GetSNSMyReceivedLikesRequest: GetSNSValuesRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/ReceivedLikes"
        self.method = .GET
    }
}

class GetSNSMyCommentsRequest: GetSNSValuesRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/MyComments"
        self.method = .GET
    }
}

class DeleteSNSPostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/Posts"
        self.method = .DELETE
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
}

class ReportObjectionableSNSPostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/SNS/ObjectionablePosts"
        self.method = .PUT
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
}
