//
//  ConversationListCell.swift
//  Vessage
//
//  Created by AlexChow on 16/3/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: ConversationListCell
typealias ConversationListCellHandler = (cell:ConversationListCell)->Void
class ConversationListCell:ConversationListCellBase{
    static let reuseId = "ConversationListCell"
    
    override var rootController:ConversationListController!{
        didSet{
            if oldValue == nil{
                self.addObservers()
            }
        }
    }
    
    @IBOutlet weak var badgeButton: UIButton!{
        didSet{
            badgeButton.badgeValue = ""
            badgeButton.shouldHideBadgeAtZero = true
            badgeButton.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var avatarView: UIImageView!{
        didSet{
            avatarView.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var headLineLabel: UILabel!
    @IBOutlet weak var subLineLabel: UILabel!
    
    var conversationListCellHandler:ConversationListCellHandler!
    var originModel:AnyObject?{
        didSet{
            badge = 0
            if let conversation = originModel as? Conversation{
                updateWithConversation(conversation)
            }else if let searchResult = originModel as? SearchResultModel{
                if let conversation = searchResult.conversation{
                    updateWithConversation(conversation)
                }else if let user = searchResult.user{
                    updateWithUser(user)
                }else if let mobile = searchResult.mobile{
                    updateWithMobile(mobile)
                }
            }
        }
    }
    
    private var avatar:String!{
        didSet{
            if let imgView = self.avatarView{
                ServiceContainer.getService(FileService).setAvatar(imgView, iconFileId: avatar)
            }
        }
    }
    private var headLine:String!{
        didSet{
            self.headLineLabel?.text = headLine
        }
    }
    private var subLine:String!{
        didSet{
            self.subLineLabel?.text = subLine
        }
    }
    
    private var badge:Int = 0{
        didSet{
            badgeButton.badgeValue = badge > 0 ? "\(badge)" : ""
        }
    }
    
    deinit{
        ServiceContainer.getService(UserService).removeObserver(self)
        ServiceContainer.getService(VessageService).removeObserver(self)
        ServiceContainer.getService(ConversationService).removeObserver(self)
    }
    
    override func onCellClicked() {
        if let handler = conversationListCellHandler{
            handler(cell: self)
        }
    }
    
    //MARK: update actions
    private func updateWithConversation(conversation:Conversation){
        self.headLine = conversation.noteName
        self.subLine = conversation.lastMessageTime.dateTimeOfAccurateString.toFriendlyString()
        if let chatterId = conversation.chatterId{
            self.badge = self.rootController.vessageService.getNotReadVessage(chatterId).count
        }
        if let uId = conversation.chatterId{
            if let user = rootController.userService.getCachedUserProfile(uId){
                self.avatar = user.avatar
            }else{
                self.rootController.userService.fetchUserProfile(uId)
            }
        }
    }
    
    private func updateWithUser(user:VessageUser){
        self.headLine = user.nickName ?? user.accountId
        self.subLine = user.accountId
        self.avatar = user.avatar
    }
    
    private func updateWithMobile(mobile:String){
        self.headLine = mobile
        let msg = String(format: "OPEN_NEW_CHAT_WITH_MOBILE".localizedString(), mobile)
        self.subLine = msg
        self.avatar = nil
    }
    
    //MARK: notifications
    private func addObservers(){
        ServiceContainer.getService(UserService).addObserver(self, selector: "onUserProfileUpdated:", name: UserService.userProfileUpdated, object: nil)
        ServiceContainer.getService(VessageService).addObserver(self, selector: "onVessageReadAndReceived:", name: VessageService.onNewVessageReceived, object: nil)
        ServiceContainer.getService(VessageService).addObserver(self, selector: "onVessageReadAndReceived:", name: VessageService.onVessageRead, object: nil)
        ServiceContainer.getService(ConversationService).addObserver(self, selector: "onConversationUpdated:", name: ConversationService.conversationUpdated, object: nil)
    }
    
    func onConversationUpdated(a:NSNotification){
        if let conversation = self.originModel as? Conversation{
            if let con = a.userInfo?[ConversationUpdatedValue] as? Conversation{
                if conversation.conversationId == con.conversationId{
                    self.originModel = con
                }
            }
        }
    }
    
    func onUserProfileUpdated(a:NSNotification){
        if let conversation = self.originModel as? Conversation{
            if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
                if ConversationService.isConversationWithUser(conversation, user: user){
                    self.avatar = user.avatar
                }
            }
        }
    }
    
    func onVessageReadAndReceived(a:NSNotification){
        if let conversation = self.originModel as? Conversation{
            if let vsg = a.userInfo?[VessageServiceNotificationValue] as? Vessage{
                if ConversationService.isConversationVessage(conversation, vsg: vsg){
                    self.badge = self.rootController.vessageService.getNotReadVessage(conversation.chatterId).count
                }
            }
        }
    }

    
}

