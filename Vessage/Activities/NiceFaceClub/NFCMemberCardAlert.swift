//
//  NFCMessageAlert.swift
//  Vessage
//
//  Created by AlexChow on 16/8/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class NFCMemberCardAlert:UIViewController{
    
    @IBOutlet weak var faceScoreLabel: UILabel!{
        didSet{
            faceScoreLabel.superview?.layoutIfNeeded()
            faceScoreLabel.superview?.userInteractionEnabled = true
            faceScoreLabel.superview?.clipsToBounds = true
            faceScoreLabel.superview?.layer.cornerRadius = faceScoreLabel.superview!.frame.height / 2
            self.faceScoreLabel.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMemberCardAlert.onTapImage(_:))))
        }
    }
    var chatable:Bool{
        if let profile = NiceFaceClubManager.instance.myNiceFaceProfile{
            return profile.isAnonymous() == false && profile.mbId != profileId
        }
        return false
    }
    var editable:Bool{
        if let mbId = NiceFaceClubManager.instance.myNiceFaceProfile?.mbId{
            return mbId == profileId
        }
        return false
    }
    
    
    @IBOutlet weak var sexImage: UIImageView!
    @IBOutlet weak var mottoLabel: UILabel!
    @IBOutlet weak var nickLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!{
        didSet{
            likesLabel.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NFCMemberCardAlert.onTapCard(_:))))
        }
    }
    @IBOutlet weak var faceProgress: KDCircularProgress!
    @IBOutlet weak var imageView: UIImageView!{
        didSet{
            imageView.layoutIfNeeded()
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
            imageView.layer.cornerRadius = imageView.frame.height / 2
            imageView.layer.borderWidth = 0.6
            imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
            imageView.superview?.layer.cornerRadius = 10
            
        }
    }
    @IBOutlet weak var bcgMaskView: UIView!{
        didSet{
            bcgMaskView?.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMemberCardAlert.onTapBagMask(_:))))
        }
    }
    
    private var profileId:String!{
        didSet{
            if oldValue != profileId {
                NiceFaceClubManager.instance.getUserProfile(profileId, callback: { (profile) in
                    if let p = profile {
                        self.updateCardView(p)
                    }else{
                        self.noProfileLoaded()
                    }
                })
            }
        }
    }
    
    private func noProfileLoaded(){
        let iSee = UIAlertAction(title: "I_SEE".localizedString(), style: .Cancel) { (ac) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.showAlert("NFC".niceFaceClubString, msg: "NO_PROFILE_LOADED".niceFaceClubString, actions: [iSee])
    }
    
    private func updateCardView(profile:UserNiceFaceProfile){
        ServiceContainer.getFileService().setImage(self.imageView, iconFileId: profile.faceId)
        self.nickLabel.text = profile.nick
        ServiceContainer.getUserService().setUserSexImageView(self.sexImage, sexValue: profile.sex)
        self.likesLabel.text = "\(profile.likes)"
        let angle = Double(360 * profile.score / 10)
        self.faceProgress.animateToAngle(angle, duration: 0.3, completion: nil)
        self.mottoLabel.text = ServiceContainer.getUserService().myProfile.motto ?? "DEFAULT_MOTTO".niceFaceClubString
        self.faceScoreLabel.text = "\(profile.score)"
        self.faceProgress.superview?.hidden = false
    }
    
    private func modifyNiceFace(aleadyMember:Bool = true){
        let controller = SetupNiceFaceViewController.instanceFromStoryBoard()
        self.presentViewController(controller, animated: true){
            if aleadyMember{
                NFCMessageAlert.showNFCMessageAlert(controller, title: "NICE_FACE_CLUB".niceFaceClubString, message: "UPDATE_YOUR_NICE_FACE".niceFaceClubString)
            }
        }
    }
    
    func onTapCard(ges:UITapGestureRecognizer) {
        var actions = [UIAlertAction]()
        
        if editable {
            let modifyNiceFace = UIAlertAction(title: "MODIFY_NICE_FACE".niceFaceClubString, style: .Default) { (ac) in
                self.modifyNiceFace()
            }
            let userSettig = UIAlertAction(title: "UPDATE_MEMBER_PROFILE".niceFaceClubString, style: .Default) { (ac) in
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                UserSettingViewController.showUserSettingViewController(self.navigationController!)
            }
            actions.append(modifyNiceFace)
            actions.append(userSettig)
        }
        
        if chatable {
            let chatAction = UIAlertAction(title: "CHAT_WITH_TA".niceFaceClubString, style: .Default, handler: { (ac) in
                self.chatWithMember()
            })
            actions.append(chatAction)
        }
        
        if actions.count > 0 {
            actions.append(ALERT_ACTION_CANCEL)
            let alertController = UIAlertController.create(title: nickLabel.text, message: nil, preferredStyle: .ActionSheet)
            actions.forEach{alertController.addAction($0)}
            self.showAlert(alertController)
        }
    }
    
    private func chatWithMember(){
        let hud = self.showActivityHud()
        NFCPostManager.instance.chatMember(self.profileId, callback: { (userId) in
            hud.hideAnimated(true)
            if String.isNullOrWhiteSpace(userId){
                self.playCrossMark("NO_MEMBER_USERID_FOUND".niceFaceClubString)
            }else{
                
                let msg:[String:AnyObject]? = ServiceContainer.getConversationService().existsConversationOfUserId(userId!) ? nil : ["input_text":"NFC_HELLO".niceFaceClubString]
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                ConversationViewController.showConversationViewController(self.navigationController!, userId: userId!,createByActivityId:NFCPostManager.activityId,initMessage: msg)
            }
        })
    }
    
    func onTapImage(ges:UITapGestureRecognizer) {
        self.imageView.slideShowFullScreen(self)
    }
    
    func onTapBagMask(_:UITapGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.superview?.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        bcgMaskView.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        bcgMaskView.hidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        bcgMaskView.hidden = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    static func showNFCMemberCardAlert(vc:UIViewController, memberId:String) -> NFCMemberCardAlert{
        let controller = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCMemberCardAlert") as! NFCMemberCardAlert
        let nvc = UINavigationController(rootViewController: controller)
        nvc.setNavigationBarHidden(true, animated: false)
        nvc.providesPresentationContextTransitionStyle = true
        nvc.definesPresentationContext = true
        nvc.modalPresentationStyle = .OverCurrentContext
        vc.presentViewController(nvc, animated: true) {
            controller.profileId = memberId
        }
        return controller
    }
}
