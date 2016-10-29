//
//  FaceTextBubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class FaceTextBubbleVessageHandler: BubbleVessageHandler {
    
    func getContentViewSize(vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel{
            label.text = vessage.getBodyDict()["textMessage"] as? String
            var size = label.sizeThatFits(maxLimitedSize)
            if size.width < 48 {
                size.width = 48
            }
            return size
        }
        return CGSizeZero
    }
    
    func getContentView(vessage: Vessage) -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .Center
        return label
    }
    
    func presentContent(oldVessage: Vessage?, newVessage: Vessage,contentView:UIView) {
        if let label = contentView as? UILabel {
            label.text = newVessage.getBodyDict()["textMessage"] as? String
            ServiceContainer.getVessageService().readVessage(newVessage)
        }
    }
}
