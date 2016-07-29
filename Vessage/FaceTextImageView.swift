//
//  FaceTextImageView.swift
//  Vessage
//
//  Created by AlexChow on 16/7/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class FaceTextChatBubble: UIView {

    var messageContent:String!{
        didSet{
            
            messageContentTextView?.text = messageContent
        }
    }
    
    private var beginPoint:CGPoint!
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        self.beginPoint = touches.first?.locationInView(self)
        
        
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        if let bp = beginPoint {
            if let pt = touches.first?.locationInView(self){
                var newFrame = self.frame
                newFrame.origin.x += pt.x - bp.x
                newFrame.origin.y += pt.y - bp.y
                self.frame = newFrame
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        self.beginPoint = nil
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        self.beginPoint = nil
    }
    
    @IBOutlet weak var messageContentTextView: UILabel!{
        didSet{
            messageContentTextView.userInteractionEnabled = false
        }
    }
    
    static func instanceFromXib() -> FaceTextChatBubble{
        let view = NSBundle.mainBundle().loadNibNamed("FaceTextChatBubble", owner: nil, options: nil)[0] as! FaceTextChatBubble
        view.backgroundColor = UIColor.clearColor()
        view.userInteractionEnabled = true
        return view
    }
}

class FaceTextImageView: UIView {
    weak private var container:UIView!
    private var loadingImageView:UIImageView!
    private var imageView:UIImageView!{
        didSet{
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
        }
    }
    private var chatBubble:FaceTextChatBubble!
    private(set) var imageLoaded:Bool = false
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
    
    func initContainer(container:UIView) {
        self.container = container
        self.imageView = UIImageView()
        self.chatBubble = FaceTextChatBubble.instanceFromXib()
        let imv = UIImageView(frame: CGRectMake(0, 0, 64, 46))
        imv.animationImages = hudSpinImageArray
        imv.animationRepeatCount = 0
        imv.animationDuration = 0.6
        self.loadingImageView = imv
        
        self.subviews.forEach{$0.removeFromSuperview()}
        self.addSubview(self.imageView)
        self.addSubview(self.chatBubble)
        
        self.chatBubble.hidden = true
    }
    
    private func render(){
        self.frame = container.bounds
        self.imageView.frame = self.bounds
    }
    
    func setTextImage(fileId:String!,message:String!) {
        self.imageLoaded = false
        self.render()
        self.chatBubble.messageContent = message
        self.chatBubble.hidden = true
        self.imageView.hidden = true
        self.loadingImageView.center = self.center
        self.addSubview(self.loadingImageView)
        self.loadingImageView.startAnimating()
        ServiceContainer.getFileService().setAvatar(self.imageView, iconFileId: fileId, defaultImage: getDefaultFace()) { (suc) in
            self.imageLoaded = true
            self.loadingImageView.stopAnimating()
            self.loadingImageView.removeFromSuperview()
            self.imageView.hidden = false
            self.imageView.contentMode = (suc ? .ScaleAspectFill : .ScaleAspectFit)
            self.chatBubble.hidden = String.isNullOrEmpty(message)
            func retryFetchChatImage(suc:Bool,timesLeft:Int){
                if suc{
                    self.adjustChatBubble()
                }else{
                    self.setChatBubbleCenter()
                }
                
                if !suc && timesLeft > 0{
                    ServiceContainer.getFileService().setAvatar(self.imageView, iconFileId: fileId,defaultImage: getDefaultFace()){ setted in
                        retryFetchChatImage(setted,timesLeft: timesLeft - 1)
                    }
                }
                #if DEBUG
                    if !suc {
                        if timesLeft > 0 {
                            print("Retry Fetching Chat Image,Retry Times Left:\(timesLeft - 1)")
                        }else{
                            print("Fetch Chat Image Failure")
                        }
                    }else{
                        print("Chat Image Fetched")
                    }
                #endif
            }
            retryFetchChatImage(suc, timesLeft: 2)
            
        }
    }
    
    func adjustChatBubble() {
        if let cgi = self.imageView.image!.CGImage{
            let img = CIImage(CGImage: cgi, options: nil)
            let faces = self.faceDetector.featuresInImage(img)
            if let face = faces.first as? CIFaceFeature{
                
                let previewBox = self.imageView.bounds
                let clap = self.imageView.image!
                
                var faceRect = face.bounds
                // scale coordinates so they fit in the preview box, which may be scaled
                let widthScaleBy = previewBox.size.width / clap.size.width;
                let heightScaleBy = previewBox.size.height / clap.size.height;
                let scale = max(widthScaleBy, heightScaleBy)
                faceRect.size.width *= scale;
                faceRect.size.height *= scale;
                faceRect.origin.x *= scale;
                faceRect.origin.y *= scale;
                
                //mirror
                var rect = faceRect
                rect = CGRectMake(previewBox.size.width - faceRect.origin.x - faceRect.size.width, previewBox.size.height - faceRect.size.height - faceRect.origin.y, faceRect.size.width, faceRect.size.height);
                let x = rect.origin.x + rect.size.width / 2 - self.imageView.frame.width / 2
                let y = rect.origin.y + rect.size.height - 10
                self.setChatBubblePosition(CGPointMake(x, y))
                return
            }
        }
        self.setChatBubbleCenter()
    }
    
    private func setChatBubbleCenter(){
        let center = CGPointMake((self.frame.width - self.chatBubble.frame.width) / 2, (self.frame.height + 80) / 2)
        self.setChatBubblePosition(center)
    }
    
    func setChatBubblePosition(position:CGPoint) {
        let width = self.imageView.frame.width
        let str = self.chatBubble.messageContent!
        let strRect = str.boundingRectWithSize(CGSizeMake(width, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:self.chatBubble.messageContentTextView.font], context: nil)
        self.chatBubble.frame = CGRectMake(position.x,position.y,width,strRect.height + strRect.height / 14 * 42)
        self.chatBubble.messageContentTextView.frame = self.chatBubble.bounds
        self.chatBubbleAnimateShow()
    }
    
    func chatBubbleAnimateShow() {
        self.chatBubble.alpha = 0
        self.chatBubble.hidden = false
        UIView.beginAnimations("ChatBubbleEaseIn", context: nil)
        UIView.setAnimationCurve(.EaseInOut)
        UIView.setAnimationDuration(0.6)
        self.chatBubble.alpha = 1
        UIView.commitAnimations()
    }
}