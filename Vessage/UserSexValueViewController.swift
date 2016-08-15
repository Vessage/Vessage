//
//  UserSexValueViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

typealias SaveSexValueHandler = (newValue:Int)->Void

//MARK:UserSexValueViewController
class UserSexValueViewController: UIViewController {
    
    @IBOutlet weak var bcgMaskView: UIView!
    private(set) var sexValue = 0{
        didSet{
            refresh()
        }
    }
    
    var saveSexValueHandler:SaveSexValueHandler?
    
    
    @IBOutlet weak var sexValueSlider: UISlider!
    @IBOutlet weak var sexValueImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sexValueSlider.superview?.layer.cornerRadius = 10
        self.sexValueSlider.superview?.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.sexValueSlider.superview?.layer.borderWidth = 0.3
        bcgMaskView.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.bcgMaskView.hidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.bcgMaskView.hidden = true
    }
    
    private func refresh(){
        sexValueSlider?.value = NSNumber(integer: sexValue).floatValue
        ServiceContainer.getUserService().setUserSexImageView(self.sexValueImageView, sexValue: sexValue)
    }
    
    @IBAction func onSlideChanged(sender: AnyObject) {
        self.sexValue = NSNumber(float: self.sexValueSlider.value).integerValue
    }
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func confirm(sender: AnyObject) {
        let newValue = sexValue
        self.dismissViewControllerAnimated(true, completion: {
            self.saveSexValueHandler?(newValue: newValue)
        })
    }
    
    static func showUserProfileViewController(vc:UIViewController, sexValue:Int,handler:SaveSexValueHandler){
        let controller = instanceFromStoryBoard("User", identifier: "UserSexValueViewController") as! UserSexValueViewController
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.modalPresentationStyle = .OverCurrentContext
        controller.saveSexValueHandler = handler
        vc.presentViewController(controller, animated: true) {
            controller.sexValue = sexValue
        }
    }
}

extension UserService{
    func setUserSexImageView(imageView:UIImageView?,sexValue:Int) {
        if sexValue == 0 {
            imageView?.image = UIImage(named: "sex_middle")
            imageView?.alpha = 1
        }else if sexValue > 0{
            imageView?.image = UIImage(named: "sex_male")
            imageView?.alpha = 0.5 + CGFloat(sexValue) / 100
        }else if sexValue < 0{
            imageView?.image = UIImage(named: "sex_female")
            imageView?.alpha = 0.5 + CGFloat(-1 * sexValue) / 100
        }
    }
}