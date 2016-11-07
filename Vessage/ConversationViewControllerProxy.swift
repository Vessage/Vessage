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
    
    var groupFaceImageViewContainer:UIView!{
        return rootController?.groupFaceContainer
    }
    
    var noSmileFaceTipsLabel: UILabel!{
        return rootController?.noSmileFaceTipsLabel
    }
    var recordingFlashView: UIView!{
        return rootController?.recordingFlashView
    }
    var recordingProgress:KDCircularProgress!{
        return rootController?.recordingProgress
    }
    var previewRectView: UIView!{
        return rootController?.previewRectView
    }
    
    var backgroundImage:UIImageView!{
        return rootController?.backgroundImage
    }
    
    func onVessagesReceived(vessages:[Vessage]) {}

    //func onInitChatter(chatter:VessageUser) {}
    func onInitGroup(chatGroup:ChatGroup) {}

    //func onChatterUpdated(chatter:VessageUser) {}
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
        self.rootController.currentManager = self
    }
}
