//
//  NFCPostManager.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

class NFCPostManager {
    static let activityId = "1002"
    static let instance:NFCPostManager = {
        let mgr = NFCPostManager()
        return mgr
    }()
    
    let NFC_LIKED_POSTIDS_KEY = "NFC_LIKED_POSTIDS"
    
    
    func initManager() {
        if let postIds = UserSetting.getUserValue(NFC_LIKED_POSTIDS_KEY) as? [String]{
            for id in postIds{
                likedPost.updateValue(true, forKey: id)
            }
        }
    }
    
    func releaseManager() {
        let ids:[String] = likedPost.flatMap{$0.0}
        UserSetting.setUserValue(NFC_LIKED_POSTIDS_KEY, value: ids)
        likedPost.removeAll()
    }
    
    private var likedPost = [String:Bool]()
    
    func getMainBoardData(postCnt:Int,callback:(data:NFCMainBoardData?)->Void) {

        let req = GetNFCMainBoardDataRequest()
        req.postCnt = postCnt
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NFCMainBoardData>) in
            callback(data: result.returnObject)
        }
    }
    
    func getNFCNormalPosts(startTimeSpan:Int64,pageCount:Int,callback:(posts:[NFCPost])->Void) {
        getNFCPosts(NFCPost.typeNormalPost, startTimeSpan: startTimeSpan, pageCount: pageCount, callback: callback)
    }
    
    func getNFCNewMemberPosts(startTimeSpan:Int64,pageCount:Int,callback:(posts:[NFCPost])->Void) {
        getNFCPosts(NFCPost.typeNewMemberPost, startTimeSpan: startTimeSpan, pageCount: pageCount, callback: callback)
    }
    
    func getNFCPosts(type:Int,startTimeSpan:Int64,pageCount:Int,callback:(posts:[NFCPost])->Void) {

        let req:GetNFCValuesRequestBase!
        if type == NFCPost.typeMyPost {
            req = GetMyNFCPostRequest()
        }else if type == NFCPost.typeNewMemberPost {
            req = GetNFCNewMemberPostRequest()
        }else{
            req = GetNFCPostReqeust()
        }
        req.cnt = pageCount
        req.ts = startTimeSpan
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[NFCPost]>) in
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
    
    func likePost(postId:String,mbId:String!,nick:String!,callback:(suc:Bool)->Void) {

        let req = NFCLikePostRequest()
        req.postId = postId
        req.memberId = mbId
        req.nick = nick
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            if result.isSuccess{
                self.likedPost.updateValue(true, forKey: postId)
                MobClick.event("NFC_LikePost")
            }
            callback(suc: result.isSuccess)
        }
    }
    
    class MemberUser: EVObject {
        var userId:String!
    }
    
    func chatMember(memberId:String,callback:(userId:String?)->Void) {
        let req = GetNFCMemberUserIdRequest()
        req.memberId = memberId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MemberUser>) in
            callback(userId: result.returnObject?.userId)
        }
    }
    
    func newPost(imageId:String,body:String?,callback:(post:NFCPost?)->Void) {
        let req = NFCPostNewRequest()
        req.image = imageId
        req.body = body
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NFCPost>) in
            callback(post: result.returnObject)
        }
        MobClick.event("NFC_NewPost")
    }
    
    func newPostComment(postId:String,comment:String,atMember:String! = nil,atUserNick:String! = nil,callback:(posted:Bool,msg:String?)->Void) {
        let req = NFCNewCommentRequest()
        req.postId = postId
        req.comment = comment
        req.atMember = atMember
        req.atUserNick = atUserNick
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            callback(posted: result.isSuccess,msg: result.returnObject?.msg)
        }
        MobClick.event("NFC_NewComment")
    }
    
    func getPostComment(postId:String,ts:Int64,callback:(comments:[NFCPostComment]?)->Void) {

        let req = GetNFCPostCommentRequest()
        req.postId = postId
        req.ts = ts
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[NFCPostComment]>) in
            callback(comments: result.returnObject)
        }
    }
    
    func getMyComments(ts:Int64,cnt:Int,callback:(comments:[NFCPostComment]?)->Void) {
        let req = GetNFCMyCommentsRequest()
        req.cnt = cnt
        req.ts = ts
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[NFCPostComment]>) in
            callback(comments: result.returnObject)
        }
    }
    
    func getMyReceivedLikes(ts:Int64,cnt:Int,callback:(comments:[NFCPostLike]?)->Void) {
        let req = GetNFCMyReceivedLikesRequest()
        req.ts = ts
        req.cnt = cnt
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[NFCPostLike]>) in
            callback(comments: result.returnObject)
        }
    }
    
}

//MARK: Manage Post
extension NFCPostManager{
    func deletePost(postId:String,callback:(Bool)->Void) {
        let req = DeleteNFCPostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
    
    func reportObjectionablePost(postId:String,callback:(Bool)->Void) {
        let req = ReportObjectionableNFCPostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            callback(result.isSuccess)
        }
    }
}

//MARK: God Methods
extension NFCPostManager{
    
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
