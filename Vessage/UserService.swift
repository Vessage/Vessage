//
//  UserService.swift
//  Vessage
//
//  Created by AlexChow on 16/3/2.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK:UserService
class UserService: ServiceProtocol {
    @objc static var ServiceName:String {return "User Service"}
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        
    }
    
    var isUserMobileValidated:Bool{
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            return true
        }
        
        return false
    }
    
    func sendValidateMobilSMS(callback:(suc:Bool)->Void){
        
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            callback(suc: true)
        }
        
    }
    
    func validateMobile(mobile:String, smsKey:String,callback:(suc:Bool)->Void){
        
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            callback(suc: true)
        }
        
    }
}