//
//  NiceFaceClubRF.swift
//  Vessage
//
//  Created by AlexChow on 16/8/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

//MARK: Restful Model
class NiceFaceTestResult :BahamutObject{
    override func getObjectUniqueIdName() -> String {
        return "resultId"
    }
    var rId:String!
    var hs:Float = 0
    var msg:String!
    var ts:Int64 = 0
    
    var resultId:String!{
        return rId
    }
    
    var highScore:Float{
        return hs
    }
    
    var timeSpan:Int64{
        return ts
    }
}

class UserNiceFaceProfile: BahamutObject {
    var id:String!
    var nick:String!
    var sex = 0
    var faceId:String!
    var score:Float = 0.0
    //var puzzles:String!
    var likes:Int64 = 0
    
    //local properties
    var updatedTs:Int64 = 0
    
}

class NFCPost: BahamutObject {
    
    static let typeNormalPost = 0
    static let typeNewMemberPost = 1
    
    override func getObjectUniqueIdName() -> String {
        return "pid"
    }
    
    var pid:String! //Post Id
    
    var mbId:String! //NFC Member Id
    
    var img:String! //Post Image
    
    var ts:NSNumber! //Timespan
    
    var lc:Int = 0 //Like Count
    
    var t:Int = NFCPost.typeNormalPost //Type
    
    var pster:String! //Poster
}

class NFCMainBoardData: EVObject {
    var nMemCnt = 0 //New Member Joined
    var nlks = 0 //New Likes
    var tlks = 0 //Total likes
    var annc:String! //Announcement
    var posts:[NFCPost]!
}

class NFCPostComment: EVObject {
    var cmt:String! //Comment Content
    var ts:Int64 = 0 //Time Span Create
    var psterNk:String! //Poster nick
    var pster:String! //Poster User Id
}

//MARK: Restful Request
class GetMyNiceFaceProfilesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/MyNiceFace"
        self.method = .GET
    }
    
    var location:String!{
        didSet{
            if let p = location{
                self.paramenters["location"] = p
            }
        }
    }
}

class UpdateMyProfileValuesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/MyProfileValues"
        self.method = .PUT
    }
    
    var nick:String!{
        didSet{
            if let p = nick{
                self.paramenters["nick"] = p
            }
        }
    }
    
    var sex:Int!{
        didSet{
            if let p = sex{
                self.paramenters["sex"] = "\(p)"
            }
        }
    }
}

class GetNFCMemberProfilesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/Profiles"
        self.method = .GET
    }
    
    var profileId:String!{
        didSet{
            paramenters.updateValue(profileId, forKey: "profileId")
        }
    }
    
}

class LikeMemberRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/Like"
        self.method = .POST
    }
    
    var profileId:String!{
        didSet{
            if let p = profileId{
                self.paramenters["profileId"] = p
            }
        }
    }
    
}

class DislikeMemberRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/Dislike"
        self.method = .POST
    }
    
    var profileId:String!{
        didSet{
            if let p = profileId{
                self.paramenters["profileId"] = p
            }
        }
    }
}

class FaceScoreTestRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/FaceScoreTest"
        self.method = .GET
    }
    
    func setImageUrl(imageUrl:String){
        self.paramenters["imageUrl"] = imageUrl
    }
    
    var addition:Float!{
        didSet{
            if let a = addition {
                self.paramenters["addition"] = String.init(format: "%.1f", a)
            }
        }
    }
    
}

class SetNiceFaceRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NiceFace"
        self.method = .POST
    }
    
    var imageId:String!{
        didSet{
            if let v = imageId{
                self.paramenters["imageId"] = v
            }
        }
    }
    
    var score:Float!{
        didSet{
            if let v = score{
                self.paramenters["score"] = "\(v)"
            }
        }
    }
    
    var testResultId:String!{
        didSet{
            if let v = testResultId{
                self.paramenters["testResultId"] = v
            }
        }
    }
    
    var testResultTimeSpan:Int64!{
        didSet{
            if let v = testResultTimeSpan{
                self.paramenters["timeSpan"] = "\(v)"
            }
        }
    }
}

class GetNFCMainBoardDataRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NFCMainBoardData"
        self.method = .GET
    }
}

class GetNFCPostBase: BahamutRFRequestBase {
    var ts:NSNumber!{
        didSet{
            paramenters.updateValue("\(ts.longLongValue)", forKey: "ts")
        }
    }
    
    var cnt:NSNumber = 20{
        didSet{
            paramenters.updateValue("\(cnt.longLongValue)", forKey: "cnt")
        }
    }
}

class GetNFCPostReqeust: GetNFCPostBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/Posts"
        self.method = .GET
    }
}

class GetNFCNewMemberPostRequest: GetNFCPostBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NewMemberPost"
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
