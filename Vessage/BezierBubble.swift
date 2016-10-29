//
//  BezierBubble.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

protocol BezierBubbleContentContainerDelegate {
    func bezierBubbleContentContainer(onDraw rect: CGRect)
}

private class ContentContainer: UIView {
    private var containerDelegate:BezierBubbleContentContainerDelegate?
    private override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        self.containerDelegate?.bezierBubbleContentContainer(onDraw: rect)
    }
}

class BezierBubbleView: UIView {
    private(set) var startPoint = CGPointZero
    private(set) var path:UIBezierPath!
    private var contentContainer:ContentContainer
    private(set) var bubbleViewLayer:CAShapeLayer!
    
    var containerDelegate:BezierBubbleContentContainerDelegate?{
        set{
            contentContainer.containerDelegate = newValue
        }
        get{
            return contentContainer.containerDelegate
        }
    }
    
    var bubbleDirection:BezierBubbleDirection = .Down(startXRatio: 0.5){
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        contentContainer = ContentContainer()
        contentContainer.backgroundColor = UIColor.clearColor()
        super.init(frame: frame)
        self.addSubview(contentContainer)
        contentContainer.clipsToBounds = true
        bubbleViewLayer = CAShapeLayer()
        self.backgroundColor = UIColor.clearColor()
        self.bubbleViewLayer.backgroundColor = UIColor.clearColor().CGColor
        self.bubbleViewLayer.fillColor = UIColor.whiteColor().CGColor
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playBubbleAnimation() {
        self.alpha = 0.3
        UIView.transitionWithView(self, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.alpha = 0.9
            }, completion: { suc in
                self.alpha = 1
        })
    }
    
    private let startMarkHeight:CGFloat = 10
    private let spaceOfContentToView:CGFloat = 6
    
    func setContentView(contentView:UIView) {
        if contentContainer.subviews.contains(contentView) {
            return
        }else{
            self.contentContainer.removeAllSubviews()
            contentContainer.addSubview(contentView)
        }
    }
    
    func sizeOfContentSize(contentSize:CGSize,direction:BezierBubbleDirection) -> CGSize {
        switch self.bubbleDirection {
        case .Down(startXRatio: _),.Up(startXRatio: _):
            return CGSize(width: contentSize.width + spaceOfContentToView * 2, height: contentSize.height + startMarkHeight + spaceOfContentToView * 2 )
        case .Left(startYRatio: _),.Right(startYRatio: _):
            return CGSize(width: contentSize.width + startMarkHeight + spaceOfContentToView * 2, height: contentSize.height + spaceOfContentToView * 2 )
        }
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        drawBubble(rect)
        drawcontentContainer(rect)
    }
    
    private func drawBubble(rect:CGRect){
        self.backgroundColor = UIColor.clearColor()
        UIColor.clearColor().setFill()
        if bubbleViewLayer.superlayer == nil {
            self.layer.insertSublayer(bubbleViewLayer, atIndex: 0)
        }
        let b = getBezierBubblePath(rect.width, height: rect.height)
        bubbleViewLayer.frame = self.bounds
        bubbleViewLayer.path = b.CGPath
        b.fill()
        playBubbleAnimation()
        self.bubbleViewLayer.backgroundColor = UIColor.clearColor().CGColor
    }
    
    private func drawcontentContainer(rect:CGRect){
        switch self.bubbleDirection {
        case .Down(startXRatio: _):
            contentContainer.frame.size = CGSizeMake(rect.size.width - spaceOfContentToView * 2, rect.size.height - spaceOfContentToView * 2 - startMarkHeight)
            contentContainer.frame.origin = CGPointMake(spaceOfContentToView, startMarkHeight + spaceOfContentToView)
        case .Up(startXRatio: _):
            contentContainer.frame.size = CGSizeMake(rect.size.width - spaceOfContentToView * 2, rect.size.height - spaceOfContentToView * 2 - startMarkHeight)
            contentContainer.frame.origin = CGPointMake(spaceOfContentToView, spaceOfContentToView)
        case .Left(startYRatio: _):
            contentContainer.frame.size = CGSizeMake(rect.size.width - spaceOfContentToView * 2, rect.size.height - spaceOfContentToView * 2 - startMarkHeight)
            contentContainer.frame.origin = CGPointMake(spaceOfContentToView, spaceOfContentToView)
        case .Right(startYRatio: _):
            contentContainer.frame.size = CGSizeMake(rect.size.width - spaceOfContentToView * 2, rect.size.height - spaceOfContentToView * 2 - startMarkHeight)
            contentContainer.frame.origin = CGPointMake(startMarkHeight + spaceOfContentToView, spaceOfContentToView)
        }
    }
    
    func getBezierBubblePath(width:CGFloat,height:CGFloat) -> UIBezierPath {
        if self.path == nil {
            self.path = UIBezierPath()
            self.path.lineWidth = 0
        }
        let b = self.path
        b.removeAllPoints()
        b.lineCapStyle = CGLineCap.Round
        b.lineJoinStyle = CGLineJoin.Round
        
        switch self.bubbleDirection {
        case let .Up(startXRatio: xr):
            startPoint = drawBezierDownBubble(width,height: height,startXRatio: CGFloat(xr),bezierPath:b)
        case let .Down(startXRatio: xr):
            startPoint = drawBezierUpBubble(width,height: height,startXRatio: CGFloat(xr),bezierPath: b)
        case let .Left(startYRatio: yr):
            startPoint = drawBezierLeftBubble(width,height: height,startYRatio: CGFloat(yr),bezierPath:b)
        case let .Right(startYRatio: yr):
            startPoint = drawBezierRightBubble(width,height: height,startYRatio: CGFloat(yr),bezierPath:b)
        }
        
        return b
    }
}

enum BezierBubbleDirection{
    case Up(startXRatio:Float)
    case Down(startXRatio:Float)
    case Left(startYRatio:Float)
    case Right(startYRatio:Float)
    
}

func drawBezierRightBubble(width:CGFloat,height:CGFloat,startYRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint  {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x:0,y:height * CGFloat(startYRatio))
    b.moveToPoint( start)
    b.addLineToPoint(CGPoint(x:startMarkSize.height,y:start.y + startMarkSize.width / 2))
    b.addArcWithCenter( CGPoint(x: startMarkSize.height+cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArcWithCenter( CGPoint(x: w-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArcWithCenter( CGPoint(x: w-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArcWithCenter( CGPoint(x: startMarkSize.height+cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArcWithCenter( CGPoint(x: startMarkSize.height-cornerRadius, y: start.y - startMarkSize.width / 2), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.closePath()
    return start
}

func drawBezierLeftBubble(width:CGFloat,height:CGFloat,startYRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x: CGFloat(w), y: height * CGFloat(startYRatio))
    b.moveToPoint( start)
    b.addLineToPoint(CGPoint(x:w-startMarkSize.height,y:start.y - startMarkSize.width / 2 ))
    
    b.addArcWithCenter( CGPoint(x: w-startMarkSize.height-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArcWithCenter( CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArcWithCenter( CGPoint(x: cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    
    b.addArcWithCenter( CGPoint(x: w-startMarkSize.height-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArcWithCenter( CGPoint(x: w-startMarkSize.height-cornerRadius, y: start.y+startMarkSize.width/2), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    
    b.closePath()
    return start
}

func drawBezierUpBubble(width:CGFloat,height:CGFloat,startXRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint  {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x: width * CGFloat(startXRatio),y: 0)
    b.moveToPoint( start)
    b.addLineToPoint(CGPoint(x:start.x-startMarkSize.width / 2,y:startMarkSize.height))
    b.addArcWithCenter( CGPoint(x: cornerRadius, y: startMarkSize.height + cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI*3/2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArcWithCenter( CGPoint(x: cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArcWithCenter( CGPoint(x: w-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArcWithCenter( CGPoint(x: w-cornerRadius, y: startMarkSize.height + cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArcWithCenter( CGPoint(x: start.x-startMarkSize.width / 2, y: startMarkSize.height), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.closePath()
    return start
}

func drawBezierDownBubble(width:CGFloat,height:CGFloat,startXRatio:CGFloat,bezierPath b:UIBezierPath) -> CGPoint {
    let cornerRadius:CGFloat = 10
    let startMarkSize = CGSize(width: 10, height: 10)
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x:width * CGFloat(startXRatio),y:CGFloat(h))
    b.moveToPoint( start)
    b.addLineToPoint(CGPoint(x:start.x+startMarkSize.width/2,y:h-startMarkSize.height))
    b.addArcWithCenter( CGPoint(x: w-cornerRadius, y: h-startMarkSize.height-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArcWithCenter( CGPoint(x: w-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArcWithCenter( CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArcWithCenter( CGPoint(x: cornerRadius, y: h - startMarkSize.height-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArcWithCenter( CGPoint(x: start.x-startMarkSize.width*3/2, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.closePath()
    return start
}

