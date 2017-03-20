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
        return ServiceContainer.getService(SubscriptionService)
    }
}

class GetSubscriptionAccountsRequest:BahamutRFRequestBase {
    override init() {
        super.init()
        self.method = .GET
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
    
    @objc func appStartInit(appName: String) {
        
    }
    
    @objc func userLoginInit(userId: String) {
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        setServiceNotReady()
    }
    
    func getOnlineSubscriptionAccounts(callback:([SubAccount]?)->Void) {
        let req = GetSubscriptionAccountsRequest()
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[SubAccount]>) in
            callback(result.returnObject)
        }
    }
}
