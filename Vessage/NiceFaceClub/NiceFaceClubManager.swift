//
//  NiceFaceClubManager.swift
//  Vessage
//
//  Created by AlexChow on 16/8/21.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

extension String{
    var niceFaceClubString:String{
        return LocalizedString(self, tableName: "NiceFaceClub", bundle: NSBundle.mainBundle())
    }
}

class NiceFaceTestResult :BahamutObject{
    override func getObjectUniqueIdName() -> String {
        return "resultId"
    }
    var resultId:String!
    var highScore:Float = 0
    var msg:String!
    var timeSpan:Int64 = 0
    
}

class GuessYouPuzzle{
    var leftAnswer:String!
    var rightAnswer:String!
}

class GuessPuzzleResult: BahamutObject {
    var id:String!
    var pass = false
    var msg:String!
    var memberNick:String!
    var memberUserId:String!
}

class UserNiceFaceProfile: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "profileId"
    }
    
    var profileId:String!
    var nick:String!
    var sex = 0
    var faceImage:String!
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

class NiceFaceClubManager:NSObject {
    static var faceScoreAddition = false
    static let minScore:Float = 8.0
    static let instance:NiceFaceClubManager = {
        let mgr = NiceFaceClubManager()
        ShareHelper.instance.addObserver(mgr, selector: #selector(NiceFaceClubManager.onShareSuccess(_:)), name: ShareHelper.onShareSuccess, object: nil)
        return mgr
    }()
    
    private var shareTimes = 0{
        didSet{
            
        }
    }
    private var loadMemberProfileLeftTime = 0
    private(set) var myNiceFaceProfile:UserNiceFaceProfile!
    
    func onShareSuccess(a:NSNotification) {
        shareTimes += 1
    }
    
    func refreshCachedMyFaceProfile() -> UserNiceFaceProfile? {
        let userId = ServiceContainer.getUserService().myProfile.userId
        self.myNiceFaceProfile = PersistentManager.sharedInstance.getModel(UserNiceFaceProfile.self, idValue: userId)
        return self.myNiceFaceProfile
    }
    
    func getMyNiceFaceProfile(callback:(UserNiceFaceProfile?)->Void) {
        let req = GetMyNiceFaceProfilesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<UserNiceFaceProfile>) in
            if let profile = result.returnObject{
                self.myNiceFaceProfile = profile
                self.myNiceFaceProfile.saveModel()
                callback(profile)
            }else{
                callback(nil)
            }
        }
    }
    
    func faceScoreTest(imgUrl:String,addtion:Float,callback:(result:NiceFaceTestResult?)->Void) {
        let req = FaceScoreTestRequest()
        req.setImageUrl(imgUrl)
        req.addition = addtion
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NiceFaceTestResult>) in
            callback(result: result.returnObject)
        }
    }
    
    func loadProfiles(callback:([UserNiceFaceProfile])->Void) {
        let req = GetNiceFaceProfilesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[UserNiceFaceProfile]>) in
            var resultArr = [UserNiceFaceProfile]()
            if result.isSuccess{
                if let arr = result.returnObject{
                    resultArr = arr
                }
            }
            callback(resultArr)
        }
    }
    
    func setUserNiceFace(testResult:NiceFaceTestResult,imageId:String,callback:(Bool)->Void) {
        let req = SetNiceFaceRequest()
        req.imageId = imageId
        req.testResultId = testResult.resultId
        req.testResultTimeSpan = testResult.timeSpan
        req.score = testResult.highScore
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            callback(result.isSuccess)
        }
    }
    
    func setUserPuzzle(puzzleAnswers:[String],callback:(Bool)->Void) {
        let req = SetPuzzleAnswerRequest()
        req.answer = puzzleAnswers
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            callback(result.isSuccess)
        }
    }
    
    func likeMember(profileId:String) {
        let req = LikeMemberRequest()
        req.profileId = profileId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
        }
    }
    
    func dislikeMember(profileId:String) {
        let req = DislikeMemberRequest()
        req.profileId = profileId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
        }
    }
    
    func guessMember(profileId:String,answer:[String],callback:(res:GuessPuzzleResult)->Void) {
        let req = GuessPuzzleRequest()
        req.answer = answer
        req.profileId = profileId
        
        #if DEBUG
        let res = GuessPuzzleResult()
        res.id = IdUtil.generateUniqueId()
        res.pass = false
        res.memberUserId = "578b6f9b99cc25210c5954bb"
        res.memberNick = "Hi"
        callback(res: res)
        return;
        #endif
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<GuessPuzzleResult>) in
            if result.isSuccess{
                callback(res: result.returnObject)
            }else{
                let res = GuessPuzzleResult()
                res.id = IdUtil.generateUniqueId()
                res.pass = false
                res.msg = "NETWORK_ERROR".localizedString()
                callback(res:res)
            }
        }
    }
}