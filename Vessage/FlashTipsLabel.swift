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
    
    func flashTips(container:UIView,msg:String,center:CGPoint? = nil,textColor:UIColor = UIColor.orangeColor()) {
        
        self.removeFromSuperview()
        
        self.clipsToBounds = true
        self.textColor = textColor
        self.textAlignment = .Center
        self.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.9)
        
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
