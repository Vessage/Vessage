//
//  HelpTogetherRF.swift
//  Vessage
//
//  Created by AlexChow on 16/6/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class Help: BahamutObject {
    override func getObjectUniqueIdName() -> String {
        return "helpId"
    }
    
    var helpId:String!
    var title:String!
    var category:String!
    var content:String!
    var requestor:String!
    var requestorNick:String!
}

class GetMyHelpRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/HelpTogether"
    }
    
    func setPaperId(helpIds:String){
        self.paramenters["helpIds"] = helpIds
    }
}

class GetHelpSquareRequest: BahamutRFRequestBase {
    override init() {
        super.init()
        self.api = "/HelpTogether/Square"
    }
}

class PostHelpRequest: BahamutRFRequestBase {
    var toSquare:Bool = false{
        didSet{
            self.paramenters["toSquare"] = "\(toSquare)"
        }
    }
    
    var toReceiver:String!{
        didSet{
            self.paramenters["receiver"] = toReceiver
        }
    }
    
    var myNick:String!{
        didSet{
            self.paramenters["myNick"] = myNick
        }
    }
}

class PostNewHelpRequest: PostHelpRequest {
    override init() {
        super.init()
        self.api = "/HelpTogether"
        self.method = .POST
    }
    
    var category:String!{
        didSet{
            self.paramenters["category"] = category
        }
    }
    
    var title:String!{
        didSet{
            self.paramenters["title"] = title
        }
    }
    
    var helpDescription:String!{
        didSet{
            self.paramenters["desc"] = helpDescription
        }
    }
    
}

class PostHelpToNextRquest: PostHelpRequest {
    override init() {
        super.init()
        self.api = "/HelpTogether"
        self.method = .PUT
    }
    
    
    var helpId:String!{
        didSet{
            self.paramenters["helpId"] = helpId
        }
    }
}

