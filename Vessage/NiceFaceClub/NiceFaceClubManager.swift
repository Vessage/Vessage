//
//  NiceFaceClubManager.swift
//  Vessage
//
//  Created by AlexChow on 16/8/21.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class NiceFaceTestResult :BahamutObject{
    override func getObjectUniqueIdName() -> String {
        return "resultId"
    }
    var resultId:String!
    var highScore:Float = 0
    var msg:String!
}

class NiceFaceClubManager {
    static let minScore:Float = 8.0
    static let instance:NiceFaceClubManager = {
       return NiceFaceClubManager()
    }()
    
    func faceScoreTest(imgUrl:String,callback:(result:NiceFaceTestResult?)->Void) {
        let req = FaceScoreTestRequest()
        req.setImageUrl(imgUrl)
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<NiceFaceTestResult>) in
            callback(result: result.returnObject)
        }
    }
    
    func setUserNiceFace(imageTestId:String,imageId:String,callback:(Bool)->Void) {
        let req = SetNiceFaceRequest()
        req.imageId = imageId
        req.faceTestResultId = imageTestId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            callback(result.isSuccess)
        }
    }
}