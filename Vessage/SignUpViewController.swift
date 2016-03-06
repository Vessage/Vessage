//
//  SignUpViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: SignUpViewController
class SignUpViewController: UIViewController {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    //MARK: actions
    @IBAction func signUp(sender: AnyObject) {
        
    }
    
    @IBAction func showSignIn(sender: AnyObject) {
        self.dismissViewControllerAnimated(false) { () -> Void in
            
        }
    }
    
    static func showSignUpViewController(vc:UIViewController)
    {
        let controller = instanceFromStoryBoard("AccountSign", identifier: "SignUpViewController") as! SignUpViewController
        vc.presentViewController(controller, animated: true) { () -> Void in
            
        }
    }
}
