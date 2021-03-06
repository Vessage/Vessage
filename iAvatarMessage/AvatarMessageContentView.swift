//
//  AvatarMessageContentView.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

protocol AvatarMessageContentContainerDelegate{
    func avatarMessageContentContainerWidth(_ container:AvatarMessageContentContainer) -> CGFloat
    func avatarMessageContentView(_ container:AvatarMessageContentContainer) -> UIView
    func avatarMessageContentViewContentSize(_ container:AvatarMessageContentContainer,containerWidth:CGFloat,contentView:UIView) -> CGSize
}

class AvatarMessageContentContainer: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bubbleView = BezierBubbleView()
        bubbleView.bubbleViewLayer.fillColor = UIColor.lightGray.cgColor
        self.addSubview(bubbleView)
        avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        self.backgroundColor = UIColor.clear
        self.addSubview(avatarImageView)
    }
    
    convenience init() {
        self.init(frame:CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var delegate:AvatarMessageContentContainerDelegate!
    
    var avatarSize:CGFloat = 72
    
    fileprivate(set) var avatarImageView: UIImageView!
    
    fileprivate(set) var bubbleView:BezierBubbleView!
    fileprivate(set) var contentView:UIView!
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            let curP = touch.location(in: self)
            let preP = touch.previousLocation(in: self)
            let offsetX = curP.x - preP.x;
            let offsetY = curP.y - preP.y
            if moveAvatarWithTranslation(offsetX,ty: offsetY){
                return
            }
        }
        super.touchesMoved(touches, with: event)
    }
}

//Horizontal Bubble
extension AvatarMessageContentContainer{
    override func draw(_ rect: CGRect) {
        if let d = delegate{
            avatarImageView.clipsToBounds = true
            avatarImageView.frame.size = CGSize(width: avatarSize, height: avatarSize)
            avatarImageView.layer.cornerRadius = avatarImageView.frame.size.height / 2
            
            avatarImageView.layoutIfNeeded()
            
            self.frame.size.width = d.avatarMessageContentContainerWidth(self)
            contentView = d.avatarMessageContentView(self)
            bubbleView.setContentView(contentView)
            
            let contentMaxWidth = self.frame.size.width - avatarImageView.frame.origin.x - avatarImageView.frame.size.width - 6
            
            let contentSize = d.avatarMessageContentViewContentSize(self, containerWidth: contentMaxWidth,contentView: contentView)
            contentView.frame.size = contentSize
            contentView.frame.origin = CGPoint.zero
            
            contentView.layoutIfNeeded()
            
            avatarImageView.frame.origin.x = 0
            avatarImageView.frame.origin.y = 0
            
            
            let bubbleViewSize = bubbleView.sizeOfContentSize(contentSize, direction: .right(startYRatio: 0.5))
            bubbleView.frame.size = bubbleViewSize

            bubbleView.frame.origin.x = avatarImageView.frame.origin.x + avatarImageView.frame.width + 6
            bubbleView.frame.origin.y = avatarSize > bubbleViewSize.height ? (avatarSize - bubbleViewSize.height) / 2 : 0
            
            setBubbleMarkPoint()
            
            self.frame.size.height = max(bubbleView.frame.origin.y + bubbleView.frame.size.height,avatarImageView.frame.origin.y + avatarImageView.frame.height) + 10
            self.frame.size.width += 10
            bubbleView.layoutIfNeeded()
        }
        super.draw(rect)
    }
    
    fileprivate func setBubbleMarkPoint(){
        var midPoint:CGFloat = 0
        if self.bubbleView.frame.height < self.avatarSize{
            midPoint = 0.5
        }else{
            midPoint = (self.avatarImageView.frame.origin.y + self.avatarImageView.frame.height / 2 - bubbleView.frame.origin.y) / (bubbleView.frame.size.height)
        }
        self.bubbleView.bubbleDirection = .right(startYRatio: Float(midPoint))
    }
    
    fileprivate func moveAvatarWithTranslation(_ tx:CGFloat,ty:CGFloat) -> Bool {
        if ty == 0 {
            return false
        }
        let afterY = avatarImageView.frame.origin.y + ty
        let height = avatarImageView.frame.height
        
        let tLimit = bubbleView.frame.origin.y
        let bLimit = bubbleView.frame.origin.y + bubbleView.frame.size.height - height
        
        if afterY < tLimit || afterY > bLimit {
            return false
        }
        avatarImageView.frame.origin.y = afterY
        setBubbleMarkPoint()
        return true
    }
}

/*
//Vertical Bubble
extension AvatarMessageContentContainer{
    override func drawRect(rect: CGRect) {
        if let d = delegate{
            avatarImageView.clipsToBounds = true
            avatarImageView.frame.size = CGSize(width: avatarSize, height: avatarSize)
            avatarImageView.layer.cornerRadius = avatarImageView.frame.size.height / 2
            
            avatarImageView.layoutIfNeeded()
            
            self.frame.size.width = d.avatarMessageContentContainerWidth(self)
            contentView = d.avatarMessageContentView(self)
            bubbleView.setContentView(contentView)
            
            let contentSize = d.avatarMessageContentViewContentSize(self, containerWidth: self.frame.size.width,contentView: contentView)
            contentView.frame.size = contentSize
            contentView.frame.origin = CGPointZero
            
            contentView.layoutIfNeeded()
            
            avatarImageView.frame.origin.x = 0
            avatarImageView.frame.origin.y = 0
            
            bubbleView.frame.origin.x = 0
            bubbleView.frame.origin.y = avatarImageView.frame.origin.y + avatarImageView.frame.size.height + 6
            let bubbleViewSize = bubbleView.sizeOfContentSize(contentSize, direction: .Down(startXRatio: 0.5))
            bubbleView.frame.size = bubbleViewSize
            
            setBubbleMarkPoint()
            
            self.frame.size.height = bubbleView.frame.origin.y + bubbleView.frame.size.height + 10
            bubbleView.layoutIfNeeded()
        }
        super.drawRect(rect)
    }
    private func setBubbleMarkPoint(){
        let midPoint = (self.avatarImageView.frame.origin.x + self.avatarImageView.frame.width / 2 - bubbleView.frame.origin.x) / (bubbleView.frame.size.width)
        self.bubbleView.bubbleDirection = .Down(startXRatio: Float(midPoint))
    }
    
    private func moveAvatarWithTranslation(tx:CGFloat,ty:CGFloat) -> Bool {
        if tx == 0 {
            return false
        }
        let afterX = avatarImageView.frame.origin.x + tx
        let width = avatarImageView.frame.width
        
        let lLimit = bubbleView.frame.origin.x
        let rLimit = bubbleView.frame.origin.x + bubbleView.frame.size.width - width
        
        if afterX < lLimit || afterX > rLimit {
            return false
        }
        avatarImageView.frame.origin.x = afterX
        setBubbleMarkPoint()
        return true
    }
}
*/
