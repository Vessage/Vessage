//
//  D.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

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

class PuzzleModel: EVObject {
    var question:String!
    var correct:[String]!
    var incorrect:[String]!
}

class MemberPuzzles: EVObject {
    var leastCnt = 3
    var puzzles:[PuzzleModel]!
}

extension UserNiceFaceProfile{
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
