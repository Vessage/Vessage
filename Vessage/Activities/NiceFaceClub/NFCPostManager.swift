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
    
    func getMainBoardData(callback:(data:NFCMainBoardData?)->Void) {
        #if DEBUG
            if "1" == "\(1)"{
                let p = NFCPost()
                p.img = "579eaacf9c46b95c3f884f9d"
                p.lc = 100
                p.mbId = IdUtil.generateUniqueId()
                p.pid = IdUtil.generateUniqueId()
                p.t = NFCPost.typeNormalPost
                p.ts = NSNumber(double: NSDate().timeIntervalSince1970)
                p.pster = "me"
                let d = NFCMainBoardData()
                d.nlks = 100
                d.nMemCnt = 300
                d.posts = [p,p,p]
                callback(data: d)
                return
            }
        #endif
        
        let req = GetNFCMainBoardDataRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NFCMainBoardData>) in
            callback(data: result.returnObject)
        }
    }
    
    func getNFCNormalPosts(startTimeSpan:NSNumber,pageCount:Int,callback:(posts:[NFCPost])->Void) {
        getNFCPosts(NFCPost.typeNormalPost, startTimeSpan: startTimeSpan, pageCount: pageCount, callback: callback)
    }
    
    func getNFCNewMemberPosts(startTimeSpan:NSNumber,pageCount:Int,callback:(posts:[NFCPost])->Void) {
        getNFCPosts(NFCPost.typeNewMemberPost, startTimeSpan: startTimeSpan, pageCount: pageCount, callback: callback)
    }
    
    func getNFCPosts(type:Int,startTimeSpan:NSNumber,pageCount:Int,callback:(posts:[NFCPost])->Void) {
        
        #if DEBUG
            if "1" == "\(1)"{
                let p = NFCPost()
                p.img = "579eaacf9c46b95c3f884f9d"
                p.lc = type == 1 ? 2 : 11234
                p.mbId = IdUtil.generateUniqueId()
                p.pid = IdUtil.generateUniqueId()
                p.t = type
                p.pster = "me"
                p.ts = NSNumber(double: NSDate().timeIntervalSince1970)
                callback(posts: [p])
                return
            }
        #endif
        
        let req:GetNFCPostBase!
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
    
    func likePost(postId:String,callback:(suc:Bool)->Void) {
        #if DEBUG
            if "1" == "\(1)"{
                callback(suc: true)
                return
            }
        #endif
        
        let req = NFCLikePostRequest()
        req.postId = postId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            if result.isSuccess{
                self.likedPost.updateValue(true, forKey: postId)
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
    
    func newPost(imageId:String,callback:(post:NFCPost?)->Void) {
        let req = NFCPostNewRequest()
        req.image = imageId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NFCPost>) in
            callback(post: result.returnObject)
        }
    }
    
    func newPostComment(postId:String,comment:String,callback:(posted:Bool,msg:String?)->Void) {
        
        #if DEBUG
            if "1" == "\(1)"{
                callback(posted: true,msg: nil)
                return
            }
        #endif
        
        
        let req = NFCNewCommentRequest()
        req.postId = postId
        req.comment = comment
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            callback(posted: result.isSuccess,msg: result.returnObject?.msg)
        }
    }
    
    func getPostComment(postId:String,ts:Int64,callback:(comments:[NFCPostComment]?)->Void) {
        #if DEBUG            
            if "1" == "\(1)"{
                let cmt = NFCPostComment()
                cmt.cmt = "自拍时间到"
                cmt.pster = "sdfa"
                cmt.psterNk = "妮妮"
                cmt.ts = Int64(NSDate().timeIntervalSince1970)
                callback(comments: [cmt])
                return
            }
        #endif
        
        let req = GetNFCPostCommentRequest()
        req.postId = postId
        req.ts = NSNumber(longLong:ts)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[NFCPostComment]>) in
            callback(comments: result.returnObject)
        }
    }
    
    func godLikePost(postId:String) {
        let req = GodLikePostRequest()
        req.postId = postId
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            
        }
    }
    
    func godDeletePost(postId:String) {
        let req = GodDeletePostRequest()
        req.postId = postId
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            
        }
    }
    
    func godBlockMember(memberId:String) {
        let req = GodBlockMemberRequest()
        req.memberId = memberId
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { result in
            
        }
    }
    
    
}
