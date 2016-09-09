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
    
    
    var vessageView:UIView!{
        return rootController?.vessageView
    }
    var fileService:FileService!{
        return rootController?.fileService
    }
    
    var conversation:Conversation!{
        return rootController?.conversation
    }
    
    
    var chatter:VessageUser!{
        return rootController?.chatter
    }
    var vessageService:VessageService!{
        return rootController?.vessageService
    }
    var rightButton:UIButton!{
        return rootController?.rightButton
    }
    var badgeLabel:UILabel!{
        return rootController?.badgeLabel
    }
    
    var conversationLeftTopLabel:UILabel!{
        return rootController?.conversationLeftTopLabel
    }
    
    var conversationRightBottomLabel:UILabel!{
        return rootController?.conversationRightBottomLabel
    }
    
    var recordButton: UIButton!{
        return rootController?.middleButton
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
    var previewRectView: VideoPreviewBubble!{
        return rootController?.previewRectView
    }
    
    var backgroundImage:UIImageView!{
        return rootController?.backgroundImage
    }
    
    var nextVessageButton:UIButton!{
        return rootController?.nextVessageButton
    }
    
    
    func onVessageReceived(vessages:Vessage) {}
    func onChatterUpdated(chatter:VessageUser) {}
    func onChatGroupUpdated(chatGroup:ChatGroup) {}
    func initManager(controller:ConversationViewController) {
        self.rootController = controller
    }
    func onReleaseManager() {
        self.rootController = nil
    }
    func onSwitchToManager() {
        self.rootController = nil
    }
}