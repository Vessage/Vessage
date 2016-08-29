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

class GuessYouPuzzle{
    var leftAnswer:String!
    var rightAnswer:String!
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
    
    func getPuzzles() -> [GuessYouPuzzle] {
        if let ps = puzzles{
            return ps.split(";").map({ (p) in
                let gyp = GuessYouPuzzle()
                let answers = p.split(",")
                gyp.leftAnswer = answers[0]
                gyp.rightAnswer = answers[1]
                return gyp
            })
        }
        return []
    }
}

class OnePuzzle: EVObject {
    var correct:String!
    var incorrect:String!
}

class MemberPuzzle: EVObject {
    var leastCnt = 3
    var puzzles:[OnePuzzle]!
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
    
    var puzzle:MemberPuzzle!{
        didSet{
            if let a = puzzle{
                self.paramenters["answer"] = a.toMiniJsonString()
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
                self.paramenters["answer"] = a.joinWithSeparator(";")
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
            self.paramenters["addition"] = "\(addition)"
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

