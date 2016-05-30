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
    
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.hidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
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
            
            if let conversation = originModel as? Conversation{
                updateWithConversation(conversation)
            }else if let searchResult = originModel as? SearchResultModel{
                if let conversation = searchResult.conversation{
                    updateWithConversation(conversation)
                }else if let user = searchResult.user{
                    updateWithUser(user)
                    if searchResult.activeUser {
                        subLine = "ACTIVE_USER".localizedString()
                    }
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

    private var badgeValue:Int = 0 {
        didSet{
            if badgeLabel != nil{
                if badgeValue == 0{
                    badgeLabel.hidden = true
                }else{
                    badgeLabel.text = "\(badgeValue)"
                    badgeLabel.hidden = false
                    badgeLabel.animationMaxToMin()
                }
            }
        }
    }

    func removeObservers(){
        ServiceContainer.getUserService().removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
        ServiceContainer.getConversationService().removeObserver(self)
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
            self.badgeValue = self.rootController.vessageService.getChatterNotReadVessageCount(chatterId)
            if let user = rootController.userService.getCachedUserProfile(chatterId){
                self.avatar = user.avatar
            }else{
                self.rootController.userService.fetchUserProfile(chatterId)
                self.avatar = nil
            }
        }
    }
    
    private func updateWithUser(user:VessageUser){
        self.headLine = user.nickName ?? user.accountId
        self.subLine = user.accountId
        self.avatar = user.avatar
        self.badgeValue = 0
    }
    
    private func updateWithMobile(mobile:String){
        self.headLine = mobile
        let msg = String(format: "OPEN_NEW_CHAT_WITH_MOBILE".localizedString(), mobile)
        self.subLine = msg
        self.avatar = nil
        self.badgeValue = 0
    }
    
    //MARK: notifications
    private func addObservers(){
        ServiceContainer.getUserService().addObserver(self, selector: #selector(ConversationListCell.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(ConversationListCell.onVessageReadAndReceived(_:)), name: VessageService.onNewVessageReceived, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(ConversationListCell.onVessageReadAndReceived(_:)), name: VessageService.onVessageRead, object: nil)
        ServiceContainer.getConversationService().addObserver(self, selector: #selector(ConversationListCell.onConversationUpdated(_:)), name: ConversationService.conversationUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(ConversationListCell.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        
    }
    
    func onServicesWillLogout(a:NSNotification) {
        removeObservers()
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
                    self.badgeValue = self.rootController.vessageService.getChatterNotReadVessageCount(conversation.chatterId)
                }
            }
        }
    }

    
}

