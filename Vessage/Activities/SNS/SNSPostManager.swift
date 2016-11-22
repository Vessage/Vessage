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
        return LocalizedString(self, tableName: "SNS", bundle: NSBundle.mainBundle())
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
    
    private var likedPost = [String:Bool]()
    
    func getMainBoardData(postCnt:Int,callback:(data:SNSMainBoardData?)->Void) {

        let req = GetSNSMainBoardDataRequest()
        req.postCnt = postCnt
        var userIds = ServiceContainer.getConversationService().getChattingNormalUserIds()
        if !userIds.contains(UserSetting.userId!) {
            userIds.append(UserSetting.userId)
        }
        req.focusIds = userIds
        req.location = ServiceContainer.getLocationService().hereShortString
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<SNSMainBoardData>) in
            callback(data: result.returnObject)
        }
    }
    
    func getSNSNormalPosts(startTimeSpan:Int64,pageCount:Int,callback:(posts:[SNSPost])->Void) {
        getSNSPosts(SNSPost.typeNormalPost, startTimeSpan: startTimeSpan, pageCount: pageCount, callback: callback)
    }
    
    func getSNSPosts(type:Int,startTimeSpan:Int64,pageCount:Int,callback:(posts:[SNSPost])->Void) {

        let req:GetSNSValuesRequestBase!
        if type == SNSPost.typeMyPost {
            req = GetMySNSPostRequest()
        }else{
            req = GetSNSPostReqeust()
        }
        req.cnt = pageCount
        req.ts = startTimeSpan
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPost]>) in
            if let ps = result.returnObject{
                callback(posts: ps)
            }else{
                callback(posts: [])
            }
            
        }
    }
    
    func likedInCached(postId:String) -> Bool {
        return likedPost[postId] ?? false
    }
    
    func likePost(postId:String,callback:(suc:Bool)->Void) {

        let req = SNSLikePostRequest()
        req.postId = postId
        req.nick = ServiceContainer.getUserService().myProfile.nickName
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            if result.isSuccess{
                self.likedPost.updateValue(true, forKey: postId)
                MobClick.event("SNS_LikePost")
            }
            callback(suc: result.isSuccess)
        }
        
    }
    
    func newPost(imageId:String,callback:(post:SNSPost?)->Void) {
        let req = SNSPostNewRequest()
        req.image = imageId
        req.nick = ServiceContainer.getUserService().myProfile.nickName
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<SNSPost>) in
            callback(post: result.returnObject)
        }
        MobClick.event("SNS_NewPost")
    }
    
    func newPostComment(postId:String,comment:String,senderNick:String!,atUser:String! = nil,atUserNick:String! = nil,callback:(posted:Bool,msg:String?)->Void) {
        let req = SNSNewCommentRequest()
        req.postId = postId
        req.comment = comment
        req.senderNick = senderNick
        req.atUser = atUser
        req.atUserNick = atUserNick
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            callback(posted: result.isSuccess,msg: result.returnObject?.msg)
        }
        MobClick.event("SNS_NewComment")
    }
    
    func getPostComment(postId:String,ts:Int64,callback:(comments:[SNSPostComment]?)->Void) {

        let req = GetSNSPostCommentRequest()
        req.postId = postId
        req.ts = ts
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPostComment]>) in
            callback(comments: result.returnObject)
        }
    }
    
    func getMyComments(ts:Int64,cnt:Int,callback:(comments:[SNSPostComment]?)->Void) {
        let req = GetSNSMyCommentsRequest()
        req.cnt = cnt
        req.ts = ts
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPostComment]>) in
            callback(comments: result.returnObject)
        }
    }
    
    func getMyReceivedLikes(ts:Int64,cnt:Int,callback:(comments:[SNSPostLike]?)->Void) {
        let req = GetSNSMyReceivedLikesRequest()
        req.ts = ts
        req.cnt = cnt
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SNSPostLike]>) in
            callback(comments: result.returnObject)
        }
    }
    
}

//MARK: Manage Post
extension SNSPostManager{
    func deletePost(postId:String,callback:(Bool)->Void) {
        let req = DeleteSNSPostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
    
    func reportObjectionablePost(postId:String,callback:(Bool)->Void) {
        let req = ReportObjectionableSNSPostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
}

//MARK: God Methods
extension SNSPostManager{
    
    func godLikePost(postId:String,callback:(Bool)->Void) {
        let req = GodLikePostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
    
    func godDeletePost(postId:String,callback:(Bool)->Void) {
        let req = GodDeletePostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
    
    func godBlockMember(memberId:String,callback:(Bool)->Void) {
        let req = GodBlockMemberRequest()
        req.memberId = memberId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
}
