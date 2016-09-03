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

class NiceFaceClubManager:NSObject {
    static let lastRefreshMemberTimeKey = "REFRESHED_MEMBER_PROFILE_HOURS"
    static let refreshMemberProfileIntervalHours = NSNumber(double: 1)
    static var faceScoreAddition = false
    static let minScore:Float = 8.0
    static let instance:NiceFaceClubManager = {
        let mgr = NiceFaceClubManager()
        ShareHelper.instance.addObserver(mgr, selector: #selector(NiceFaceClubManager.onShareSuccess(_:)), name: ShareHelper.onShareSuccess, object: nil)
        return mgr
    }()
    
    var needSetMemberPuzzle:Bool{
        return membersProfileRead >= 2 && String.isNullOrWhiteSpace(myNiceFaceProfile.puzzles)
    }
    
    var membersProfileRead:Int{
        get{
            return UserSetting.getUserIntValue("NFC_PROFILE_READ")
        }
        set{
            UserSetting.setUserIntValue("NFC_PROFILE_READ", value: newValue)
        }
    }
    
    var preferredSex:Int{
        get{
            return UserSetting.getUserIntValue("NFC_PREFERRED_SEX")
        }
        set{
            UserSetting.setUserIntValue("NFC_PREFERRED_SEX", value: newValue)
        }
    }
    
    private var shareTimes = 0
    private var loadMemberProfileLeftTime = 0
    private(set) var myNiceFaceProfile:UserNiceFaceProfile!
    
    func onShareSuccess(a:NSNotification) {
        shareTimes += 1
    }
    
    private func refreshCachedMyFaceProfile() -> UserNiceFaceProfile? {
        let userId = ServiceContainer.getUserService().myProfile.userId
        self.myNiceFaceProfile = PersistentManager.sharedInstance.getModel(UserNiceFaceProfile.self, idValue: userId)
        return self.myNiceFaceProfile
    }
    
    func getMyNiceFaceProfile(callback:(UserNiceFaceProfile?)->Void) {
        if let mp = refreshCachedMyFaceProfile() {
            if mp.score < NiceFaceClubManager.minScore {
                callback(mp)
            }else if !updateMyProfileValues(){
                if let lastRefreshHours = UserSetting.getUserNumberValue(NiceFaceClubManager.lastRefreshMemberTimeKey){
                    if NSDate().totalHoursSince1970.doubleValue - lastRefreshHours.doubleValue < NiceFaceClubManager.refreshMemberProfileIntervalHours.doubleValue {
                        callback(mp)
                        return
                    }
                }
            }
        }
        
        let req = GetMyNiceFaceProfilesRequest()
        if let here = ServiceContainer.getLocationService().here {
            req.location = "{\"long\":\(here.coordinate.longitude),\"lati\":\(here.coordinate.latitude),\"alti\":\(here.altitude)}"
        }
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<UserNiceFaceProfile>) in
            if let profile = result.returnObject{
                self.myNiceFaceProfile = profile
                self.myNiceFaceProfile.saveModel()
                UserSetting.setUserNumberValue(NiceFaceClubManager.lastRefreshMemberTimeKey, value: NSDate().totalHoursSince1970)
                callback(profile)
            }else{
                callback(nil)
            }
        }
    }
    
    func updateMyProfileValues() -> Bool{
        let userProfile = ServiceContainer.getUserService().myProfile
        let req = UpdateMyProfileValuesRequest()
        var needUpdate = false
        if myNiceFaceProfile.nick != userProfile.nickName {
            req.nick = userProfile.nickName
            needUpdate = true
        }
        if myNiceFaceProfile.sex != userProfile.sex {
            req.sex = userProfile.sex
            needUpdate = true
        }
        if needUpdate {
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
                if result.isSuccess{
                    UserSetting.setUserNumberValue(NiceFaceClubManager.lastRefreshMemberTimeKey, value: NSDate().totalHoursSince1970)
                    if let newSex = req.sex{
                        self.myNiceFaceProfile.sex = newSex
                    }
                    if let newNick = req.nick{
                        self.myNiceFaceProfile.nick = newNick
                    }
                    self.myNiceFaceProfile.saveModel()
                }
            }
        }
        return needUpdate
        
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
        req.preferSex = preferredSex
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
        req.testResultId = testResult.rId
        req.testResultTimeSpan = testResult.ts
        req.score = testResult.hs
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            if result.isSuccess{
                self.myNiceFaceProfile.faceId = imageId
                self.myNiceFaceProfile.score = testResult.highScore
                self.myNiceFaceProfile.saveModel()
                PersistentManager.sharedInstance.saveAll()
            }
            callback(result.isSuccess)
        }
    }
    
    func setUserPuzzle(memberPuzzles:MemberPuzzles,callback:(Bool)->Void) {
        let req = SetPuzzleAnswerRequest()
        req.puzzle = memberPuzzles
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            if result.isSuccess{
                self.myNiceFaceProfile.puzzles = memberPuzzles.toMiniJsonString()
                self.myNiceFaceProfile.saveModel()
                PersistentManager.sharedInstance.saveAll()
            }
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
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<GuessPuzzleResult>) in
            if result.isSuccess{
                self.membersProfileRead += 1
                callback(res: result.returnObject)
            }else{
                let res = GuessPuzzleResult()
                res.id = IdUtil.generateUniqueId()
                res.pass = false
                res.msg = "GUESS_PUZZLE_ERROR".niceFaceClubString
                callback(res:res)
            }
        }
    }
}