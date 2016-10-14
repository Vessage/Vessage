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
            faceScoreLabel.superview?.clipsToBounds = true
            faceScoreLabel.superview?.layer.cornerRadius = faceScoreLabel.superview!.frame.height / 2
        }
    }
    @IBOutlet weak var sexImage: UIImageView!
    @IBOutlet weak var mottoLabel: UILabel!
    @IBOutlet weak var nickLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
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
            self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(NFCMemberCardAlert.onTapImage(_:))))
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
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.modalPresentationStyle = .OverCurrentContext
        vc.presentViewController(controller, animated: true) {
            controller.profileId = memberId
        }
        return controller
    }
}
