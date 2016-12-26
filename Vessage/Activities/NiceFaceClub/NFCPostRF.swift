//
//  NFCPostRF.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/17.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

//MARK: Models
class NFCPost: BahamutObject {
    
    static let typeNormalPost = 0
    static let typeNewMemberPost = 1
    static let typeMyPost = 2
    
    override func getObjectUniqueIdName() -> String {
        return "pid"
    }
    
    var pid:String! //Post Id
    
    var mbId:String! //NFC Member Id
    
    var img:String! //Post Image
    
    var ts:Int64 = 0 //Post Timespan
    
    var lc:Int = 0 //Like Count
    
    var t:Int = NFCPost.typeNormalPost //Type
    
    var pster:String! //Poster
    
    var cmtCnt:Int = 0 //Comment Count
    
    var upTs:Int64 = 0 //Update Timespan
    
    var body:String?
}

extension NFCPost{
    func getPostDateFriendString() -> String {
        if ts <= 0 {
            return "UNKNOW_DATE_TIME".niceFaceClubString
        }
        return NSDate(timeIntervalSince1970: Double(ts) / 1000).toFriendlyString()
    }
}

class NFCMainBoardData: EVObject {
    var nMemCnt = 0 //New Member Joined
    var nlks = 0 //New Likes
    var ncmt = 0 //New Comments
    var tlks = 0 //Total likes
    var annc:String! //Announcement
    var newMemAnnc:String! //New Member Announcement
    var posts:[NFCPost]!
}

class NFCPostComment: EVObject {
    var cmt:String! //Comment Content
    var ts:Int64 = 0 //Time Span Create
    var psterNk:String! //Poster nick
    var pster:String! //Poster Member Id
    var atNick:String! //@UserNick
    var postId:String! //NFC Post Id
    var img:String! //NFC post image
}

extension NFCPostComment{
    func getPostDateFriendString() -> String {
        if ts <= 0 {
            return "UNKNOW_DATE_TIME".niceFaceClubString
        }
        return NSDate(timeIntervalSince1970: Double(ts) / 1000).toFriendlyString()
    }
}

class NFCPostLike: EVObject {
    var ts:Int64 = 0 //time span create
    var usrId:String! //post like user id
    var nick:String! //post like user nick
    var mbId:String! //NFC member id
    var img:String! //NFC post image
}

extension NFCPostLike{
    func getPostDateFriendString(formatter:NSDateFormatter! = nil) -> String {
        if ts <= 0 {
            return "UNKNOW_DATE_TIME".niceFaceClubString
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
class GetNFCMainBoardDataRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NFCMainBoardData"
        self.method = .GET
    }
    
    var postCnt:Int = 20{
        didSet{
            paramenters.updateValue("\(postCnt)", forKey: "postCnt")
        }
    }
}

class GetNFCValuesRequestBase: BahamutRFRequestBase {
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

class GetNFCPostReqeust: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/Posts"
        self.method = .GET
    }
}

class GetNFCNewMemberPostRequest: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NewMemberPost"
        self.method = .GET
    }
}

class GetMyNFCPostRequest: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/MyPost"
        self.method = .GET
    }
}

class NFCPostNewRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NewPost"
        self.method = .POST
    }
    
    var image:String!{
        didSet{
            paramenters.updateValue(image, forKey: "image")
        }
    }
    
    var body:String?{
        didSet{
            if let b = body{
                paramenters.updateValue(b, forKey: "body")
            }
        }
    }
}

class NFCLikePostRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/LikePost"
        self.method = .POST
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
    
    var memberId:String!{
        didSet{
            if let mbId = memberId{
                paramenters.updateValue(mbId, forKey: "mbId")
            }
            
        }
    }
    
    var nick:String!{
        didSet{
            paramenters.updateValue(nick, forKey: "nick")
        }
    }
    
    
}

class GetNFCMemberUserIdRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/ChatMember"
        self.method = .GET
    }
    
    var memberId:String!{
        didSet{
            paramenters.updateValue(memberId, forKey: "memberId")
        }
    }
    
}

class NFCNewCommentRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/PostComments"
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
    
    var atMember:String!{
        didSet{
            if let at = atMember {
                if !String.isNullOrWhiteSpace(at) {
                    paramenters.updateValue(at, forKey: "atMember")
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

class GetNFCPostCommentRequest: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/PostComments"
        self.method = .GET
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
}

class GetNFCMyReceivedLikesRequest: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/ReceivedLikes"
        self.method = .GET
    }
}

class GetNFCMyCommentsRequest: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/MyComments"
        self.method = .GET
    }
}

class DeleteNFCPostRequest: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/Posts"
        self.method = .DELETE
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
}

class ReportObjectionableNFCPostRequest: GetNFCValuesRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/ObjectionablePosts"
        self.method = .PUT
    }
    
    var postId:String!{
        didSet{
            paramenters.updateValue(postId, forKey: "postId")
        }
    }
}
