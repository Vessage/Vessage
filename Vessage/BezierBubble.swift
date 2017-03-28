//
//  BezierBubble.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

protocol BezierBubbleContentContainerDelegate {
    func bezierBubbleContentContainer(onDraw rect: CGRect)
}

private class ContentContainer: UIView {
    fileprivate var containerDelegate:BezierBubbleContentContainerDelegate?
    fileprivate override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.containerDelegate?.bezierBubbleContentContainer(onDraw: rect)
    }
}

class BezierBubbleView: UIView {
    fileprivate(set) var startPoint = CGPoint.zero
    fileprivate(set) var path:UIBezierPath!
    fileprivate var contentContainer:ContentContainer
    fileprivate(set) var bubbleViewLayer:CAShapeLayer!
    
    var containerDelegate:BezierBubbleContentContainerDelegate?{
        set{
            contentContainer.containerDelegate = newValue
        }
        get{
            return contentContainer.containerDelegate
        }
    }
    
    var bubbleDirection:BezierBubbleDirection = .down(startXRatio: 0.5){
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        contentContainer = ContentContainer()
        contentContainer.backgroundColor = UIColor.clear
        super.init(frame: frame)
        self.clipsToBounds = false
        self.addSubview(contentContainer)
        bubbleViewLayer = CAShapeLayer()
        self.backgroundColor = UIColor.clear
        self.bubbleViewLayer.backgroundColor = UIColor.clear.cgColor
        self.bubbleViewLayer.fillColor = UIColor.white.cgColor
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playBubbleAnimation() {
        self.alpha = 0.3
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.alpha = 0.9
            }, completion: { suc in
                self.alpha = 1
        })
    }
    
    fileprivate let startMarkHeight:CGFloat = 10
    fileprivate let spaceOfContentToView:CGFloat = 6
    
    func setContentView(_ contentView:UIView) {
        self.contentContainer.removeAllSubviews()
        contentContainer.addSubview(contentView)
    }
    
    func getContentView() -> UIView? {
        return contentContainer.subviews.first
    }
    
    @discardableResult
    func removeContentView() -> UIView? {
        let view = contentContainer.subviews.first
        contentContainer.removeAllSubviews()
        return view
    }
    
    func sizeOfContentSize(_ contentSize:CGSize,direction:BezierBubbleDirection) -> CGSize {
        switch self.bubbleDirection {
        case .down(startXRatio: _),.up(startXRatio: _):
            return CGSize(width: contentSize.width + spaceOfContentToView * 2, height: contentSize.height + startMarkHeight + spaceOfContentToView * 2 )
        case .left(startYRatio: _),.right(startYRatio: _):
            return CGSize(width: contentSize.width + startMarkHeight + spaceOfContentToView * 2, height: contentSize.height + spaceOfContentToView * 2 )
        }
    }
    
    func maxContentSizeOf(_ maxBubbleViewSize:CGSize) -> CGSize {
        switch self.bubbleDirection {
        case .down(startXRatio: _):
            return CGSize(width: maxBubbleViewSize.width - spaceOfContentToView * 2, height: maxBubbleViewSize.height - spaceOfContentToView * 2 - startMarkHeight)
        case .up(startXRatio: _):
            return CGSize(width: maxBubbleViewSize.width - spaceOfContentToView * 2, height: maxBubbleViewSize.height - spaceOfContentToView * 2 - startMarkHeight)
        case .left(startYRatio: _):
            return CGSize(width: maxBubbleViewSize.width - spaceOfContentToView * 2 - startMarkHeight, height: maxBubbleViewSize.height - spaceOfContentToView * 2)
        case .right(startYRatio: _):
            return CGSize(width: maxBubbleViewSize.width - spaceOfContentToView * 2 - startMarkHeight, height: maxBubbleViewSize.height - spaceOfContentToView * 2)
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawBubble(rect)
        drawContentContainer(rect)
    }
    
    fileprivate func drawBubble(_ rect:CGRect){
        self.backgroundColor = UIColor.clear
        UIColor.clear.setFill()
        if bubbleViewLayer.superlayer == nil {
            self.layer.insertSublayer(bubbleViewLayer, at: 0)
        }
        let b = getBezierBubblePath(rect.width, height: rect.height)
        bubbleViewLayer.frame = self.bounds
        bubbleViewLayer.path = b.cgPath
        b.fill()
        playBubbleAnimation()
        self.bubbleViewLayer.backgroundColor = UIColor.clear.cgColor
    }
    
    fileprivate func drawContentContainer(_ rect:CGRect){
        contentContainer.frame.size = maxContentSizeOf(rect.size)
        switch self.bubbleDirection {
        case .down(startXRatio: _):
            contentContainer.frame.origin = CGPoint(x: spaceOfContentToView, y: startMarkHeight + spaceOfContentToView)
        case .up(startXRatio: _):
            contentContainer.frame.origin = CGPoint(x: spaceOfContentToView, y: spaceOfContentToView)
        case .left(startYRatio: _):
            contentContainer.frame.origin = CGPoint(x: spaceOfContentToView, y: spaceOfContentToView)
        case .right(startYRatio: _):
            contentContainer.frame.origin = CGPoint(x: startMarkHeight + spaceOfContentToView, y: spaceOfContentToView)
        }
    }
    
    func getBezierBubblePath(_ width:CGFloat,height:CGFloat) -> UIBezierPath {
        if self.path == nil {
            self.path = UIBezierPath()
            self.path.lineWidth = 0
        }
        let b = self.path
        b?.removeAllPoints()
        b?.lineCapStyle = CGLineCap.round
        b?.lineJoinStyle = CGLineJoin.round
        
        switch self.bubbleDirection {
        case let .up(startXRatio: xr):
            startPoint = drawBezierDownBubble(width,height: height,startXRatio: CGFloat(xr),bezierPath:b!)
        case let .down(startXRatio: xr):
            startPoint = drawBezierUpBubble(width,height: height,startXRatio: CGFloat(xr),bezierPath: b!)
        case let .left(startYRatio: yr):
            startPoint = drawBezierLeftBubble(width,height: height,startYRatio: CGFloat(yr),bezierPath:b!)
        case let .right(startYRatio: yr):
            startPoint = drawBezierRightBubble(width,height: height,startYRatio: CGFloat(yr),bezierPath:b!)
        }
        
        return b!
    }
}

enum BezierBubbleDirection{
    case up(startXRatio:Float)
    case down(startXRatio:Float)
    case left(startYRatio:Float)
    case right(startYRatio:Float)
    
}

func drawBezierRightBubble(_ width:CGFloat,height:CGFloat,startYRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint  {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x:0,y:height * CGFloat(startYRatio))
    b.move( to: start)
    b.addLine(to: CGPoint(x:startMarkSize.height,y:start.y + startMarkSize.width / 2))
    b.addArc( withCenter: CGPoint(x: startMarkSize.height+cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArc( withCenter: CGPoint(x: w-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc( withCenter: CGPoint(x: w-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc( withCenter: CGPoint(x: startMarkSize.height+cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc( withCenter: CGPoint(x: startMarkSize.height-cornerRadius, y: start.y - startMarkSize.width / 2), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.close()
    return start
}

func drawBezierLeftBubble(_ width:CGFloat,height:CGFloat,startYRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x: CGFloat(w), y: height * CGFloat(startYRatio))
    b.move( to: start)
    b.addLine(to: CGPoint(x:w-startMarkSize.height,y:start.y - startMarkSize.width / 2 ))
    
    b.addArc( withCenter: CGPoint(x: w-startMarkSize.height-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc( withCenter: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc( withCenter: CGPoint(x: cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    
    b.addArc( withCenter: CGPoint(x: w-startMarkSize.height-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc( withCenter: CGPoint(x: w-startMarkSize.height-cornerRadius, y: start.y+startMarkSize.width/2), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    
    b.close()
    return start
}

func drawBezierUpBubble(_ width:CGFloat,height:CGFloat,startXRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint  {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x: width * CGFloat(startXRatio),y: 0)
    b.move( to: start)
    b.addLine(to: CGPoint(x:start.x-startMarkSize.width / 2,y:startMarkSize.height))
    b.addArc( withCenter: CGPoint(x: cornerRadius, y: startMarkSize.height + cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI*3/2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc( withCenter: CGPoint(x: cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArc( withCenter: CGPoint(x: w-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc( withCenter: CGPoint(x: w-cornerRadius, y: startMarkSize.height + cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc( withCenter: CGPoint(x: start.x-startMarkSize.width / 2, y: startMarkSize.height), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.close()
    return start
}

func drawBezierDownBubble(_ width:CGFloat,height:CGFloat,startXRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x:width * CGFloat(startXRatio),y:CGFloat(h))
    b.move( to: start)
    b.addLine(to: CGPoint(x:start.x+startMarkSize.width/2,y:h-startMarkSize.height))
    b.addArc( withCenter: CGPoint(x: w-cornerRadius, y: h-startMarkSize.height-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc( withCenter: CGPoint(x: w-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc( withCenter: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc( withCenter: CGPoint(x: cornerRadius, y: h - startMarkSize.height-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArc( withCenter: CGPoint(x: start.x-startMarkSize.width*3/2, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.close()
    return start
}

