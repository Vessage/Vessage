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
    
    @IBOutlet weak var messageContentTextView: UILabel!{
        didSet{
            messageContentTextView.userInteractionEnabled = false
        }
    }
    
    static func instanceFromXib() -> FaceTextChatBubble{
        let view = NSBundle.mainBundle().loadNibNamed("FaceTextChatBubble", owner: nil, options: nil)![0] as! FaceTextChatBubble
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
            imageView.layoutIfNeeded()
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
        }
    }
    private(set) var chatBubbleMoveGesture:UIPanGestureRecognizer!
    private var chatBubble:FaceTextChatBubble!
    var chatBubbleMovable = true{
        didSet{
            if chatBubbleMovable {
                self.chatBubble?.addGestureRecognizer(self.chatBubbleMoveGesture)
            }else{
                self.chatBubble?.removeGestureRecognizer(self.chatBubbleMoveGesture)
            }
        }
    }
    
    private(set) var imageLoaded:Bool = false
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
    
    #if DEBUG
    private var faceMask:UIView!
    private func initFaceMask(){
        faceMask = UIView()
        faceMask.backgroundColor = UIColor.clearColor()
        faceMask.layer.borderColor = UIColor.orangeColor().CGColor
        faceMask.layer.borderWidth = 1
    }
    #endif
    
    func initContainer(container:UIView) {
        self.container = container
        self.imageView = UIImageView()
        self.chatBubble = FaceTextChatBubble.instanceFromXib()
        self.chatBubbleMoveGesture = UIPanGestureRecognizer(target: self, action: #selector(FaceTextImageView.onMoveChatBubble(_:)))
        if chatBubbleMovable {
            self.chatBubble.addGestureRecognizer(self.chatBubbleMoveGesture)
        }
        let imv = UIImageView(frame: CGRectMake(0, 0, 64, 46))
        imv.animationImages = hudSpinImageArray
        imv.animationRepeatCount = 0
        imv.animationDuration = 0.6
        self.loadingImageView = imv
        
        self.subviews.forEach{$0.removeFromSuperview()}
        self.addSubview(self.imageView)
        self.addSubview(self.chatBubble)
        
        #if DEBUG
            initFaceMask()
        #endif
        
        self.chatBubble.hidden = true
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    private var beginPoint:CGPoint!
    func onMoveChatBubble(ges:UIPanGestureRecognizer) {
        
        switch ges.state {
        case .Began:
            beginPoint = ges.locationInView(self)
        case .Cancelled,.Ended,.Failed,.Possible:
            beginPoint = nil
        case .Changed:
            if let bp = beginPoint{
                let pt = ges.locationInView(self)
                var newFrame = ges.view!.frame
                newFrame.origin.x += pt.x - bp.x
                newFrame.origin.y += pt.y - bp.y
                ges.view!.frame = newFrame
                beginPoint = pt
            }
        }
    }
    
    private func render(){
        container.layoutIfNeeded()
        self.frame = container.bounds
        self.imageView.frame = self.bounds
    }
    
    func setTextImage(fileId:String!,message:String!,onMessagePresented:(()->Void)? = nil) {
        self.imageLoaded = false
        self.render()
        self.chatBubble.messageContent = message
        self.chatBubble.hidden = true
        self.imageView.hidden = true
        self.loadingImageView.center = self.center
        self.addSubview(self.loadingImageView)
        self.loadingImageView.startAnimating()
        ServiceContainer.getFileService().setAvatar(self.imageView, iconFileId: fileId, defaultImage: getDefaultFace()) { (suc) in
            if self.container == nil{
                return
            }
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
                        if self.container == nil{
                            return
                        }
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
            onMessagePresented?()
        }
    }
    
    func adjustChatBubble() {
        
        if let cgi = self.imageView.image!.CGImage{
            
            let img = CIImage(CGImage: cgi, options: nil)
            let faces = self.faceDetector!.featuresInImage(img)
            if let face = faces.last as? CIFaceFeature{
                
                let previewBox = self.imageView.bounds
                let clap = self.imageView.image!
                
                #if DEBUG
                    print("Preview ImageView Frame:\(previewBox)")
                    print("Clap Size:\(clap.size)")
                #endif
                
                var faceRect = face.bounds
                // scale coordinates so they fit in the preview box, which may be scaled
                let widthScaleBy = previewBox.size.width / clap.size.width;
                let heightScaleBy = previewBox.size.height / clap.size.height;
                let scale = max(widthScaleBy, heightScaleBy)
                faceRect.size.width *= scale;
                faceRect.size.height *= scale;
                faceRect.origin.x *= scale;
                faceRect.origin.y *= scale;
                
                let imageCenter = CGSizeMake(clap.size.width * scale / 2, clap.size.height * scale / 2)
                let preivewCenter = CGSizeMake(previewBox.width / 2, previewBox.height / 2)
                
                let delta = CGSizeMake(preivewCenter.width - imageCenter.width, preivewCenter.height - imageCenter.height)
                
                #if DEBUG
                    print("imageCenter:\(imageCenter)")
                    print("preivewCenter:\(preivewCenter)")
                    print("delta:\(delta)")
                #endif
                
                //adjust move center
                var rect = faceRect
                rect.origin.x += delta.width
                rect.origin.y += delta.height
                
                //rotate 180'
                rect = CGRectMake(rect.origin.x, previewBox.height - rect.origin.y - rect.height, rect.width, rect.height)
                
                #if DEBUG
                    self.container.addSubview(faceMask)
                    faceMask.frame = rect
                #endif
                
                let x = rect.origin.x + rect.size.width * 0.5
                let y = rect.origin.y + rect.size.height
                
                let mouthPos = CGPointMake(x, y)
                
                self.setChatBubblePosition(mouthPos)
                return
            }
        }
        self.setChatBubbleCenter()
    }
    
    private func setChatBubbleCenter(){
        let center = CGPointMake(self.imageView.frame.width / 2, self.imageView.frame.height * 0.6)
        self.setChatBubblePosition(center)
    }
    
    func setChatBubblePosition(position:CGPoint) {
        let width = self.imageView.frame.width + 10
        let str = self.chatBubble.messageContent!
        let strRect = str.boundingRectWithSize(CGSizeMake(width, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:self.chatBubble.messageContentTextView.font], context: nil)
        self.chatBubble.frame = CGRectMake(position.x - width / 2,position.y,width,strRect.height + strRect.height / 14 * 42 + 30)
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
