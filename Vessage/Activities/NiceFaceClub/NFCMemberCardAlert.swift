//
//  NFCMessageAlert.swift
//  Vessage
//
//  Created by AlexChow on 16/8/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class NFCMemberCardAlert:UIViewController{
    
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
        
    }
    
    func onTapBagMask(_:UITapGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
