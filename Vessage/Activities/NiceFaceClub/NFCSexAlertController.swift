//
//  NFCSexViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class NFCSexAlertController:UIViewController{
    
    @IBOutlet weak var preferredSexLabel: UILabel!
    @IBOutlet weak var userProfileSexImageView: UIImageView!
    
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var preferredSexSlider: UISlider!{
        didSet{
            preferredSexSlider.superview?.clipsToBounds = true
            preferredSexSlider.superview?.layer.cornerRadius = 6
            preferredSexSlider.superview?.layer.borderColor = UIColor.orangeColor().CGColor
            preferredSexSlider.superview?.layer.borderWidth = 1
            
            preferredSexSlider.minimumValue = minSexValue
            preferredSexSlider.maximumValue = maxSexValue
        }
    }
    @IBOutlet weak var userProfileSexSlider: UISlider!{
        didSet{
            userProfileSexSlider.minimumValue = minSexValue
            userProfileSexSlider.maximumValue = maxSexValue
        }
    }
    @IBOutlet weak var bcgMaskView: UIView!
    @IBAction func onClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userSexValue = ServiceContainer.getUserService().myProfile.sex
        let preferredSex = NiceFaceClubManager.instance.preferredSex
        setPreferrdSexLabel(preferredSex)
        ServiceContainer.getUserService().setUserSexImageView(self.userProfileSexImageView, sexValue: userSexValue)
        userProfileSexSlider.setValue(Float(userSexValue), animated: true)
        preferredSexSlider.setValue(Float(preferredSex), animated: true)
        checkButton.enabled = false
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
    
    @IBAction func userProfileSexValueChanged(sender: AnyObject) {
        ServiceContainer.getUserService().setUserSexImageView(self.userProfileSexImageView, sexValue: Int(self.userProfileSexSlider.value))
        checkButton.enabled = true
    }
    
    func setPreferrdSexLabel(sex:Int) {
        if sex == 0 {
            preferredSexLabel.textColor = UIColor.orangeColor()
            preferredSexLabel.text = "ALL_MEMBERS".niceFaceClubString
        }else if sex > 0{
            preferredSexLabel.textColor = UIColor.blueColor()
            preferredSexLabel.text = "MALE_MEMBERS".niceFaceClubString
        }else{
            preferredSexLabel.textColor = UIColor.redColor()
            preferredSexLabel.text = "FEMALE_MEMBERS".niceFaceClubString
        }
    }
    
    @IBAction func preferredSexValueChanged(sender: AnyObject) {
        setPreferrdSexLabel(Int(self.preferredSexSlider.value))
        checkButton.enabled = true
    }
    
    @IBAction func saveValues(sender: AnyObject) {
        let hud = self.showAnimationHud()
        ServiceContainer.getUserService().setUserSexValue(Int(self.userProfileSexSlider.value)) { (suc) in
            hud.hideAnimated(true)
            if suc{
                NiceFaceClubManager.instance.updateMyProfileValues()
                let preferredSex = Int(self.preferredSexSlider.value)
                NiceFaceClubManager.instance.preferredSex = preferredSex
                NiceFaceClubManager.instance.updateMyProfileValues()
                self.onClose(sender)
            }else{
                self.playCrossMark("UPDATE_SEX_INFO_ERROR".niceFaceClubString)
            }
        }
        
    }
    
    static func showNFCSexAlert(vc:UIViewController) -> NFCSexAlertController{
        let controller = instanceFromStoryBoard("NiceFaceClub", identifier: "NFCSexAlertController") as! NFCSexAlertController
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.modalPresentationStyle = .OverCurrentContext
        vc.presentViewController(controller, animated: true) {
            
        }
        return controller
    }
}