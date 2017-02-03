//
//  File.swift
//  Vessage
//
//  Created by AlexChow on 16/7/12.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK:ConversationViewControllerProxy
class ConversationViewControllerProxy: NSObject {
    private(set) weak var rootController:ConversationViewController!
    
    var isGroupChat:Bool{
        return rootController?.isGroupChat ?? false
    }
    
    var chatGroup:ChatGroup!{
        return rootController?.chatGroup
    }
    
    var fileService:FileService!{
        return rootController?.fileService
    }
    
    var conversation:Conversation!{
        return rootController?.conversation
    }
    
    var vessageService:VessageService!{
        return rootController?.vessageService
    }
    
    var backgroundImage:UIImageView!{
        return rootController?.backgroundImage
    }
    
    func onVessagesReceived(vessages:[Vessage]) {}

    func onInitGroup(chatGroup:ChatGroup) {}

    func onChatGroupUpdated(chatGroup:ChatGroup) {}
    func onGroupChatterUpdated(chatter:VessageUser) {}
    
    func onKeyBoardHidden() {}
    
    func onKeyBoardShown() {}
    
    func initManager(controller:ConversationViewController) {
        self.rootController = controller
    }
    
    func onReleaseManager() {
        self.rootController = nil
    }
    
    func onSwitchToManager() {
        //self.rootController.currentManager = self
    }
    
    func flashTips(msg:String) {
        self.rootController.flashTips(msg)
    }
}
