//
//  NFCDeprecatedActions.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: Puzzle
extension NiceFaceClubManager{
    
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

//MARK: Member Profiles
let NFCReadMemberProfileLimitedPerDay = 10

extension NiceFaceClubManager{
    
    var needSetSex:Bool{
        return preferredSex == 0 && myNiceFaceProfile.sex == 0
    }
    
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
    
    private var lastLoadMemberProfileDay:Int{
        get{
            return UserSetting.getUserIntValue("NFC_LAST_LOAD_MP_DAY")
        }
    }
    
    private func setTodayLoadedMemperProfiles() {
        UserSetting.setUserIntValue("NFC_LAST_LOAD_MP_DAY", value: NSDate().totalDaysSince1970.integerValue)
    }
    
    var canShareAddTimes:Bool{
        return !UserSetting.isSettingEnable("NFC_TODAY_ADDTION_TIMES_SHARED")
    }
    
    func setTodaySharedAddTimes(){
        UserSetting.enableSetting("NFC_TODAY_ADDTION_TIMES_SHARED")
    }
    
    func loadProfiles(callback:([UserNiceFaceProfile])->Void) {
        let cachedProfiles = PersistentManager.sharedInstance.getAllModel(UserNiceFaceProfile).filter{$0.id != self.myNiceFaceProfile.id}
        if cachedProfiles.count > 0 {
            callback(cachedProfiles)
        }else{
            let req = GetNiceFaceProfilesRequest()
            req.preferSex = preferredSex
            BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[UserNiceFaceProfile]>) in
                var resultArr = [UserNiceFaceProfile]()
                if result.isSuccess{
                    if let arr = result.returnObject{
                        resultArr = arr
                        if arr.count > 0{
                            self.setTodayLoadedMemperProfiles()
                        }
                    }
                }
                callback(resultArr)
            }
        }
    }
    
    var loadMemberProfileLimitedTimes:Int{
        get{
            if lastLoadMemberProfileDay < NSDate().totalDaysSince1970.integerValue {
                PersistentManager.sharedInstance.removeAllModels(UserNiceFaceProfile)
                UserSetting.disableSetting("NFC_TODAY_ADDTION_TIMES_SHARED")
                UserSetting.setUserIntValue("NFC_TODAY_LOAD_MP_L_TIMES", value: NFCReadMemberProfileLimitedPerDay)
                return NFCReadMemberProfileLimitedPerDay
            }
            return UserSetting.getUserIntValue("NFC_TODAY_LOAD_MP_L_TIMES")
        }
    }
    
    func useLoadMemberProfileOnec() -> Bool {
        let leftTimes = loadMemberProfileLimitedTimes
        if leftTimes > 0 {
            UserSetting.setUserIntValue("NFC_TODAY_LOAD_MP_L_TIMES", value: leftTimes - 1)
            return true
        }
        return false
    }
    
    func addLoadMemberTimes(times:Int) {
        let leftTimes = loadMemberProfileLimitedTimes
        UserSetting.setUserIntValue("NFC_TODAY_LOAD_MP_L_TIMES", value: leftTimes + times)
    }
}
