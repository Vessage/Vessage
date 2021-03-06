//
//  ConversationListCell.swift
//  Vessage
//
//  Created by AlexChow on 16/3/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import CoreLocation
import LTMorphingLabel

//MARK: ConversationListCellBase
class ConversationListCellBase:UITableViewCell{
    weak var rootController:ConversationListController!
    
    func onCellClicked(){
        
    }
    
    deinit{
        rootController = nil
    }
}

//MARK: ConversationListCell
typealias ConversationListCellHandler = (_ cell:ConversationListCell)->Void
class ConversationListCell:ConversationListCellBase{
    static let reuseId = "ConversationListCell"
    fileprivate static var progressViewOriginTintColor:UIColor?
    fileprivate static var progressViewDisappearingTintColor = UIColor.red
    fileprivate static var progressViewTimingTintColor = UIColor.orange
    
    weak override var rootController:ConversationListController!{
        didSet{
            if oldValue == nil && rootController != nil{
                self.addObservers()
            }
        }
    }
    
    @IBOutlet weak var sendingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var timeupProgressView: UIProgressView!{
        didSet{
            if ConversationListCell.progressViewOriginTintColor == nil {
                ConversationListCell.progressViewOriginTintColor = timeupProgressView.progressTintColor
            }else{
                timeupProgressView.progressTintColor = ConversationListCell.progressViewOriginTintColor
            }
        }
    }
    
    @IBOutlet weak var retrySendTaskButton: UIButton!{
        didSet{
            retrySendTaskButton.isHidden = true
        }
    }
    
    @IBOutlet weak var cancelSendButton: UIButton!{
        didSet{
            cancelSendButton.isHidden = true
        }
    }
    
    @IBOutlet weak var pinMark: UIView!{
        didSet{
            pinMark.isHidden = false
            pinMark.layoutIfNeeded()
            pinMark.clipsToBounds = true
            pinMark.layer.cornerRadius = pinMark.frame.height / 2
        }
    }
    
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.layoutIfNeeded()
            badgeLabel.isHidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var avatarView: UIImageView!{
        didSet{
            avatarView.clipsToBounds = true
            avatarView.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var headLineLabel: UILabel!
    @IBOutlet weak var subLineLabel: LTMorphingLabel!{
        didSet{
            subLineLabel.morphingEffect = .pixelate
        }
    }
    
    var conversationListCellHandler:ConversationListCellHandler!
    
    func getUserDistance(_ user:VessageUser!)->Double?{
        if (user?.location?.count ?? 0 ) >= 2 {
            let lat = user.location[1]
            let lon = user.location[0]
            let p2 = CLLocation(latitude: lat, longitude: lon)
            if let p1 = ServiceContainer.getLocationService().here{
                let dis = p1.distance(from: p2)
                return dis
            }
        }
        
        return nil
    }
    
    
    var originModel:AnyObject?{
        didSet{
            timeupProgressView?.isHidden = true
            subLineLabel?.morphingEnabled = true
            pinMark?.isHidden = true
            if let conversation = originModel as? Conversation{
                updateWithConversation(conversation)
            }else if let searchResult = originModel as? SearchResultModel{
                subLineLabel?.morphingEnabled = false
                switch searchResult.type {
                case .userActiveNear:
                    updateWithUser(searchResult.user)
                    var sl = "ACTIVE_NEAR_USER".localizedString()
                    if let dis = getUserDistance(searchResult.user){
                        sl = String(format: "ACTIVE_NEAR_USER_AT_X".localizedString(), Int(dis).friendString)
                    }
                    subLine = sl
                    
                case .userActive:
                    updateWithUser(searchResult.user)
                    subLine = "ACTIVE_USER".localizedString()
                case .userNear:
                    updateWithUser(searchResult.user)
                    var sl = "NEAR_USER".localizedString()
                    if let dis = getUserDistance(searchResult.user){
                        sl = String(format: "NEAR_USER_AT_X".localizedString(), Int(dis).friendString)
                    }
                    subLine = sl
                case .userNormal:updateWithUser(searchResult.user)
                case .mobile:updateWithMobile(searchResult.mobile)
                case .conversation:updateWithConversation(searchResult.conversation)
                default: break
                    
                }
            }
        }
    }
    
    fileprivate var defaultAvatarId = "0"
    fileprivate var sex = 0
    fileprivate var avatar:String!{
        didSet{
            if let imgView = self.avatarView{
                if String.isNullOrEmpty(self.avatar) {
                    imgView.image = getDefaultAvatar(defaultAvatarId,sex: sex)
                }else if let fileId = avatar{
                    if fileId != oldValue {
                        imgView.image = getDefaultAvatar(defaultAvatarId,sex: sex)
                        ServiceContainer.getFileService().getImage(iconFileId: fileId, callback: { (image) in
                            if self.avatar != nil && fileId == self.avatar && image != nil {
                                self.avatarView?.image = image
                            }
                        })
                    }
                }
            }
        }
    }
    
    fileprivate var headLine:String!{
        didSet{
            self.headLineLabel?.text = headLine
        }
    }
    
    fileprivate var subLine:String!{
        didSet{
            self.subLineLabel?.text = subLine
        }
    }
    
    func layoutSubline() {
        subLineLabel.morphingEnabled = true
        let text = subLineLabel.text
        subLineLabel.text = nil
        subLineLabel.text = text
    }

    fileprivate var badgeValue:Int = 0 {
        didSet{
            setBadgeLabelValue(badgeLabel,value: badgeValue)
        }
    }
    
    override func onCellClicked() {
        if let handler = conversationListCellHandler{
            handler(self)
        }
    }
    
    //MARK: Send Task
    @IBAction func retrySend(_ sender: AnyObject) {
        
    }
    
    @IBAction func cancelSend(_ sender: AnyObject) {
        
    }
    
    //MARK: update actions
    fileprivate func updateWithConversation(_ conversation:Conversation){
        
        if let chatterId = conversation.chatterId{
            if conversation.isGroupChat {
                if let group = self.rootController.groupService.getChatGroup(chatterId) {
                    updateWithChatGroup(group)
                }else{
                    let group = ChatGroup()
                    group.groupName = "NEW_GROUP_CHAT".localizedString()
                    group.groupId = chatterId
                    updateWithChatGroup(group)
                    self.rootController.groupService.fetchChatGroup(chatterId)
                }
            }else{
                if let user = rootController.userService.getCachedUserProfile(chatterId){
                    updateWithUser(user)
                }else{
                    let user = VessageUser()
                    user.userId = chatterId
                    updateWithUser(user)
                    self.rootController.userService.fetchUserProfile(chatterId)
                }
            }
        }
        self.subLine = conversation.getDisappearString()
        self.timeupProgressView?.isHidden = false
        if let p = conversation.getConversationTimeUpProgressLeft(){
            self.setTimeProgress(p)
        }
        if conversation.pinned {
            self.setTimeProgress(1)
        }
        pinMark?.isHidden = !conversation.pinned
        
    }
    
    fileprivate func setTimeProgress(_ p:Float){
        self.timeupProgressView?.progress = p
        if p < 0.3 {
            self.timeupProgressView?.progressTintColor = ConversationListCell.progressViewDisappearingTintColor
        }else if p < 0.6{
            self.timeupProgressView?.progressTintColor = ConversationListCell.progressViewTimingTintColor
        }else{
            self.timeupProgressView?.progressTintColor = ConversationListCell.progressViewOriginTintColor
        }
    }
    
    fileprivate func updateWithChatGroup(_ group:ChatGroup){
        self.headLine = group.groupName
        self.avatarView.image = UIImage(named: "group_chat")
        self.badgeValue = self.rootController.vessageService.getChatterNotReadVessageCount(group.groupId)
    }
    
    fileprivate func updateWithUser(_ user:VessageUser){
        self.headLine = self.rootController.userService.getUserNotedNameIfExists(user.userId) ?? user.nickName
        if user.t == VessageUser.typeSubscription {
            self.subLine = "SUBSCRIPTION_ACCUNT".localizedString()
        }else{
            self.subLine = user.accountId
        }
        self.updateAvatarWithUser(user)
        self.badgeValue = self.rootController.vessageService.getChatterNotReadVessageCount(user.userId)
    }
    
    fileprivate func updateWithMobile(_ mobile:String){
        self.headLine = mobile
        let msg = String(format: "OPEN_NEW_CHAT_WITH_MOBILE".localizedString(), mobile)
        self.subLine = msg
        self.avatar = nil
        self.sex = 0
        self.badgeValue = 0
    }
    
    fileprivate func updateAvatarWithUser(_ user:VessageUser){
        if let aId = user.accountId {
            self.defaultAvatarId = aId
        }
        self.sex = user.sex
        if String.isNullOrWhiteSpace(user.avatar) && user.t == VessageUser.typeSubscription {
            self.avatar = "subaccount_icon"
        }else{
            self.avatar = user.avatar
        }
    }
    
    //MARK: notifications
    fileprivate func addObservers(){
        ServiceContainer.getUserService().addObserver(self, selector: #selector(ConversationListCell.onUserNoteNameUpdated(_:)), name: UserService.userNoteNameUpdated, object: nil)
        ServiceContainer.getUserService().addObserver(self, selector: #selector(ConversationListCell.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(ConversationListCell.onVessageReadAndReceived(_:)), name: VessageService.onNewVessageReceived, object: nil)
        ServiceContainer.getVessageService().addObserver(self, selector: #selector(ConversationListCell.onVessageReadAndReceived(_:)), name: VessageService.onVessageRead, object: nil)
        ServiceContainer.getChatGroupService().addObserver(self, selector: #selector(ConversationListCell.onChatGroupUpdated(_:)), name: ChatGroupService.OnChatGroupUpdated, object: nil)
        ServiceContainer.getConversationService().addObserver(self, selector: #selector(ConversationListCell.onConversationUpdated(_:)), name: ConversationService.conversationUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(ConversationListCell.onServicesWillLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
    }
    
    func removeObservers(){
        self.conversationListCellHandler = nil
        ServiceContainer.instance.removeObserver(self)
        ServiceContainer.getChatGroupService().removeObserver(self)
        ServiceContainer.getUserService().removeObserver(self)
        ServiceContainer.getVessageService().removeObserver(self)
        ServiceContainer.getConversationService().removeObserver(self)
    }
    
    func onServicesWillLogout(_ a:Notification) {
        removeObservers()
    }
    
    func onConversationUpdated(_ a:Notification){
        if let conversation = self.originModel as? Conversation{
            if let con = a.userInfo?[ConversationUpdatedValue] as? Conversation{
                if conversation.conversationId == con.conversationId{
                    self.originModel = con
                }
            }
        }
    }
    
    func onChatGroupUpdated(_ a:Notification){
        if let conversation = self.originModel as? Conversation{
            if let g = a.userInfo?[kChatGroupValue] as? ChatGroup{
                if ConversationService.isConversationWithChatGroup(conversation, group: g) {
                    self.updateWithChatGroup(g)
                }
            }
        }
    }
    
    func onUserNoteNameUpdated(_ a:Notification) {
        if let userId = a.userInfo?[UserProfileUpdatedUserIdValue] as? String{
            if userId == (self.originModel as? Conversation)?.chatterId {
                if let note = a.userInfo?[UserNoteNameUpdatedValue] as? String{
                    self.headLine = note
                }
            }
        }
    }
    
    func onUserProfileUpdated(_ a:Notification){
        if let conversation = self.originModel as? Conversation{
            if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
                if ConversationService.isConversationWithUser(conversation, user: user){
                    self.headLine = self.rootController.userService.getUserNotedName(user.userId)
                    updateAvatarWithUser(user)
                }
            }
        }
    }
    
    func onVessageReadAndReceived(_ a:Notification){
        if let conversation = self.originModel as? Conversation{
            if let vsg = a.userInfo?[VessageServiceNotificationValue] as? Vessage{
                if ConversationService.isConversationVessage(conversation, vsg: vsg){
                    self.badgeValue = self.rootController.vessageService.getChatterNotReadVessageCount(conversation.chatterId)
                }
            }
        }
    }
}

