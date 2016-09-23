//
//  VideoPreviewBubble.swift
//  Vessage
//
//  Created by AlexChow on 16/8/12.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class VideoPreviewBubble: UIView {
    
    @IBOutlet var contentView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialFromXib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialFromXib()
    }
    
    func initialFromXib() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "VideoPreviewBubble", bundle: bundle)
        contentView = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        contentView.frame = bounds
        addSubview(contentView)
        videoPreviewView = contentView.viewWithTag(1)
        videoPreviewView.layer.cornerRadius = bounds.height / 2
        videoPreviewView.clipsToBounds = true
    }
    
    private(set) var videoPreviewView: UIView!
    
    static func instanceFromXib() -> VideoPreviewBubble{
        return NSBundle.mainBundle().loadNibNamed("VideoPreviewBubble", owner: nil, options: nil)![0] as! VideoPreviewBubble
    }
    
    
}
