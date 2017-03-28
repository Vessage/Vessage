//
//  SNSPostManager.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

extension String{
    var SNSString:String{
        return LocalizedString(self, tableName: "SNS", bundle: Bundle.main)
    }
}

class SNSPostManager {
    static let activityId = "1003"
    static let instance:SNSPostManager = {
        let mgr = SNSPostManager()
        return mgr
    }()
    
    let SNS_LIKED_POSTIDS_KEY = "SNS_LIKED_POSTIDS"
    
    
    func initManager() {
        if let postIds = UserSetting.getUserValue(SNS_LIKED_POSTIDS_KEY) as? [String]{
            for id in postIds{
                likedPost.updateValue(true, forKey: id)
            }
        }
    }
    
    func releaseManager() {
        let ids:[String] = likedPost.flatMap{$0.0}
        UserSetting.setUserValue(SNS_LIKED_POSTIDS_KEY, value: ids)
        likedPost.removeAll()
    }
    
    fileprivate var likedPost = [String:Bool]()
    
    func getMainBoardData(_ postCnt:Int,callback:@escaping (_ data:SNSMainBoardData?)->Void) {

        let req = GetSNSMainBoardDataRequest()
        req.postCnt = postCnt
        var userIds = ServiceContainer.getConversationService().getChattingNormalUserIds()
        if !userIds.contains(UserSetting.userId!) {
            userIds.append(UserSetting.userId)
        }
        req.focusIds = userIds
        req.location = ServiceContainer.getLocationService().hereShortString
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<SNSMainBoardData>) in
            callback(result.returnObject)
        }
    }
    
    func getSNSNormalPosts(_ startTimeSpan:Int64,pageCount:Int,callback:@escaping (_ posts:[SNSPost])->Void) {
        getSNSPosts(SNSPost.typeNormalPost, startTimeSpan: startTimeSpan, pageCount: pageCount, callback: callback)
    }
    
    func getSNSPosts(_ type:Int,startTimeSpan:Int64,pageCount:Int,specificUserId:String? = nil,callback:@escaping (_ posts:[SNSPost])->Void) {

        let req:GetSNSValuesRequestBase!
        if type == SNSPost.typeMyPost {
            req = GetMySNSPostRequest()
        }else if type == SNSPost.typeSingleUserPost{
            let r = GetUserSNSPostRequest()
            r.userId = specificUserId
            req = r
        }else{
            req = GetSNSPostReqeust()
        }
        req.cnt = pageCount
        req.ts = startTimeSpan
        
        getSNSPosts(req, callback: callback)
    }
    
    func getSNSPosts(_ req:GetSNSValuesRequestBase,callback:@escaping (_ posts:[SNSPost])->Void) {
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPost]>) in
            if let ps = result.returnObject{
                callback(ps)
            }else{
                callback([])
            }
            
        }
    }
    
    func likedInCached(_ postId:String) -> Bool {
        return likedPost[postId] ?? false
    }
    
    func likePost(_ postId:String,callback:@escaping (_ suc:Bool)->Void) {

        let req = SNSLikePostRequest()
        req.postId = postId
        req.nick = ServiceContainer.getUserService().myProfile.nickName
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            if result.isSuccess{
                self.likedPost.updateValue(true, forKey: postId)
                MobClick.event("SNS_LikePost")
            }
            callback(result.isSuccess)
        }
        
    }
    
    func newPost(_ imageId:String?,body:String?,state:Int,autoPrivate:Int,callback:@escaping (_ post:SNSPost?)->Void) {
        let req = SNSPostNewRequest()
        req.image = imageId
        req.body = body
        req.state = state
        req.nick = ServiceContainer.getUserService().myProfile.nickName
        req.autoPrivate = autoPrivate
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<SNSPost>) in
            callback(result.returnObject)
        }
        MobClick.event("SNS_NewPost")
    }
    
    class PostCmtResult: MsgResult {
        var cmtId:String!
    }
    
    func newPostComment(_ postId:String,comment:String,senderNick:String!,atUser:String! = nil,atUserNick:String! = nil,callback:@escaping (_ postedCmtId:String?,_ msg:String?)->Void) {
        let req = SNSNewCommentRequest()
        req.postId = postId
        req.comment = comment
        req.senderNick = senderNick
        req.atUser = atUser
        req.atUserNick = atUserNick
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<PostCmtResult>) in
            if result.isSuccess{
                MobClick.event("SNS_NewComment")
                callback(result.returnObject?.cmtId, result.returnObject?.msg)
            }else{
                callback(nil, result.returnObject?.msg)
            }
        }
    }
    
    func getPostComment(_ postId:String,ts:Int64,callback:@escaping (_ comments:[SNSPostComment]?)->Void) {

        let req = GetSNSPostCommentRequest()
        req.postId = postId
        req.ts = ts
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPostComment]>) in
            callback(result.returnObject)
        }
    }
    
    func getMyComments(_ ts:Int64,cnt:Int,callback:@escaping (_ comments:[SNSPostComment]?)->Void) {
        let req = GetSNSMyCommentsRequest()
        req.cnt = cnt
        req.ts = ts
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPostComment]>) in
            callback(result.returnObject)
        }
    }
    
    func getMyReceivedLikes(_ ts:Int64,cnt:Int,callback:@escaping (_ comments:[SNSPostLike]?)->Void) {
        let req = GetSNSMyReceivedLikesRequest()
        req.ts = ts
        req.cnt = cnt
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPostLike]>) in
            callback(result.returnObject)
        }
    }
    
}

//MARK: Manage Post
extension SNSPostManager{
    func updatePostState(_ postId:String,state:Int,callback:@escaping (Bool)->Void) {
        var req:BahamutRFRequestBase!
        if state < 0 {
            let r = DeleteSNSPostRequest()
            r.postId = postId
            req = r
        }else{
            let r = UpdateSNSPostStateRequest()
            r.postId = postId
            r.state = state
            req = r
        }
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
    
    func reportObjectionablePost(_ postId:String,callback:@escaping (Bool)->Void) {
        let req = ReportObjectionableSNSPostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
}

//MARK: Manage Post Comment
extension SNSPostManager{
    func deletePostComment(_ postId:String,cmtId:String,isCmtOwner:Bool,callback:@escaping (Bool)->Void) {
        let req = DeleteSNSComment()
        req.cmtId = cmtId
        req.postId = postId
        req.cmtOwner = isCmtOwner
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
}

//MARK: God Methods
extension SNSPostManager{
    
    func godLikePost(_ postId:String,callback:@escaping (Bool)->Void) {
        let req = SNSGodLikePostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
    
    func godDeletePost(_ postId:String,callback:@escaping (Bool)->Void) {
        let req = SNSGodDeletePostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
    
    func godBlockMember(_ memberId:String,callback:@escaping (Bool)->Void) {
        let req = SNSGodBlockMemberRequest()
        req.memberId = memberId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
}
