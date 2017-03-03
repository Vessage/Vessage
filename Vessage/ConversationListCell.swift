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
typealias ConversationListCellHandler = (cell:ConversationListCell)->Void
class ConversationListCell:ConversationListCellBase{
    static let reuseId = "ConversationListCell"
    private static var progressViewOriginTintColor:UIColor?
    private static var progressViewDisappearingTintColor = UIColor.redColor()
    private static var progressViewTimingTintColor = UIColor.orangeColor()
    
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
            retrySendTaskButton.hidden = true
        }
    }
    
    @IBOutlet weak var cancelSendButton: UIButton!{
        didSet{
            cancelSendButton.hidden = true
        }
    }
    
    @IBOutlet weak var pinMark: UIView!{
        didSet{
            pinMark.hidden = false
            pinMark.layoutIfNeeded()
            pinMark.clipsToBounds = true
            pinMark.layer.cornerRadius = pinMark.frame.height / 2
        }
    }
    
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.layoutIfNeeded()
            badgeLabel.hidden = true
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
            subLineLabel.morphingEffect = .Pixelate
        }
    }
    
    var conversationListCellHandler:ConversationListCellHandler!
    
    func getUserDistance(user:VessageUser!)->Double?{
        if (user?.location?.count ?? 0 ) >= 2 {
            let lat = user.location[1]
            let lon = user.location[0]
            let p2 = CLLocation(latitude: lat, longitude: lon)
            if let p1 = ServiceContainer.getLocationService().here{
                let dis = p1.distanceFromLocation(p2)
                return dis
            }
        }
        
        return nil
    }
    
    
    var originModel:AnyObject?{
        didSet{
            timeupProgressView?.hidden = true
            subLineLabel?.morphingEnabled = true
            pinMark?.hidden = true
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
    
    private var defaultAvatarId = "0"
    private var sex = 0
    private var avatar:String!{
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
    
    func layoutSubline() {
        subLineLabel.morphingEnabled = true
        let text = subLineLabel.text
        subLineLabel.text = nil
        subLineLabel.text = text
    }

    private var badgeValue:Int = 0 {
        didSet{
            setBadgeLabelValue(badgeLabel,value: badgeValue)
        }
    }
    
    override func onCellClicked() {
        if let handler = conversationListCellHandler{
            handler(cell: self)
        }
    }
    
    //MARK: Send Task
    @IBAction func retrySend(sender: AnyObject) {
        
    }
    
    @IBAction func cancelSend(sender: AnyObject) {
        
    }
    
    //MARK: update actions
    private func updateWithConversation(conversation:Conversation){
        
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
        let minLeft = NSNumber(double:conversation.getConversationTimeUpMinutesLeft()).integerValue
        if !conversation.pinned && (minLeft < Int(ConversationMaxTimeUpMinutes / 2) || minLeft % 3 != 0) {
            self.subLine = conversation.getDisappearString()
        }else{
            self.subLine = conversation.getLastUpdatedTime().toFriendlyString()
        }
        self.timeupProgressView?.hidden = false
        if let p = conversation.getConversationTimeUpProgressLeft(){
            self.setTimeProgress(p)
        }
        if conversation.pinned {
            self.setTimeProgress(1)
        }
        pinMark?.hidden = !conversation.pinned
        
    }
    
    private func setTimeProgress(p:Float){
        self.timeupProgressView?.progress = p
        if p < 0.3 {
            self.timeupProgressView?.progressTintColor = ConversationListCell.progressViewDisappearingTintColor
        }else if p < 0.6{
            self.timeupProgressView?.progressTintColor = ConversationListCell.progressViewTimingTintColor
        }else{
            self.timeupProgressView?.progressTintColor = ConversationListCell.progressViewOriginTintColor
        }
    }
    
    private func updateWithChatGroup(group:ChatGroup){
        self.headLine = group.groupName
        self.avatarView.image = UIImage(named: "group_chat")
        self.badgeValue = self.rootController.vessageService.getChatterNotReadVessageCount(group.groupId)
    }
    
    private func updateWithUser(user:VessageUser){
        self.headLine = self.rootController.userService.getUserNotedNameIfExists(user.userId) ?? user.nickName
        self.subLine = user.accountId
        self.updateAvatarWithUser(user)
        self.badgeValue = self.rootController.vessageService.getChatterNotReadVessageCount(user.userId)
    }
    
    private func updateWithMobile(mobile:String){
        self.headLine = mobile
        let msg = String(format: "OPEN_NEW_CHAT_WITH_MOBILE".localizedString(), mobile)
        self.subLine = msg
        self.avatar = nil
        self.sex = 0
        self.badgeValue = 0
    }
    
    private func updateAvatarWithUser(user:VessageUser){
        if let aId = user.accountId {
            self.defaultAvatarId = aId
        }
        self.sex = user.sex
        self.avatar = user.avatar
    }
    
    //MARK: notifications
    private func addObservers(){
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
    
    func onChatGroupUpdated(a:NSNotification){
        if let conversation = self.originModel as? Conversation{
            if let g = a.userInfo?[kChatGroupValue] as? ChatGroup{
                if ConversationService.isConversationWithChatGroup(conversation, group: g) {
                    self.updateWithChatGroup(g)
                }
            }
        }
    }
    
    func onUserNoteNameUpdated(a:NSNotification) {
        if let userId = a.userInfo?[UserProfileUpdatedUserIdValue] as? String{
            if userId == (self.originModel as? Conversation)?.chatterId {
                if let note = a.userInfo?[UserNoteNameUpdatedValue] as? String{
                    self.headLine = note
                }
            }
        }
    }
    
    func onUserProfileUpdated(a:NSNotification){
        if let conversation = self.originModel as? Conversation{
            if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
                if ConversationService.isConversationWithUser(conversation, user: user){
                    self.headLine = self.rootController.userService.getUserNotedName(user.userId)
                    updateAvatarWithUser(user)
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

