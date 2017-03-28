//
//  SubscriptionService.swift
//  Vessage
//
//  Created by Alex Chow on 2017/3/20.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getSubscriptionService() -> SubscriptionService{
        return ServiceContainer.getService(SubscriptionService.self)
    }
}

class GetSubscriptionAccountsRequest:BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .get
        self.api = "/Subscription"
    }
}

class SubAccount: BahamutObject {
    var id:String!
    var title:String!
    var avatar:String!
    var desc:String!
}

class SubscriptionService: ServiceProtocol {
    @objc static var ServiceName:String {return "Subscription Service"}
    
    @objc func appStartInit(_ appName: String) {
        
    }
    
    @objc func userLoginInit(_ userId: String) {
        self.setServiceReady()
    }
    
    @objc func userLogout(_ userId: String) {
        setServiceNotReady()
    }
    
    func getOnlineSubscriptionAccounts(_ callback:@escaping ([SubAccount]?)->Void) {
        let req = GetSubscriptionAccountsRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SubAccount]>) in
            callback(result.returnObject)
        }
    }
}
