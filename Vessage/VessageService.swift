//
//  VessageService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let NewVessageReceivedValue = "NewVessageReceivedValue"

//MARK: VessageService
class VessageService:NSNotificationCenter, ServiceProtocol {
    static let onNewVessageReceived = "onNewVessageReceived"
    @objc static var ServiceName:String {return "Vessage Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        setServiceReady()
        self.newVessageFromServer()
    }
    
    @objc func userLogout(userId: String) {
        
    }
    
    func sendVessage(receiverId:String?, receiverMobile:String?, fileId:String,callback:(sended:Bool)->Void){
        var req:BahamutRFRequestBase! = nil
        if let rId = receiverId{
            let r = SendNewVessageForUserRequest()
            r.receiverId = rId
            r.fileId = fileId
            req = r
        }else if let m = receiverMobile{
            let r = SendNewVessageForMobileRequest()
            r.receiverMobile = m
            r.fileId = fileId
            req = r
        }
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
            callback(sended: result.isSuccess)
        }
    }
    
    func readVessage(vessageId:String){
        let req = SetVessageRead()
        req.vessageId = vessageId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
        }
    }
    
    func newVessageFromServer(){
        let req = GetNewVessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[Vessage]>) -> Void in
            if let vsgs = result.returnObject{
                vsgs.saveBahamutObjectModels()
                vsgs.forEach({ (vsg) -> () in
                    self.postNotificationName(VessageService.onNewVessageReceived, object: self, userInfo: [NewVessageReceivedValue:vsg])
                })
                
                //TODO: remove mark
                //self.notifyVessageGot()
            }
        }
    }
    
    private func notifyVessageGot(){
        let req = NotifyGotNewVessagesRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result) -> Void in
        }
    }
    
    func getNotReadVessage(chatter:VessageUser) -> [Vessage]{
        return PersistentManager.sharedInstance.getAllModelFromCache(Vessage).filter{$0.isRead == false && ($0.sender == chatter.userId) }
    }
}