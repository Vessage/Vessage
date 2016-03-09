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
    }
    
    @objc func userLogout(userId: String) {
        
    }
    
    func sendVessage(vessage:Vessage){
        
    }
    
    func finishSendVessage(vessageId:String){
        
    }
    
    func newVessageFromServer(){
        //TODO:
    }
    
    private func notifyVessageGot(){
        //TODO:
    }
    
    func getConversationNotReadVessage(conversationId:String) -> [Vessage]{
        //TODO:
        return [Vessage]()
    }
}