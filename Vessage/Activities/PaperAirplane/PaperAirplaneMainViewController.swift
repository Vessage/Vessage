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

let PaperAirplaneActivityId = "1005"

class PaperAirplaneMainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        loadAnimation()
    }
    
    private func loadAnimation() {
        
    }

}
