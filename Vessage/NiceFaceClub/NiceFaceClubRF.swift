//
//  NiceFaceClubRF.swift
//  Vessage
//
//  Created by AlexChow on 16/8/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class FaceScoreTestRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/FaceScoreTest"
        self.method = .GET
    }
    
    func setImageUrl(imageUrl:String){
        self.paramenters["imageUrl"] = imageUrl
    }
}

class SetNiceFaceRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/NiceFaceClub/NiceFace"
        self.method = .POST
    }
    
    var imageId:String!{
        didSet{
            if let v = imageId{
                self.paramenters["imageId"] = v
            }
        }
    }
    
    var faceTestResultId:String!{
        didSet{
            if let v = faceTestResultId{
                self.paramenters["faceTestResultId"] = v
            }
        }
    }
    
}