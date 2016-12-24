//
//  MYQRF.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

class MYQInfo :EVObject{
    var userId:String!
    var nick:String!
    var ques:String!
    var avatar:String!
    var aTs:Int64 = 0
}

class MYQMainInfo :EVObject{
    var ques:String!
    var newer = false
    var usrQues:[MYQInfo]!
}


class GetMYQMainInfoRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/MYQ/MainInfo"
        self.method = .GET
    }
    
    var location:String!{
        didSet{
            if let p = location{
                self.paramenters["location"] = p
            }
        }
    }
}

class UpdateMYQuestionRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/MYQ/Question"
        self.method = .PUT
    }
    
    var question:String!{
        didSet{
            if let q = question{
                self.paramenters["ques"] = q
            }
        }
    }
}
