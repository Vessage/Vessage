//
//  HelpTogetherManager.swift
//  Vessage
//
//  Created by AlexChow on 16/6/4.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class HelpTogetherManager:NSNotificationCenter{
    static let onMyHelpItemsUpdated = "onMyHelpItemsUpdated"
    static private(set) var instance:HelpTogetherManager!
    static func initManager(myProfile:VessageUser){
        if instance == nil {
            instance = HelpTogetherManager()
        }
        instance.myProfile = myProfile
        instance.loadTestData()
    }
    
    static func releaseManager(){
        
    }
    
    private var myProfile:VessageUser!
    private(set) var receivedHelps = [Help]()
    private(set) var sendedHelps = [Help]()
    
    static let ReceivedHelpType = 1
    static let SendedHelpType = 2
    
    func getTypedHelps(type:Int,index:Int) -> Help? {
        if type == HelpTogetherManager.ReceivedHelpType {
            return receivedHelps[index]
        }else if type == HelpTogetherManager.SendedHelpType {
            return sendedHelps[index]
        }
        return nil
    }
    
    func loadTestData() {
        var h = Help()
        h.category = "TT"
        h.title = "Title"
        h.content = "Test Content"
        h.helpId = "ssssssssssssss"
        h.requestor = "55333f7ba57d884cbe9bd24549cba9a43a3c7ac9"
        h.requestorNick = "MYY"
        receivedHelps.append(h)
        
        h = Help()
        h.category = "TT1"
        h.title = "Title"
        h.content = "Test Content1"
        h.helpId = "sssssssssssss33s"
        h.requestor = "55333f7ba57d884cbe9bd24549cba9a43a3c7ac9"
        h.requestorNick = "MYY1"
        receivedHelps.append(h)
        
        h = Help()
        h.category = "T2T"
        h.title = "Title"
        h.content = "Test Content3 MY SENDED"
        h.helpId = "ssssssssssssss3223"
        h.requestor = "55333f7ba57d884cbe9bd24549cba9a43a3c7ac8"
        h.requestorNick = "CPLOVER"
        sendedHelps.append(h)
    }
    
    func refreshMyHelpItems() {
        let req = GetMyHelpRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[Help]>) in
            if let helps = result.returnObject{
                self.receivedHelps.removeAll()
                self.sendedHelps.removeAll()
                helps.forEach({ (h) in
                    if !String.isNullOrEmpty(h.requestor) && h.requestor == self.myProfile.userId{
                        self.sendedHelps.append(h)
                    }else{
                        self.receivedHelps.append(h)
                    }
                })
                self.postNotificationNameWithMainAsync(HelpTogetherManager.onMyHelpItemsUpdated, object: self, userInfo: nil)
            }
        }
    }
    
    func getSquareHelpItems() {
        let req = GetHelpSquareRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[Help]>) in
            if let helps = result.returnObject{
                
            }else{
                
            }
        }
    }
    
    func postNewHelp(title:String!,content:String!,toReceiver:String?,myNick:String!,toSquare:Bool = false,callback:(help:Help!)->Void) {
        let  req = PostNewHelpRequest()
        req.helpDescription = content
        req.title = title
        req.toReceiver = toReceiver
        req.toSquare = toSquare
        req.myNick = myNick
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<Help>) in
            if let h = result.returnObject{
                callback(help: h)
            }else{
                callback(help: nil)
            }
        }
    }
    
    func postHelpToNext(helpId:String,toReceiver:String?,myNick:String!,toSquare:Bool = false,callback:(help:Help!)->Void) {
        let  req = PostHelpToNextRquest()
        req.helpId = helpId
        req.toReceiver = toReceiver
        req.toSquare = toSquare
        req.myNick = myNick
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<Help>) in
            if let h = result.returnObject{
                callback(help: h)
            }else{
                callback(help: nil)
            }
        }
    }
    
}