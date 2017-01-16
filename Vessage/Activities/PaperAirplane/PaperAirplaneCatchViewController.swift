//
//  PaperAirplaneCatchViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/13.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import UIKit

class PaperAirplaneCatchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @IBAction func cancelAndBack(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    static func showCatchView(vc:UIViewController){
        let controller = instanceFromStoryBoard("PaperAirplane", identifier: "PaperAirplaneCatchViewController")
        vc.presentViewController(controller, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
