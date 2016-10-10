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
    
    static let minScore:Float = 8.0
    static let instance:NiceFaceClubManager = {
        let mgr = NiceFaceClubManager()
        ShareHelper.instance.addObserver(mgr, selector: #selector(NiceFaceClubManager.onShareSuccess(_:)), name: ShareHelper.onShareSuccess, object: nil)
        return mgr
    }()
    
    private var shareTimes = 0
    private var loadMemberProfileLeftTime = 0
    private(set) var myNiceFaceProfile:UserNiceFaceProfile!
    private(set) var userId:String!
    
    var isValidatedMember:Bool{
        return (myNiceFaceProfile?.score ?? 0) >= NiceFaceClubManager.minScore && myNiceFaceProfile.mbAcpt
    }
    
    func onShareSuccess(a:NSNotification) {
        shareTimes += 1
    }
    
    private func refreshCachedMyFaceProfile() -> UserNiceFaceProfile? {
        self.userId = ServiceContainer.getUserService().myProfile.userId
        self.myNiceFaceProfile = PersistentManager.sharedInstance.getModel(UserNiceFaceProfile.self, idValue: userId)
        return self.myNiceFaceProfile
    }
    
    func getMyNiceFaceProfile(callback:(UserNiceFaceProfile?)->Void) {
        if let mp = refreshCachedMyFaceProfile() {
            if mp.score < NiceFaceClubManager.minScore {
                callback(mp)
                return
            }else if !updateMyProfileValues(){
                if let lastRefreshHours = UserSetting.getUserNumberValue(NiceFaceClubManager.lastRefreshMemberTimeKey){
                    if NSDate().totalHoursSince1970.doubleValue - lastRefreshHours.doubleValue < NiceFaceClubManager.refreshMemberProfileIntervalHours.doubleValue {
                        callback(mp)
                        if mp.mbAcpt {
                            return
                        }
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
    
    func getUserProfile(profileId:String,callback:(profile:UserNiceFaceProfile?)->Void) {
        let profile = PersistentManager.sharedInstance.getModel(UserNiceFaceProfile.self, idValue: profileId)
        let nowTs = NSNumber(double:NSDate().timeIntervalSince1970).longLongValue
        if profile != nil && nowTs - profile!.updatedTs < 1000 * 60 * 60 * 24  {
            callback(profile:profile)
            return
        }
        let req = GetNFCMemberProfilesRequest()
        req.profileId = profileId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<UserNiceFaceProfile>) in
            if let profile = result.returnObject{
                profile.updatedTs = nowTs
                profile.saveModel()
                callback(profile: profile)
            }else{
                callback(profile: nil)
            }
        }
    }
}

//MARK: Modify Member Profile
extension NiceFaceClubManager{
    
    func updateMyProfileValues() -> Bool{
        if myNiceFaceProfile == nil || myNiceFaceProfile.score < NiceFaceClubManager.minScore{
            return false
        }
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

}

//MARK: face score
extension NiceFaceClubManager{
    
    func faceScoreTest(imgUrl:String,addtion:Float,callback:(result:NiceFaceTestResult?)->Void) {
        let req = FaceScoreTestRequest()
        req.setImageUrl(imgUrl)
        req.addition = addtion
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NiceFaceTestResult>) in
            callback(result: result.returnObject)
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
                if self.myNiceFaceProfile.score < NiceFaceClubManager.minScore{
                    self.myNiceFaceProfile.mbAcpt = false
                }
                self.myNiceFaceProfile.faceId = imageId
                self.myNiceFaceProfile.score = testResult.highScore
                self.myNiceFaceProfile.saveModel()
                PersistentManager.sharedInstance.saveAll()
            }
            callback(result.isSuccess)
        }
    }
    
}
