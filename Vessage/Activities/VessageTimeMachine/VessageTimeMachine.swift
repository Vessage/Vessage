//
//  VessageTimeMachine.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class VessageTimeMachineItem {
    var vessage:Vessage!
    var chatter:String!
}

extension VessageTimeMachineItem{
    
    func getVessageTimeMachineTitle() -> String {
        let userService = ServiceContainer.getUserService()
        
        let dateString = self.vessage?.getSendTime()?.toFriendlyString() ?? "UNKNOW_TIME".localizedString()
        let nickString = (self.vessage?.isMySendingVessage() ?? false) ? "ME".localizedString() : userService.getUserNotedName(self.vessage.getVessageRealSenderId() ?? "")
        return String(format: "X_AT_D", nickString,dateString)
    }
    
    func getSubline() -> String {
        switch vessage?.typeId ?? -1 {
        case Vessage.typeFaceText:
            return self.vessage.getBodyDict()["textMessage"] as? String ?? "UNKNOW_TEXT".localizedString()
        case Vessage.typeImage:
            return "SEND_AN_IMAGE".localizedString()
        case Vessage.typeChatVideo:
            return "SEND_A_CHAT_VIDEO".localizedString()
        case Vessage.typeLittleVideo:
            return "SEND_A_LITTLE_VIDEO".localizedString()
        default:
            return "SEND_AN_UNKNOW_VESSAGE".localizedString()
        }
    }
}


class VessageTimeMachine {
    static var instance:VessageTimeMachine = {
       return VessageTimeMachine()
    }()
    
    static func initWithUserId(userId:String){
        
    }
    
    static func release(){
        
    }
    
    func getVessageBefore(chatter:String,ts:Int64) -> [VessageTimeMachineItem] {
        var items = [VessageTimeMachineItem]()
        return items
    }
}
