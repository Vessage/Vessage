//
//  UserRF.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

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

class VessageUser: BahamutObject {
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
    
    var lastUpdatedTime:NSDate!
}

extension VessageUser{
    static func getUnLoadedUser(userId:String) -> VessageUser{
        let user = VessageUser()
        user.userId = userId
        user.nickName = "UNLOADED_USER".localizedString()
        return user
    }
    
    static func isTheSameUser(usera:VessageUser?,userb:VessageUser?) ->Bool{
        if let a = usera{
            if let b = userb{
                if !String.isNullOrWhiteSpace(a.userId) && !String.isNullOrWhiteSpace(b.userId) && a.userId == b.userId{
                    return true
                }
                if !String.isNullOrWhiteSpace(a.mobile) && !String.isNullOrWhiteSpace(b.mobile){
                    if a.mobile == b.mobile || a.mobile.md5 == b.mobile || a.mobile == b.mobile.md5{
                        return true
                    }
                }
            }
        }
        return false
    }
}

class GetUserInfoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
        self.api = "/VessageUsers"
    }
    
    override func getMaxRequestCount() -> Int32 {
        return 10
    }
    
    var userId:String!{
        didSet{
            self.api = "/VessageUsers/UserId/\(userId)"
        }
    }
}

class GetNearUsersInfoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
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
        self.method = .GET
        self.api = "/VessageUsers/Active"
    }
}

class GetUserInfoByAccountIdRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
        self.api = "/VessageUsers/AccountId"
    }
    
    var accountId:String!{
        didSet{
            self.api = "/VessageUsers/AccountId/\(accountId)"
        }
    }
}

class GetUserInfoByMobileRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
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
        self.method = .POST
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
        self.method = .POST
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
}

class ChangeAvatarRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .PUT
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
        self.method = .PUT
        self.api = "/VessageUsers/MainChatImage"
    }
    
    var image:String!{
        didSet{
            self.paramenters["image"] = image
        }
    }
}

class GetUserChatImageRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
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
        self.method = .PUT
        self.api = "/VessageUsers/ChatImages"
    }
    
    var imageType:String!{
        didSet{
            self.paramenters["imageType"] = image
        }
    }
    
    
    var image:String!{
        didSet{
            self.paramenters["image"] = image
        }
    }
}

class ChangeNickRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .PUT
        self.api = "/VessageUsers/Nick"
    }
    
    var nick:String!{
        didSet{
            self.paramenters["nick"] = nick
        }
    }
}

class RegistMobileUserRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .POST
        self.api = "/VessageUsers/NewMobileUser"
    }
    
    var mobile:String!{
        didSet{
            self.paramenters["mobile"] = mobile
        }
    }
}

class RegistNewVessageUserRequest: BahamutRFRequestBase{
    override init() {
        super.init()
        self.method = .POST
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
