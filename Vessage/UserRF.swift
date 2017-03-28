//
//  UserRF.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
 
class VessageUser: BahamutObject {
    static let typeNormal = 0
    static let typeSubscription = 1
    
    override func getObjectUniqueIdName() -> String {
        return "userId"
    }
    var userId:String!
    var nickName:String!
    var motto:String!
    
    var accountId:String!
    var mainChatImage:String!
    var avatar:String!
    var mobile:String!
    
    var lastUpdatedTime:Date!
    
    var sex = 0
    
    var acTs:Int64 = 0
    var location:[Double]!
    
    var t = 0
    
}

extension VessageUser{
    static func getUnLoadedUser(_ userId:String) -> VessageUser{
        let user = VessageUser()
        user.userId = userId
        user.nickName = "UNLOADED_USER".localizedString()
        return user
    }
    
    static func isTheSameUser(_ usera:VessageUser?,userb:VessageUser?) ->Bool{
        if let a = usera{
            if let b = userb{
                if !String.isNullOrWhiteSpace(a.userId) && !String.isNullOrWhiteSpace(b.userId) && a.userId == b.userId{
                    return true
                }
            }
        }
        return false
    }
}

class GetUserInfoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers"
    }
    
    override func getMaxRequestCount() -> Int32 {
        return 10
    }
    
    var userId:String!{
        didSet{
            self.api = "/VessageUsers/UserId/\(userId!)"
        }
    }
}

class GetUsersProfileRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers/Profiles"
    }
    
    var userIds:[String]!{
        didSet{
            if let us = userIds {
                self.paramenters["userIds"] = us.joined(separator: ",")
            }
        }
    }
}

class MobileMatchedUser: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "usrId"
    }
    var account:String!
    var usrId:String!
    var mobile:String!
    var nick:String!
    var avatar:String!
}

class MatchUsersWithMobileRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers/MatchMobileProfiles"
    }
    
    var mobiles:[String]!{
        didSet{
            if let us = mobiles {
                self.paramenters["mobiles"] = us.joined(separator: ",")
            }
        }
    }
}

class GetNearUsersInfoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers/Near"
    }
    
    var location:String!{
        didSet{
            self.paramenters["location"] = location
        }
    }
    
}

class GetActiveUsersInfoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers/Active"
    }
}

class GetUserInfoByAccountIdRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers/AccountId"
    }
    
    var accountId:String!{
        didSet{
            self.api = "/VessageUsers/AccountId/\(accountId!)"
        }
    }
}

class GetUserInfoByMobileRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers/Mobile"
    }
    
    var mobile:String!{
        didSet{
            self.paramenters["mobile"] = mobile
        }
    }
}

class SendMobileVSMSRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .post
        self.api = "/VessageUsers/SendMobileVSMS"
        
    }
    
    var mobile:String!{
        didSet{
            self.paramenters["mobile"] = mobile
        }
    }
}

class ValidateMobileVSMSRequest: BahamutRFRequestBase{
    override init() {
        super.init()
        self.method = .post
        self.api = "/VessageUsers/ValidateMobileVSMS"
        
    }
    
    var mobile:String!{
        didSet{
            self.paramenters["mobile"] = mobile
        }
    }
    
    var code:String!{
        didSet{
            self.paramenters["code"] = code
        }
    }
    
    var zoneCode:String!{
        didSet{
            self.paramenters["zone"] = zoneCode
        }
    }
    
    var smsAppkey:String!{
        didSet{
            self.paramenters["smsAppkey"] = smsAppkey
        }
    }
    
    var bindExistsAccount:Bool!{
        didSet{
            if let b = bindExistsAccount{
                self.paramenters["bindExistsAccount"] = "\(b)"
            }
        }
    }
    
}

class ChangeAvatarRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .put
        self.api = "/VessageUsers/Avatar"
    }
    
    var avatar:String!{
        didSet{
            self.paramenters["avatar"] = avatar
        }
    }
}

class ChangeMainChatImageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .put
        self.api = "/VessageUsers/MainChatImage"
    }
    
    var image:String!{
        didSet{
            self.paramenters["image"] = image
        }
    }
}

class ChangeUserSexValueRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .put
        self.api = "/VessageUsers/SexValue"
    }
    
    var value:Int!{
        didSet{
            if let v = value {
                self.paramenters["value"] = "\(v)"
            }
        }
    }
}

class ChangeNickRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .put
        self.api = "/VessageUsers/Nick"
    }
    
    var nick:String!{
        didSet{
            self.paramenters["nick"] = nick
        }
    }
}

class ChangeMottoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .put
        self.api = "/VessageUsers/Motto"
    }
    
    var motto:String!{
        didSet{
            self.paramenters["motto"] = motto
        }
    }
}


class RegistNewVessageUserRequest: BahamutRFRequestBase{
    override init() {
        super.init()
        self.method = .post
        self.api = "/NewUsers"
    }
    
    var region:String!{
        didSet{
            self.paramenters["region"] = region
        }
    }
    
    var nickName:String!{
        didSet{
            self.paramenters["nickName"] = nickName
        }
    }
    
    var motto:String!{
        didSet{
            self.paramenters["motto"] = motto
        }
    }
    
    var appkey:String!{
        didSet{
            self.paramenters["appkey"] = appkey
        }
    }
    var accountId:String!{
        didSet{
            self.paramenters["accountId"] = accountId
        }
    }
    
    var accessToken:String!{
        didSet{
            self.paramenters["accessToken"] = accessToken
        }
    }
}


//MARK: Deprecated
/*
class RegistMobileUserRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .post
        self.api = "/VessageUsers/NewMobileUser"
    }
    
    var mobile:String!{
        didSet{
            self.paramenters["mobile"] = mobile
        }
    }
    
    var inviteMessage:String!{
        didSet{
            if let msg = inviteMessage{
                self.paramenters["inviteMsg"] = msg
            }
        }
    }
    
}
 
class ChatImage: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "imageId"
    }
 
    var imageId:String!
    var imageType:String!
}

class UserChatImages: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "userId"
    }
    
    var userId:String!
    var chatImages:[ChatImage]!
    
}

class GetUserChatImageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/VessageUsers/ChatImages"
    }
    
    var userId:String!{
        didSet{
            self.paramenters["userId"] = userId
        }
    }
}

class UpdateChatImageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .put
        self.api = "/VessageUsers/ChatImages"
    }
    
    var imageType:String!{
        didSet{
            self.paramenters["imageType"] = imageType
        }
    }
    
    
    
    var image:String!{
        didSet{
            self.paramenters["image"] = image
        }
    }
}
*/
