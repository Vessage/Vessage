//
//  UserSexValueViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

typealias SaveSexValueHandler = (_ newValue:Int)->Void
let maxSexValue:Float = 100
let minSexValue:Float = -100

//MARK:UserSexValueViewController
class UserSexValueViewController: UIViewController {
    
    @IBOutlet weak var bcgMaskView: UIView!
    fileprivate var originValue = 0
    fileprivate(set) var sexValue = 0{
        didSet{
            refresh()
        }
    }
    @IBOutlet weak var saveButton: UIButton!
    
    var saveSexValueHandler:SaveSexValueHandler?
    
    
    @IBOutlet weak var sexValueSlider: UISlider!{
        didSet{
            sexValueSlider.minimumValue = minSexValue
            sexValueSlider.maximumValue = maxSexValue
        }
    }
    @IBOutlet weak var sexValueImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sexValueSlider.superview?.layer.cornerRadius = 10
        self.sexValueSlider.superview?.layer.borderColor = UIColor.lightGray.cgColor
        self.sexValueSlider.superview?.layer.borderWidth = 0.3
        bcgMaskView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.bcgMaskView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bcgMaskView.isHidden = true
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    fileprivate func refresh(){
        sexValueSlider?.value = NSNumber(value: sexValue as Int).floatValue
        ServiceContainer.getUserService().setUserSexImageView(self.sexValueImageView, sexValue: sexValue)
        saveButton?.isEnabled = originValue != sexValue
    }
    
    @IBAction func onSlideChanged(_ sender: AnyObject) {
        self.sexValue = NSNumber(value: self.sexValueSlider.value as Float).intValue
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirm(_ sender: AnyObject) {
        let newValue = sexValue
        self.dismiss(animated: true, completion: {
            self.saveSexValueHandler?(newValue)
        })
    }
    
    static func showSexValueViewController(_ vc:UIViewController, sexValue:Int,handler:@escaping SaveSexValueHandler){
        let controller = instanceFromStoryBoard("User", identifier: "UserSexValueViewController") as! UserSexValueViewController
        controller.originValue = sexValue
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.modalPresentationStyle = .overCurrentContext
        controller.saveSexValueHandler = handler
        vc.present(controller, animated: true) {
            controller.sexValue = sexValue
        }
    }
}

extension UserService{
    func setUserSexImageView(_ imageView:UIImageView?,sexValue:Int) {
        let sexImgMinAlpha:CGFloat = 0.1
        
        if sexValue == 0 {
            imageView?.image = UIImage(named: "sex_middle")
            imageView?.alpha = 1
        }else if sexValue > 0{
            imageView?.image = UIImage(named: "sex_male")
            imageView?.alpha = sexImgMinAlpha + (1 - sexImgMinAlpha) * CGFloat(sexValue) / CGFloat(maxSexValue)
        }else if sexValue < 0{
            imageView?.image = UIImage(named: "sex_female")
            imageView?.alpha = sexImgMinAlpha + (1 - sexImgMinAlpha) * CGFloat(sexValue) / CGFloat(minSexValue)
        }
    }
}
