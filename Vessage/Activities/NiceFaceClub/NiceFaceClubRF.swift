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

class GuessPuzzle:EVObject{
    var qs:String!
    var l:String!
    var r:String!
    
    var question:String!{
        return qs
    }
    var leftAnswer:String!{
        return l
    }
    var rightAnswer:String!{
        return r
    }
}

class GuessPuzzleResult: BahamutObject {
    var id:String!
    var pass = false
    var msg:String!
    var nick:String!
    var userId:String!
}

class UserNiceFaceProfile: BahamutObject {
    var id:String!
    var nick:String!
    var sex = 0
    var faceId:String!
    var score:Float = 0.0
    var puzzles:String!
    
    func getGuessPuzzles() -> [GuessPuzzle] {
        if let ps = puzzles{
            if !String.isNullOrWhiteSpace(ps) {
                return GuessPuzzle.arrayFromJson(ps)
            }
        }
        return []
    }
    
    func getMemberPuzzle() -> MemberPuzzles? {
        if let ps = puzzles{
            if !String.isNullOrWhiteSpace(ps) {
                return MemberPuzzles(json: ps)
            }
        }
        return nil
    }
}

class PuzzleModel: EVObject {
    var question:String!
    var correct:[String]!
    var incorrect:[String]!
}

class MemberPuzzles: EVObject {
    var leastCnt = 3
    var puzzles:[PuzzleModel]!
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

class GetNiceFaceProfilesRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NiceFaces"
        self.method = .GET
    }
    
    var preferSex:Int = 0{
        didSet{
            self.paramenters["preferSex"] = "\(preferSex)"
        }
    }
    
}

class SetPuzzleAnswerRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/PuzzleAnswer"
        self.method = .PUT
    }
    
    var puzzle:MemberPuzzles!{
        didSet{
            if let a = puzzle{
                self.paramenters["puzzle"] = a.toMiniJsonString()
            }
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

class GuessPuzzleRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/Puzzle"
        self.method = .POST
    }
    
    var profileId:String!{
        didSet{
            if let p = profileId{
                self.paramenters["profileId"] = p
            }
        }
    }
    
    var answer:[String]!{
        didSet{
            if let a = answer{
                let arr = a.map{"\"\($0)\""}
                self.paramenters["answer"] = "[\(arr.joinWithSeparator(","))]"
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

