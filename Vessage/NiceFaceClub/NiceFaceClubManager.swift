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
        let userProfile = ServiceContainer.getUserService().myProfile
        #if DEBUG
            let img = ServiceContainer.getUserService().myProfile.mainChatImage
            let p0 = UserNiceFaceProfile()
            p0.faceId = img
            p0.nick = "dd"
            p0.id = ServiceContainer.getUserService().myProfile.userId
            p0.puzzles = "🍌,🍎;#000000,#FFFFFF;苹果,香蕉"
            p0.score = 8.4
            p0.sex = 10
            self.myNiceFaceProfile = p0
            callback(p0)
            return;
        #endif
        
        if let mp = refreshCachedMyFaceProfile() {
            if  mp.nick == userProfile.nickName && mp.sex == userProfile.sex{
                callback(mp)
                return
            }
            if let lastRefreshHours = UserSetting.getUserNumberValue(NiceFaceClubManager.lastRefreshMemberTimeKey){
                if NSDate().totalHoursSince1970.doubleValue - lastRefreshHours.doubleValue < NiceFaceClubManager.refreshMemberProfileIntervalHours.doubleValue {
                    callback(mp)
                    return
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
    
    func faceScoreTest(imgUrl:String,addtion:Float,callback:(result:NiceFaceTestResult?)->Void) {
        let req = FaceScoreTestRequest()
        req.setImageUrl(imgUrl)
        req.addition = addtion
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NiceFaceTestResult>) in
            callback(result: result.returnObject)
        }
    }
    
    func loadProfiles(callback:([UserNiceFaceProfile])->Void) {
        
        #if DEBUG
            let img = ServiceContainer.getUserService().myChatImages.first?.imageId
            let p0 = UserNiceFaceProfile()
            p0.faceId = img
            p0.nick = "dd"
            p0.id = IdUtil.generateUniqueId()
            p0.puzzles = "🍌,🍎;#00FF00,#FFFFFF;苹果,香蕉"
            p0.score = 8.4
            p0.sex = 10
            
            let p1 = UserNiceFaceProfile()
            p1.faceId = img
            p1.nick = "dd"
            p1.id = IdUtil.generateUniqueId()
            p1.puzzles = "🍌,🍎;#F0F000,#FF0F0F;羽毛球羽毛球羽毛球,小羽毛球羽毛球提琴"
            p1.score = 8.4
            p1.sex = 10
            
            callback([p0,p1])
            return;
        #endif
        
        let req = GetNiceFaceProfilesRequest()
        req.preferSex = myNiceFaceProfile.sex * -1
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
            callback(result.isSuccess)
        }
    }
    
    func setUserPuzzle(memberPuzzle:MemberPuzzle,callback:(Bool)->Void) {
        let req = SetPuzzleAnswerRequest()
        req.puzzle = memberPuzzle
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
            res.userId = "578b6f9b99cc25210c5954bb"
            res.nick = "Hi"
            res.msg = "你不懂我，不和你聊😝" //你不懂我，不和你聊😝 //还是你懂我😌~~
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