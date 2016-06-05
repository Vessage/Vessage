//
//  HelpTogetherManager.swift
//  Vessage
//
//  Created by AlexChow on 16/6/4.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class HelpTogetherManager{
    static private(set) var instance:HelpTogetherManager!
    static func initManager(){
        if instance == nil {
            instance = HelpTogetherManager()
        }
    }
    
    static func releaseManager(){
        
    }
    
    func refreshMyHelpItems(callback:()->Void) {
        let req = GetMyHelpRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            
        }
    }
    
    func getSquareHelpItems(callback:()->Void) {
        let req = GetHelpSquareRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            
        }
    }
    
    func postNewHelp(title:String!,content:String!,toReceiver:String?,toSquare:Bool = false,callback:(help:Help!)->Void) {
        let  req = PostNewHelpRequest()
        req.helpDescription = content
        req.title = title
        req.toReceiver = toReceiver
        req.toSquare = toSquare
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            
        }
    }
    
    func postHelpToNext(helpId:String,toReceiver:String?,toSquare:Bool = false,callback:(help:Help!)->Void) {
        let  req = PostHelpToNextRquest()
        req.helpId = helpId
        req.toReceiver = toReceiver
        req.toSquare = toSquare
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) in
            
        }
    }
    
}