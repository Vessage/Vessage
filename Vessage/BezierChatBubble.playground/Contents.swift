//: Playground - noun: a place where people can play

import UIKit

enum BezierBubbleDirection{
    case Up(width:Float,height:Float,startXRatio:Float)
    case Down(width:Float,height:Float,startXRatio:Float)
    case Left(width:Float,height:Float,startYRatio:Float)
    case Right(width:Float,height:Float,startYRatio:Float)
}

let b = UIBezierPath()
b.lineWidth=1
b.lineCapStyle = CGLineCap.round
b.lineJoinStyle = CGLineJoin.round
let cornerRadius:CGFloat = 10
let startMarkSize = CGSize(width: 10, height: 10)
/*
let l = BezierBubbleDirection.Left(width: 200, height: 200, startYRatio: 0.5)
if case let BezierBubbleDirection.Left(width,height,startYRatio) = l {
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x: CGFloat(w), y: CGFloat(height * startYRatio))
    b.move(to: start)
    b.addLine(to: CGPoint(x:w-startMarkSize.height,y:start.y - startMarkSize.width / 2 ))
    
    b.addArc(withCenter: CGPoint(x: w-startMarkSize.height-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc(withCenter: CGPoint(x: cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    
    b.addArc(withCenter: CGPoint(x: w-startMarkSize.height-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc(withCenter: CGPoint(x: w-startMarkSize.height-cornerRadius, y: start.y+startMarkSize.width/2), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    
    b.close()
}

let d = BezierBubbleDirection.Down(width: 200, height: 200, startXRatio: 0.5)
if case let BezierBubbleDirection.Down(width,height,startXRatio) = d {
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x:CGFloat(width * startXRatio),y:CGFloat(h))
    b.move(to: start)
    b.addLine(to: CGPoint(x:start.x+startMarkSize.width/2,y:h-startMarkSize.height))
    b.addArc(withCenter: CGPoint(x: w-cornerRadius, y: h-startMarkSize.height-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc(withCenter: CGPoint(x: w-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc(withCenter: CGPoint(x: cornerRadius, y: h - startMarkSize.height-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArc(withCenter: CGPoint(x: start.x-startMarkSize.width*3/2, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.close()
}
*/
let u = BezierBubbleDirection.Up(width: 200, height: 200, startXRatio: 0.5)
if case let BezierBubbleDirection.Up(width,height,startXRatio) = u {
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x: CGFloat(width * startXRatio),y: 0)
    b.move(to: start)
    b.addLine(to: CGPoint(x:start.x-startMarkSize.width / 2,y:startMarkSize.height))
    b.addArc(withCenter: CGPoint(x: cornerRadius, y: startMarkSize.height + cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI*3/2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc(withCenter: CGPoint(x: cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArc(withCenter: CGPoint(x: w-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc(withCenter: CGPoint(x: w-cornerRadius, y: startMarkSize.height + cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc(withCenter: CGPoint(x: start.x-startMarkSize.width / 2, y: startMarkSize.height), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.close()
}

let r = BezierBubbleDirection.Right(width: 200, height: 200, startYRatio: 0.5)
if case let BezierBubbleDirection.Right(width,height,startYRatio) = r {
    let w = CGFloat(width)
    let h = CGFloat(height)
    let start = CGPoint(x:0,y:CGFloat(height * startYRatio))
    b.move(to: start)
    b.addLine(to: CGPoint(x:startMarkSize.height,y:start.y + startMarkSize.width / 2))
    b.addArc(withCenter: CGPoint(x: startMarkSize.height+cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI / 2), clockwise: false)
    b.addArc(withCenter: CGPoint(x: w-cornerRadius, y: h-cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI / 2), endAngle: CGFloat(0), clockwise: false)
    b.addArc(withCenter: CGPoint(x: w-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 3 / 2), clockwise: false)
    b.addArc(withCenter: CGPoint(x: startMarkSize.height+cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 3 / 2), endAngle: CGFloat(M_PI), clockwise: false)
    b.addArc(withCenter: CGPoint(x: startMarkSize.height-cornerRadius, y: start.y - startMarkSize.width / 2), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(0), clockwise: false)
    b.close()
}
