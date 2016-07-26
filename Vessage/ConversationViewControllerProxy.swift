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
    private(set) var rootController:ConversationViewController!
    
    var isGroupChat:Bool{
        return rootController.isGroupChat
    }
    
    var chatGroup:ChatGroup!{
        return rootController.chatGroup
    }
    
    
    var vessageView:UIView!{
        return rootController.vessageView
    }
    var fileService:FileService!{
        return rootController.fileService
    }
    
    var conversation:Conversation!{
        return rootController.conversation
    }
    
    
    var chatter:VessageUser!{
        return rootController.chatter
    }
    var vessageService:VessageService!{
        return rootController.vessageService
    }
    var rightButton:UIButton!{
        return rootController.rightButton
    }
    var noMessageTipsLabel:UILabel!{
        return rootController.noMessageTipsLabel
    }
    var badgeLabel:UILabel!{
        return rootController.badgeLabel
    }
    var vessageSendTimeLabel:UILabel{
        return rootController.vessageSendTimeLabel
    }
    
    var recordButton: UIButton!{
        return rootController.middleButton
    }
    
    var cancelRecordButton: UIButton!{
        return rootController.rightButton
    }
    
    var groupFaceImageViewContainer:UIView{
        return rootController.groupFaceContainer
    }
    
    var noSmileFaceTipsLabel: UILabel!{
        return rootController.noSmileFaceTipsLabel
    }
    var recordingFlashView: UIView!{
        return rootController.recordingFlashView
    }
    var recordingProgress:KDCircularProgress!{
        return rootController.recordingProgress
    }
    var previewRectView: UIView!{
        return rootController.previewRectView
    }
    
    var backgroundImage:UIImageView!{
        return rootController.backgroundImage
    }
    
    var imageChatButton:UIButton!{
        return rootController.imageChatButton
    }
    
    
    func onVessageReceived(vessages:Vessage) {}
    func onChatterUpdated(chatter:VessageUser) {}
    func onChatGroupUpdated(chatGroup:ChatGroup) {}
    func initManager(controller:ConversationViewController) {
        self.rootController = controller
    }
    func onReleaseManager() {
        
    }
    func onSwitchToManager() {
        
    }
}