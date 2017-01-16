//
//  PaperAirplaneMainViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/13.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import UIKit

extension String{
    var PaperAirplaneString:String{
        return LocalizedString(self, tableName: "PaperAirplane", bundle: NSBundle.mainBundle())
    }
}

let PaperAirplaneActivityId = "1007"

class PaperAirplaneMainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(PaperAirplaneMainViewController.onSwipe(_:)))
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(PaperAirplaneMainViewController.onSwipe(_:)))
        swipeDown.direction = .Down
        swipeUp.direction = .Up
        self.view.addGestureRecognizer(swipeDown)
        self.view.addGestureRecognizer(swipeUp)
        loadAnimation()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func onSwipe(ges:UISwipeGestureRecognizer) {
        if ges.direction == .Down {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }else if ges.direction == .Up{
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    private func loadAnimation() {
        
    }

    @IBAction func catchPaperPlane(sender: AnyObject) {
        PaperAirplaneCatchViewController.showCatchView(self)
    }
    
    @IBAction func leave(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
