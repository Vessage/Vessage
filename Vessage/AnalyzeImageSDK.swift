//
//  AnalyzeImageSDK.swift
//  Vessage
//
//  Created by AlexChow on 20/8/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//
import Foundation
import Alamofire
import AlamofireJsonToObjects

class AnalyzeImageSDK {
    static let instance:AnalyzeImageSDK = {
        return AnalyzeImageSDK()
    }()
    var subscriptionKey:String{
        return VessageConfig.bahamutConfig.faceDetectSubscriptionKey![Int(arc4random()) % VessageConfig.bahamutConfig.faceDetectSubscriptionKey.count]
    }
    
    func detectFace(picUrl:String) {
        let url = "https://api.projectoxford.ai/face/v1.0/detect?returnFaceId=true&returnFaceLandmarks=true"
        let headers = ["Content-Type":"application/json","Ocp-Apim-Subscription-Key":subscriptionKey]
        let data = "{\"url\":\"\(picUrl)\"}".toUTF8EncodingData()!
        Alamofire.upload(.POST, url, headers: headers, data: data).responseJSON { (response) in
            
        }
    }
}
