//
//  UserProfileViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import LTMorphingLabel

protocol UserProfileViewControllerDelegate {
    func userProfileViewController(_ sender:UserProfileViewController,rightButtonTitle profile:VessageUser) -> String
    func userProfileViewController(_ sender:UserProfileViewController,rightButtonClicked profile:VessageUser)
}

protocol UserProfileViewControllerDismissedDelegate:UserProfileViewControllerDelegate {
    func userProfileViewControllerDismissed(_ sender:UserProfileViewController)
}

class UserProfileViewControllerDelegateOpenConversation : UserProfileViewControllerDelegate{
    
    var operateTitle:String?
    
    var initMessage:[String:Any]?
    
    var beforeRemoveTimeSpan:Int64 = ConversationMaxTimeUpMS
    
    var createActivityId:String? = nil
    
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonClicked profile: VessageUser) {
        if let nvc = sender.navigationController{
            ConversationViewController.showConversationViewController(nvc, userId: profile.userId,beforeRemoveTs: beforeRemoveTimeSpan,createByActivityId: createActivityId, initMessage: initMessage)
        }
    }
    
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonTitle profile: VessageUser) -> String {
        if !String.isNullOrWhiteSpace(operateTitle) {
            return operateTitle!
        }
        if profile.t == VessageUser.typeSubscription {
            return "SUBSCRIPT".localizedString()
        }
        return "CHAT".localizedString()
    }
}

private let NoteUserDelegate = UserProfileViewControllerDelegateNoteUser()
class UserProfileViewControllerDelegateNoteUser : UserProfileViewControllerDelegate{
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonClicked profile: VessageUser) {
        ServiceContainer.getUserService().showNoteConversationAlert(sender, user: profile)
    }
    
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonTitle profile: VessageUser) -> String {
        return "NOTE".localizedString()
    }
}

class UserProfileViewControllerDelegateAddConversation: UserProfileViewControllerDelegate {
    var beforeRemoveTimeSpan:Int64 = ConversationMaxTimeUpMS
    var createActivityId:String? = nil
    
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonClicked profile: VessageUser) {
        if ServiceContainer.getConversationService().existsConversationOfUserId(profile.userId){
            sender.showAlert("CONVERSATION_EXISTS".localizedString(),msg:nil)
            sender.rightButtonEnabled = false
        }else{
            let type = profile.t == VessageUser.typeSubscription ? Conversation.typeSubscription : Conversation.typeSingleChat
            ServiceContainer.getConversationService().openConversationByUserId(profile.userId, beforeRemoveTs: beforeRemoveTimeSpan, createByActivityId: createActivityId,type: type)
            sender.showAlert("CONVERSATION_CREATED".localizedString(),msg:nil)
            sender.rightButtonEnabled = false
        }
    }
    
    func userProfileViewController(_ sender: UserProfileViewController, rightButtonTitle profile: VessageUser) -> String {
        return "ADD_TO_CONVERSATION_LIST".localizedString()
    }
}

class UserProfileViewController: UIViewController {
    var delegate:UserProfileViewControllerDelegate?{
        didSet{
            updateRightButtonTitle()
        }
    }
    
    var accountIdHidden:Bool = true{
        didSet{
            accountIdLabel?.isHidden = accountIdHidden
        }
    }
    
    var snsButtonEnabled:Bool = false{
        didSet{
            updateSNSButton()
        }
    }
    
    var rightButtonEnabled:Bool = true{
        didSet{
            rightButton?.isEnabled = rightButtonEnabled
        }
    }
    
    
    func updateSNSButton() {
        snsButton?.isEnabled = snsButtonEnabled
    }
    
    
    fileprivate(set) var profile:VessageUser!{
        didSet{
            let img = getDefaultAvatar(profile.accountId ?? "0",sex:profile.sex)
            ServiceContainer.getFileService().setImage(avatarImageView, iconFileId: profile.avatar, defaultImage: img)
            if let aId = profile.accountId {
                let format = profile.t == VessageUser.typeSubscription ? "SUBSCRIPTION_ACCOUNT_FORMAT".localizedString() : "USER_ACCOUNT_FORMAT".localizedString()
                self.accountIdLabel.text = String(format: format,aId)
                var name = profile.nickName
                if let note = ServiceContainer.getUserService().getUserNotedNameIfExists(profile.userId) {
                    if note != name {
                        name = "\(name)(\(note))"
                    }
                }
                self.nameLabel.text = name
            }else{
                self.accountIdLabel.text = "MOBILE_USER".localizedString()
                self.nameLabel.text = ServiceContainer.getUserService().getUserNotedName(profile.userId)
            }
            if profile.t == VessageUser.typeSubscription {
                self.accountIdLabel.isHidden = false
            }else{
                self.accountIdLabel.isHidden = accountIdHidden
            }
            mottoLabel.text = profile.motto ?? "DEFAULT_VGER_MOTTO".localizedString()
            sexImageView.superview?.isHidden = false
            avatarImageView.isHidden = false
            ServiceContainer.getUserService().setUserSexImageView(self.sexImageView, sexValue: profile.sex)
            updateRightButtonTitle()
        }
    }
    
    @IBOutlet weak var rightButton: UIButton!{
        didSet{
            rightButton?.isEnabled = rightButtonEnabled
        }
    }
    @IBOutlet weak var mottoLabel: UILabel!
    @IBOutlet weak var bcgMaskView: UIView!
    
    @IBOutlet weak var snsButton: UIButton!{
        didSet{
            updateSNSButton()
        }
    }
    
    @IBOutlet weak var sexImageView: UIImageView!
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.borderWidth = 0.6
            avatarImageView.layer.borderColor = UIColor.lightGray.cgColor
            avatarImageView.superview?.layer.borderWidth = 0.1
            avatarImageView.superview?.layer.borderColor = UIColor.lightGray.cgColor
            avatarImageView.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserProfileViewController.onTapAlertContainer(_:))))
            avatarImageView.isHidden = true
            avatarImageView.isUserInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(UserProfileViewController.onTapImage(_:))))
        }
    }
    
    @IBOutlet weak var accountIdLabel: LTMorphingLabel!{
        didSet{
            accountIdLabel.morphingEffect = .pixelate
            accountIdLabel.text = nil
            accountIdLabel.isHidden = accountIdHidden
        }
    }
    
    @IBOutlet weak var nameLabel: LTMorphingLabel!{
        didSet{
            nameLabel.morphingEffect = .pixelate
            nameLabel.text = nil
        }
    }
    
    @IBAction func back(_ sender: AnyObject) {
        ServiceContainer.getUserService().removeObserver(self)
        self.dismiss(animated: true){
            if let handler = self.delegate as? UserProfileViewControllerDismissedDelegate {
                handler.userProfileViewControllerDismissed(self)
            }
        }
    }
    
    @IBAction func onClickRightButton(_ sender: AnyObject) {
        delegate?.userProfileViewController(self, rightButtonClicked: profile)
    }
    
    @IBAction func onClickSns(_ sender: AnyObject) {
        if let nvc = self.navigationController,let userId = self.profile?.userId{
            SNSMainViewController.showUserSNSPostViewController(nvc, userId: userId,nick: ServiceContainer.getUserService().getUserNotedName(userId))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserProfileViewController.onTapView(_:))))
        ServiceContainer.getUserService().addObserver(self, selector: #selector(UserProfileViewController.onUserNoteNameUpdated(_:)), name: UserService.userNoteNameUpdated, object: nil)
        ServiceContainer.getUserService().addObserver(self, selector: #selector(UserProfileViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        bcgMaskView.isHidden = true
        sexImageView.superview?.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        var attr = [String:AnyObject]()
        attr.updateValue(UIColor.themeColor, forKey: NSForegroundColorAttributeName)
        self.navigationController?.navigationBar.titleTextAttributes = attr
        updateRightButtonTitle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bcgMaskView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.bcgMaskView.isHidden = false
    }
    
    fileprivate func updateRightButtonTitle() {
        if let d = delegate {
            if let p = profile {
                rightButton?.setTitle(d.userProfileViewController(self, rightButtonTitle: p), for: UIControlState())
            }
        }
    }
    
    func onTapAlertContainer(_ a:UITapGestureRecognizer) {
    }
    
    func onTapImage(_ ges:UITapGestureRecognizer) {
        avatarImageView.slideShowFullScreen(self)
    }
    
    func onTapView(_ a:UITapGestureRecognizer) {
        back(a)
    }
    
    func onUserNoteNameUpdated(_ a:Notification) {
        if let userId = a.userInfo?[UserProfileUpdatedUserIdValue] as? String{
            if userId == profile.userId {
                if let note = a.userInfo?[UserNoteNameUpdatedValue] as? String{
                    if profile.nickName != note {
                        self.nameLabel.text = "\(profile.nickName)(\(note))"
                    }else{
                        self.nameLabel.text = profile.nickName
                    }
                }
            }
        }
    }
    
    func onUserProfileUpdated(_ a:Notification) {
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if profile != nil && user.userId == profile.userId {
                self.profile = user
            }
        }
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    static func showUserProfileViewController(_ vc:UIViewController,userId:String,delegate:UserProfileViewControllerDelegate = NoteUserDelegate,callback:((UserProfileViewController)->Void)? = nil){
        if let user = ServiceContainer.getUserService().getCachedUserProfile(userId){
            let c = UserProfileViewController.showUserProfileViewController(vc, userProfile: user,delegate: delegate)
            callback?(c)
        }else{
            let hud = vc.showActivityHud()
            ServiceContainer.getUserService().getUserProfile(userId, updatedCallback: { (user) in
                hud.hide(animated: true)
                if let u = user{
                    let c = UserProfileViewController.showUserProfileViewController(vc, userProfile: u,delegate: delegate)
                    callback?(c)
                }else{
                    vc.playCrossMark("NO_SUCH_USER".localizedString())
                }
            })
        }
    }
    
    @discardableResult
    static func showUserProfileViewController(_ vc:UIViewController, userProfile:VessageUser,delegate:UserProfileViewControllerDelegate = NoteUserDelegate) -> UserProfileViewController{
        let controller = instanceFromStoryBoard("User", identifier: "UserProfileViewController") as! UserProfileViewController
        let nvc = UINavigationController(rootViewController: controller)
        nvc.providesPresentationContextTransitionStyle = true
        nvc.definesPresentationContext = true
        nvc.modalPresentationStyle = .overCurrentContext
        controller.delegate = delegate
        vc.present(nvc, animated: true) {
            controller.profile = userProfile
            ServiceContainer.getUserService().setForeceGetUserProfileIgnoreTimeLimit()
            ServiceContainer.getUserService().fetchLatestUserProfile(userProfile)
        }
        return controller
    }
}

//MARK: Show Chatter Profile
extension UserService:UIEditTextPropertyViewControllerDelegate{
    func editPropertySave(_ sender: UIEditTextPropertyViewController, propertyIdentifier: String!, newValue: String!, userInfo: [String : AnyObject?]?) {
        if let userid = userInfo?["userid"] as? String,let newNoteName = newValue{
            setUserNoteName(userid, noteName: newNoteName)
        }
    }
}

extension UserService{
    func showUserProfile(_ vc:UIViewController,user:VessageUser,delegate:UserProfileViewControllerDelegate = NoteUserDelegate) -> UserProfileViewController {
        return UserProfileViewController.showUserProfileViewController(vc, userProfile: user,delegate: delegate)
    }
    
    fileprivate func showNoteConversationAlert(_ vc:UIViewController,user:VessageUser){
        let property = UIEditTextPropertySet()
        property.illegalValueMessage = "NEW_NOTE_NAME_CANT_NULL".localizedString()
        property.isOneLineValue = true
        property.propertyValue = ServiceContainer.getUserService().getUserNotedNameIfExists(user.userId) ?? user.nickName ?? user.accountId!
        
        property.propertyIdentifier = "NOTE_USER_NAME"
        
        property.valueTextViewHolder = "CONVERSATION_NAME".localizedString()
        property.valueRegex = "^.{1,20}$"
        property.userInfo = ["userid":user.userId as Optional<AnyObject>]
        let title = String(format: "NOTE_X_NAME".localizedString(),user.nickName ?? user.accountId ?? property.propertyValue)
        UIEditTextPropertyViewController.showEditPropertyViewController(vc.navigationController!, propertySet: property, controllerTitle: title, delegate: self)
    }
}
