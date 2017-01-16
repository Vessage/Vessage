//
//  FlashTipsLabel.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/16.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
class FlashTipsLabel: UILabel {
    
    var flashDuration:NSTimeInterval = 0.6
    var flashTime:UInt64 = 3600
    
    func flashTips(container:UIView,msg:String,center:CGPoint? = nil) {
        
        self.removeFromSuperview()
        
        self.clipsToBounds = true
        self.textColor = UIColor.orangeColor()
        self.textAlignment = .Center
        self.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.8)
        
        self.text = msg
        self.sizeToFit()
        
        self.layoutIfNeeded()
        
        self.frame.size.height += 10
        self.frame.size.width += 16
        
        self.layer.cornerRadius = self.frame.height / 2
        
        self.center = center == nil ? CGPointMake(container.frame.width / 2, container.frame.height / 2) : center!
        container.addSubview(self)
        UIAnimationHelper.flashView(self, duration: flashDuration, autoStop: true, stopAfterMs: flashTime){
            self.removeFromSuperview()
        }
    }
}
