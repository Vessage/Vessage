//
//  UserProfileViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import LTMorphingLabel

class UserProfileViewController: UIViewController {
    private(set) var profile:VessageUser!{
        didSet{
            ServiceContainer.getFileService().setImage(avatarImageView, iconFileId: profile.avatar, defaultImage: getDefaultAvatar(profile.accountId ?? "0"))
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
            mottoLabel.text = profile.motto ?? "DEFAULT_VGER_MOTTO".localizedString()
            sexImageView.hidden = false
            avatarImageView.hidden = false
            ServiceContainer.getUserService().setUserSexImageView(self.sexImageView, sexValue: profile.sex)
        }
    }
    
    @IBOutlet weak var mottoLabel: LTMorphingLabel!{
        didSet{
            mottoLabel.morphingEffect = .Pixelate
        }
    }
    @IBOutlet weak var bcgMaskView: UIView!
    
    @IBOutlet weak var sexImageView: UIImageView!{
        didSet{
            sexImageView.hidden = true
        }
    }
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
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func noteName(sender: AnyObject) {
        ServiceContainer.getUserService().showNoteConversationAlert(self, user: profile)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserProfileViewController.onTapView(_:))))
        ServiceContainer.getUserService().addObserver(self, selector: #selector(UserProfileViewController.onUserNoteNameUpdated(_:)), name: UserService.userNoteNameUpdated, object: nil)
        ServiceContainer.getUserService().addObserver(self, selector: #selector(UserProfileViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
        bcgMaskView.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.bcgMaskView.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.bcgMaskView.hidden = false
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
    
    static func showUserProfileViewController(vc:UIViewController, userProfile:VessageUser){
        let controller = instanceFromStoryBoard("User", identifier: "UserProfileViewController") as! UserProfileViewController
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.modalPresentationStyle = .OverCurrentContext
        vc.presentViewController(controller, animated: true) { 
            controller.profile = userProfile
            ServiceContainer.getUserService().fetchLatestUserProfile(userProfile)
        }
    }
}

//MARK: Show Chatter Profile
extension UserService{
    func showUserProfile(vc:UIViewController,user:VessageUser) {
        UserProfileViewController.showUserProfileViewController(vc, userProfile: user)
    }
    
    private func showNoteConversationAlert(vc:UIViewController,user:VessageUser){
        let title = "NOTE_CONVERSATION_A_NAME".localizedString()
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
            textfield.placeholder = "CONVERSATION_NAME".localizedString()
            textfield.borderStyle = .None
            textfield.text = ServiceContainer.getUserService().getUserNotedName(user.userId)
        })
        
        let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
            let newNoteName = alertController.textFields?[0].text ?? ""
            if String.isNullOrEmpty(newNoteName)
            {
                vc.playToast("NEW_NOTE_NAME_CANT_NULL".localizedString())
            }else{
                if String.isNullOrWhiteSpace(user.userId) == false{
                    ServiceContainer.getUserService().setUserNoteName(user.userId, noteName: newNoteName)
                }
                vc.playCheckMark("SAVE_NOTE_NAME_SUC".localizedString())
            }
        })
        let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
        alertController.addAction(no)
        alertController.addAction(yes)
        vc.showAlert(alertController)
    }
}
