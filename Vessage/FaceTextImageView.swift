//
//  FaceTextImageView.swift
//  Vessage
//
//  Created by AlexChow on 16/7/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

extension BubbleMetadata{
    func getOriginSize() -> CGPoint {
        return CGPointMake(CGFloat(size[0]), CGFloat(size[1]))
    }
    
    func getScrollOriginRect() -> CGRect {
        return CGRectMake(CGFloat(scrollableRect[0]), CGFloat(scrollableRect[1]), CGFloat(scrollableRect[2]), CGFloat(scrollableRect[3]))
    }
    
    func getMinRadio() -> CGFloat {
        return CGFloat(radio[0])
    }
    
    func getMaxRadio() -> CGFloat {
        return CGFloat(radio[1])
    }
    
    func getStartPointRatio() -> CGPoint {
        return CGPointMake(CGFloat(startPoint[0] / size[0]),CGFloat(startPoint[1] / size[1]))
    }
    
    func getTextViewRatio() -> CGFloat {
        return CGFloat(1 * scrollableRect[3] / scrollableRect[2])
    }
    
    func getBubbleImage() -> UIImage? {
        if type == BubbleMetadata.typeEmbeded {
            return UIImage(named: bubbleId)
        }
        return nil
    }
}


class FaceTextChatBubble: UIView {
    
    class VerticalCenterTextView: UITextView {
        
        private var contentLabel:UILabel = {return UILabel()}()
        
        override var font: UIFont?{
            didSet{
                contentLabel.font = font
            }
        }
        
        override func drawRect(rect: CGRect) {
            super.drawRect(rect)
            if contentLabel.hidden {
                contentLabel.removeFromSuperview()
            }else{
                contentLabel.font = self.font
                contentLabel.textAlignment = .Center
                contentLabel.numberOfLines = 0
                self.addSubview(contentLabel)
                contentLabel.frame = self.bounds
            }
            
        }
        
        private var contentText:String?
        
        override var scrollEnabled: Bool{
            didSet{
                if false == scrollEnabled {
                    contentText = text
                    text = nil
                }else{
                    text = contentText
                }
                contentLabel.hidden = scrollEnabled
                contentLabel.text = contentText
            }
        }
    }
    
    private let TAG = "FaceTextChatBubble:%@"

    private var fontSize:CGFloat = 14.3
    
    private var scrollViewFinalPos = CGPoint()
    private var textViewFinalWidth:CGFloat = 0
    private var textViewFinalHeight:CGFloat = 0
    private var scrollViewFinalHeight:CGFloat = 0
    private var finalRatio:CGFloat = 0.3
    private var finalImageViewWidth:CGFloat = 0
    private var finalImageViewHeight:CGFloat = 0
    private var bubbleStartPoint = CGPoint()
    
    private var bubbleMetadata:BubbleMetadata! = FaceTextBubbleConfig.embededBubbles.first
    
    private var bubbleText:String!
    
    var containerWidth:CGFloat = 0
    
    private var bubbleTextView:UITextView!{
        didSet{
            bubbleTextView.layoutIfNeeded()
            bubbleTextView.backgroundColor = UIColor.clearColor()
            bubbleTextView.scrollEnabled = true
            bubbleTextView.editable = false
            bubbleTextView.textAlignment = .Center
            bubbleTextView.contentMode = .Center
            bubbleTextView.font = UIFont.systemFontOfSize(fontSize)
            self.addSubview(bubbleTextView)
        }
    }
    
    private var bubbleImageView:UIImageView!{
        didSet{
            bubbleImageView.layoutIfNeeded()
            bubbleImageView.contentMode = .ScaleToFill
            self.addSubview(bubbleImageView)
            self.sendSubviewToBack(bubbleImageView)
        }
    }
}

extension FaceTextChatBubble{
    
    func initSubviews() {
        bubbleTextView = VerticalCenterTextView()
        bubbleImageView = UIImageView()
    }
    
    func scrollText(y:CGFloat) {
        if !bubbleTextView.scrollEnabled {
            return
        }
        let v = y / -80
        var fy = bubbleTextView.contentOffset.y + v
        if fy < 0 {
            fy = 0
        }else if fy > bubbleTextView.contentSize.height - bubbleTextView.frame.height{
            fy = bubbleTextView.contentSize.height - bubbleTextView.frame.height
        }
        bubbleTextView.contentOffset.y = fy
    }
    
    func setBubbleText(bubbleText:String) {
        self.bubbleText = "abcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdefbcdef"
        bubbleTextView.text = self.bubbleText
        bubbleMetadata = FaceTextBubbleConfig.randomBubble
        if let img = bubbleMetadata?.getBubbleImage(){
            bubbleImageView.image = img
        }else{
            bubbleMetadata = FaceTextBubbleConfig.defaultBubble
            bubbleImageView.image = bubbleMetadata?.getBubbleImage()
        }
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
        
        #if DEBUG1
            debugPrint(bubbleTextView.contentSize)
            debugPrint(bubbleTextView.frame.size)
            bubbleTextView.layer.borderColor = UIColor.redColor().CGColor
            bubbleTextView.layer.borderWidth = 1
            
            bubbleImageView.layer.borderColor = UIColor.blueColor().CGColor
            bubbleImageView.layer.borderWidth = 1
        #endif
    }
    
    private func measureViewSize() {
        debugLog(TAG,"------------------Start Measure------------------------")
        debugLog(TAG,"containerWidth:\(containerWidth)")
        let tv = bubbleTextView
        
        let bubbleTextViewRatio = bubbleMetadata.getTextViewRatio()
        let scrollViewOriginRect = bubbleMetadata.getScrollOriginRect()
        let bubbleMinRadio = bubbleMetadata.getMinRadio()
        let bubbleMaxRadio = bubbleMetadata.getMaxRadio()
        let bubbleOriginSize = self.bubbleMetadata.getOriginSize()
        let bubbleStartPointRatio = bubbleMetadata.getStartPointRatio()
 
        for widthRadio in bubbleMinRadio.stride(to: bubbleMaxRadio, by: 0.01){
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
                debugLog(TAG,"Select Radio:\(widthRadio)")
                bubbleTextView.scrollEnabled = false
                break
            } else if (widthRadio == bubbleMaxRadio) {
                textViewFinalHeight = measuredHeight
                bubbleTextView.scrollEnabled = true
                bubbleTextView.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated: true)
                debugLog(TAG,"Select Radio:\(widthRadio)")
            }
            debugLog(TAG,"textViewFinalHeight:\(textViewFinalHeight)")
        }
        finalRatio = textViewFinalWidth / scrollViewOriginRect.width
        finalImageViewWidth = bubbleOriginSize.x * finalRatio
        finalImageViewHeight = bubbleOriginSize.y * finalRatio
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
        self.chatBubble.setBubbleText(message)
        self.chatBubble.hidden = true
        self.imageView.hidden = true
        self.loadingImageView.center = self.center
        self.addSubview(self.loadingImageView)
        self.loadingImageView.startAnimating()
        ServiceContainer.getFileService().setImage(self.imageView, iconFileId: fileId, defaultImage: getDefaultFace()) { (suc) in
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
                    ServiceContainer.getFileService().setImage(self.imageView, iconFileId: fileId,defaultImage: getDefaultFace()){ setted in
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
    
    func scrollBubbleText(y:CGFloat) {
        chatBubble?.scrollText(y)
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
                
                #if DEBUG1
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
        self.chatBubble.bubbleTextView.flashScrollIndicators()
        UIView.commitAnimations()
    }
}
