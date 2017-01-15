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
    func userProfileViewController(sender:UserProfileViewController,rightButtonTitle profile:VessageUser) -> String
    func userProfileViewController(sender:UserProfileViewController,rightButtonClicked profile:VessageUser)
}

protocol UserProfileViewControllerDismissedDelegate:UserProfileViewControllerDelegate {
    func userProfileViewControllerDismissed(sender:UserProfileViewController)
}

class UserProfileViewControllerDelegateOpenConversation : UserProfileViewControllerDelegate{
    
    var operateTitle:String?
    
    
    var initMessage:[String:AnyObject]?
    
    var beforeRemoveTimeSpan:Int64 = ConversationMaxTimeUpMS
    
    var createActivityId:String? = nil
    
    
    func userProfileViewController(sender: UserProfileViewController, rightButtonClicked profile: VessageUser) {
        if let nvc = sender.navigationController{
            ConversationViewController.showConversationViewController(nvc, userId: profile.userId,beforeRemoveTs: beforeRemoveTimeSpan,createByActivityId: createActivityId, initMessage: initMessage)
        }
    }
    
    func userProfileViewController(sender: UserProfileViewController, rightButtonTitle profile: VessageUser) -> String {
        return operateTitle ?? "CHAT".localizedString()
    }
}

private let NoteUserDelegate = UserProfileViewControllerDelegateNoteUser()
class UserProfileViewControllerDelegateNoteUser : UserProfileViewControllerDelegate{
    func userProfileViewController(sender: UserProfileViewController, rightButtonClicked profile: VessageUser) {
        ServiceContainer.getUserService().showNoteConversationAlert(sender, user: profile)
    }
    
    func userProfileViewController(sender: UserProfileViewController, rightButtonTitle profile: VessageUser) -> String {
        return "NOTE".localizedString()
    }
}

class UserProfileViewController: UIViewController {
    var delegate:UserProfileViewControllerDelegate?{
        didSet{
            updateRightButtonTitle()
        }
    }
    
    var accountIdHidden:Bool = false{
        didSet{
            accountIdLabel?.hidden = accountIdHidden
        }
    }
    
    var snsButtonEnable:Bool = true{
        didSet{
            snsButton?.enabled = snsButtonEnable
        }
    }
    
    
    private(set) var profile:VessageUser!{
        didSet{
            let img = getDefaultAvatar(profile.accountId ?? "0",sex:profile.sex)
            ServiceContainer.getFileService().setImage(avatarImageView, iconFileId: profile.avatar, defaultImage: img)
            if let aId = profile.accountId {
                self.accountIdLabel.text = String(format: "USER_ACCOUNT_FORMAT".localizedString(),aId)
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
            self.accountIdLabel.hidden = accountIdHidden
            mottoLabel.text = profile.motto ?? "DEFAULT_VGER_MOTTO".localizedString()
            sexImageView.superview?.hidden = false
            avatarImageView.hidden = false
            ServiceContainer.getUserService().setUserSexImageView(self.sexImageView, sexValue: profile.sex)
            updateRightButtonTitle()
        }
    }
    
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var mottoLabel: LTMorphingLabel!{
        didSet{
            mottoLabel.morphingEffect = .Pixelate
        }
    }
    @IBOutlet weak var bcgMaskView: UIView!
    
    @IBOutlet weak var snsButton: UIButton!
    @IBOutlet weak var sexImageView: UIImageView!
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.borderWidth = 0.6
            avatarImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
            avatarImageView.superview?.layer.borderWidth = 0.1
            avatarImageView.superview?.layer.borderColor = UIColor.lightGrayColor().CGColor
            avatarImageView.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserProfileViewController.onTapAlertContainer(_:))))
            avatarImageView.hidden = true
            avatarImageView.userInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(UserProfileViewController.onTapImage(_:))))
        }
    }
    
    @IBOutlet weak var accountIdLabel: LTMorphingLabel!{
        didSet{
            accountIdLabel.morphingEffect = .Pixelate
            accountIdLabel.text = nil
            accountIdLabel.hidden = accountIdHidden
        }
    }
    @IBOutlet weak var nameLabel: LTMorphingLabel!{
        didSet{
            nameLabel.morphingEffect = .Pixelate
            nameLabel.text = nil
        }
    }
    
    @IBAction func back(sender: AnyObject) {
        ServiceContainer.getUserService().removeObserver(self)
        self.dismissViewControllerAnimated(true){
            if let handler = self.delegate as? UserProfileViewControllerDismissedDelegate {
                handler.userProfileViewControllerDismissed(self)
            }
        }
    }
    
    @IBAction func onClickRightButton(sender: AnyObject) {
        delegate?.userProfileViewController(self, rightButtonClicked: profile)
    }
    
    @IBAction func onClickSns(sender: AnyObject) {
        if let nvc = self.navigationController,let userId = self.profile?.userId{
            SNSMainViewController.showUserSNSPostViewController(nvc, userId: userId,nick: ServiceContainer.getUserService().getUserNotedName(userId))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserProfileViewController.onTapView(_:))))
        ServiceContainer.getUserService().addObserver(self, selector: #selector(UserProfileViewController.onUserNoteNameUpdated(_:)), name: UserService.userNoteNameUpdated, object: nil)
        ServiceContainer.getUserService().addObserver(self, selector: #selector(UserProfileViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        bcgMaskView.hidden = true
        sexImageView.superview?.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
        var attr = [String:AnyObject]()
        attr.updateValue(UIColor.themeColor, forKey: NSForegroundColorAttributeName)
        self.navigationController?.navigationBar.titleTextAttributes = attr
        updateRightButtonTitle()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.bcgMaskView.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.bcgMaskView.hidden = false
    }
    
    private func updateRightButtonTitle() {
        if let d = delegate {
            if let p = profile {
                rightButton?.setTitle(d.userProfileViewController(self, rightButtonTitle: p), forState: .Normal)
            }
        }
    }
    
    func onTapAlertContainer(a:UITapGestureRecognizer) {
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        avatarImageView.slideShowFullScreen(self)
    }
    
    func onTapView(a:UITapGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onUserNoteNameUpdated(a:NSNotification) {
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
    
    func onUserProfileUpdated(a:NSNotification) {
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
    
    static func showUserProfileViewController(vc:UIViewController,userId:String,delegate:UserProfileViewControllerDelegate = NoteUserDelegate,callback:((UserProfileViewController)->Void)? = nil){
        if let user = ServiceContainer.getUserService().getCachedUserProfile(userId){
            let c = UserProfileViewController.showUserProfileViewController(vc, userProfile: user,delegate: delegate)
            callback?(c)
        }else{
            let hud = vc.showActivityHud()
            ServiceContainer.getUserService().getUserProfile(userId, updatedCallback: { (user) in
                hud.hideAnimated(true)
                if let u = user{
                    let c = UserProfileViewController.showUserProfileViewController(vc, userProfile: u,delegate: delegate)
                    callback?(c)
                }else{
                    vc.playCrossMark("NO_SUCH_USER".localizedString())
                }
            })
        }
    }
    
    static func showUserProfileViewController(vc:UIViewController, userProfile:VessageUser,delegate:UserProfileViewControllerDelegate = NoteUserDelegate) -> UserProfileViewController{
        let controller = instanceFromStoryBoard("User", identifier: "UserProfileViewController") as! UserProfileViewController
        let nvc = UINavigationController(rootViewController: controller)
        nvc.providesPresentationContextTransitionStyle = true
        nvc.definesPresentationContext = true
        nvc.modalPresentationStyle = .OverCurrentContext
        controller.delegate = delegate
        vc.presentViewController(nvc, animated: true) {
            controller.profile = userProfile
            ServiceContainer.getUserService().setForeceGetUserProfileIgnoreTimeLimit()
            ServiceContainer.getUserService().fetchLatestUserProfile(userProfile)
        }
        return controller
    }
}

//MARK: Show Chatter Profile
extension UserService:UIEditTextPropertyViewControllerDelegate{
    func editPropertySave(sender: UIEditTextPropertyViewController, propertyIdentifier: String!, newValue: String!, userInfo: [String : AnyObject?]?) {
        if let userid = userInfo?["userid"] as? String,let newNoteName = newValue{
            setUserNoteName(userid, noteName: newNoteName)
        }
    }
}

extension UserService{
    func showUserProfile(vc:UIViewController,user:VessageUser,delegate:UserProfileViewControllerDelegate = NoteUserDelegate) -> UserProfileViewController {
        return UserProfileViewController.showUserProfileViewController(vc, userProfile: user,delegate: delegate)
    }
    
    private func showNoteConversationAlert(vc:UIViewController,user:VessageUser){
        let property = UIEditTextPropertySet()
        property.illegalValueMessage = "NEW_NOTE_NAME_CANT_NULL".localizedString()
        property.isOneLineValue = true
        property.propertyValue = ServiceContainer.getUserService().getUserNotedNameIfExists(user.userId) ?? user.nickName ?? user.accountId!
        
        property.propertyIdentifier = "NOTE_USER_NAME"
        
        property.propertyLabel = "CONVERSATION_NAME".localizedString()
        property.valueRegex = "^.{1,20}$"
        property.userInfo = ["userid":user.userId]
        let title = String(format: "NOTE_X_NAME".localizedString(),user.nickName ?? user.accountId ?? property.propertyValue)
        UIEditTextPropertyViewController.showEditPropertyViewController(vc.navigationController!, propertySet: property, controllerTitle: title, delegate: self)
    }
}
