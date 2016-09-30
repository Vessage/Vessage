//
//  FaceTextImageView.swift
//  Vessage
//
//  Created by AlexChow on 16/7/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class FaceTextChatBubble: UIView {
    private let TAG = "FaceTextChatBubble:%@"
    private let bubbleOriginSize:CGPoint = CGPointMake(793,569);
    private let scrollViewOriginRect:CGRect = CGRectMake(156,156,474,315);
    private let bubbleMinRadio:CGFloat = 0.3
    private let bubbleMaxRadio:CGFloat = 0.6
    private var bubbleStartPointRatio:CGPoint{return CGPointMake(391 / bubbleOriginSize.x,0)}
    private var bubbleTextViewRatio:CGFloat{return 1 * scrollViewOriginRect.height / scrollViewOriginRect.width}
    
    private var scrollViewFinalPos = CGPoint()
    private var textViewFinalWidth:CGFloat = 0
    private var textViewFinalHeight:CGFloat = 0
    private var scrollViewFinalHeight:CGFloat = 0
    private var finalRatio:CGFloat = 0.3
    private var finalImageViewWidth:CGFloat = 0
    private var finalImageViewHeight:CGFloat = 0
    private var bubbleStartPoint = CGPoint()
    
    private var bubbleText:String!
    
    var containerWidth:CGFloat = 0
    
    private var bubbleTextView:UITextView!{
        didSet{
            bubbleTextView.layoutIfNeeded()
            bubbleTextView.backgroundColor = UIColor.clearColor()
            bubbleTextView.scrollEnabled = true
            bubbleTextView.editable = false
            self.addSubview(bubbleTextView)
        }
    }
    
    private var bubbleImageView:UIImageView!{
        didSet{
            bubbleImageView.image = UIImage(named: "cloud_bubble")
            bubbleImageView.layoutIfNeeded()
            bubbleImageView.contentMode = .ScaleAspectFit
            self.addSubview(bubbleImageView)
            self.sendSubviewToBack(bubbleImageView)
        }
    }
    
    func initSubviews() {
        bubbleTextView = UITextView()
        bubbleImageView = UIImageView()
    }
    
    func scrollText(y:CGFloat) {
        
    }
}

extension FaceTextChatBubble{
    func setBubbleText(bubbleText:String) {
        self.bubbleText = bubbleText
        bubbleTextView.text = bubbleText
        measureViewSize()
        setMeasuredValues()
    }
    
    func getBubbleStartPoint() -> CGPoint {
        return CGPoint(x: bubbleStartPoint.x, y: bubbleStartPoint.y)
    }
    
    private func setMeasuredValues(){
        bubbleImageView.frame = CGRectMake(0, 0, finalImageViewWidth, finalImageViewHeight)
        bubbleTextView.frame = CGRectMake(scrollViewFinalPos.x,scrollViewFinalPos.y,textViewFinalWidth,scrollViewFinalHeight)
        self.frame.size.height = finalImageViewHeight
        self.frame.size.width = finalImageViewWidth
    }
    
    private func measureViewSize() {
        debugLog(TAG,"------------------Start Measure------------------------")
        debugLog(TAG,"containerWidth:\(containerWidth)")
        var widthRadio = bubbleMinRadio
        let tv = bubbleTextView
        
        for (; widthRadio <= bubbleMaxRadio; widthRadio += 0.01) {
            textViewFinalWidth = containerWidth * widthRadio
            textViewFinalHeight = textViewFinalWidth * bubbleTextViewRatio
            
            tv.frame.size.width = textViewFinalWidth;
            tv.layoutIfNeeded()
            tv.sizeToFit()
            let measuredHeight = tv.contentSize.height
            scrollViewFinalHeight = textViewFinalHeight;
            
            debugLog(TAG,"radio:\(widthRadio)")
            debugLog(TAG,"measuredHeight:\(measuredHeight)")
            debugLog(TAG,"scrollViewFinalHeight:\(scrollViewFinalHeight)")
            debugLog(TAG,"textViewFinalWidth:\(textViewFinalWidth)")
            
            if (measuredHeight <= textViewFinalHeight) {
                debugLog(TAG,"textViewFinalHeight:\(textViewFinalHeight)");
                break
            } else if (widthRadio == bubbleMaxRadio) {
                textViewFinalHeight = measuredHeight
            }
            debugLog(TAG,"textViewFinalHeight:\(textViewFinalHeight)")
        }
        
        debugLog(TAG,"Select Radio:\(widthRadio)")
        finalRatio = textViewFinalWidth / scrollViewOriginRect.width
        finalImageViewWidth = bubbleOriginSize.x * finalRatio
        finalImageViewHeight = finalImageViewWidth * bubbleTextViewRatio
        debugLog(TAG,"finalImageViewWidth:\(finalImageViewWidth)")
        debugLog(TAG,"finalImageViewHeight:\(finalImageViewHeight)")
        scrollViewFinalPos.x = scrollViewOriginRect.origin.x * finalRatio
        scrollViewFinalPos.y = scrollViewOriginRect.origin.y * finalRatio
        debugLog(TAG,"scrollViewFinalPos:\(scrollViewFinalPos)");
        bubbleStartPoint.x = finalImageViewWidth * bubbleStartPointRatio.x
        bubbleStartPoint.y = finalImageViewHeight * bubbleStartPointRatio.y
        debugLog(TAG,"bubbleStartPoint:\(bubbleStartPoint)");
        debugLog(TAG,"------------------End Measure------------------------");
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
        self.chatBubble = FaceTextChatBubble()
        self.chatBubble.initSubviews()
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
        self.chatBubble.containerWidth = self.container.bounds.width
        self.chatBubble.setBubbleText(message + message + message)
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
        
        let bubbleStartPoint = chatBubble.getBubbleStartPoint();
        let movePoint = CGPointMake(position.x - bubbleStartPoint.x,position.y - bubbleStartPoint.y );
        debugLog("chatBubbleFrame:\(chatBubble.frame)")
        debugLog("movePoint:\(movePoint)")
        chatBubble.frame.origin = movePoint
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
