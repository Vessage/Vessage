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
    private let TAG = "FaceTextChatBubble:%@"

    private var fontSize:CGFloat = 13
    
    private var scrollViewFinalPos = CGPoint()
    private var textViewFinalWidth:CGFloat = 0
    private var textViewFinalHeight:CGFloat = 0
    private var scrollViewFinalHeight:CGFloat = 0
    private var finalRatio:CGFloat = 0.3
    private var finalImageViewWidth:CGFloat = 0
    private var finalImageViewHeight:CGFloat = 0
    private var bubbleStartPoint = CGPoint()
    
    private var bubbleMetadata:BubbleMetadata! = nil
    
    private var bubbleText:String!
    
    var containerWidth:CGFloat = 0
    
    private var bubbleTextView:UITextView!{
        didSet{
            bubbleTextView.layoutIfNeeded()
            bubbleTextView.backgroundColor = UIColor.clearColor()
            bubbleTextView.editable = false
            bubbleTextView.autocorrectionType = .No
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
        bubbleTextView = UITextView()
        bubbleImageView = UIImageView()
    }
    
    func scrollText(y:CGFloat) -> Bool{
        if !bubbleTextView.scrollEnabled {
            return false
        }
        let v = y / -80
        var fy = bubbleTextView.contentOffset.y + v
        if fy < 0 {
            fy = 0
        }else if fy > bubbleTextView.contentSize.height - bubbleTextView.frame.height{
            fy = bubbleTextView.contentSize.height - bubbleTextView.frame.height
        }
        bubbleTextView.contentOffset.y = fy
        return true
    }
    
    func setBubbleText(bubbleText:String) {
        self.bubbleText = bubbleText
        bubbleMetadata = FaceTextBubbleConfig.getSutableBubble(bubbleText.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
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
        
        #if DEBUG
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
        self.layoutIfNeeded()
        bubbleTextView.textContainerInset = UIEdgeInsetsZero
        bubbleTextView.textAlignment = .Left
        bubbleTextView.font = UIFont.systemFontOfSize(fontSize)
        let tv = bubbleTextView
        tv.text = bubbleText
        let bubbleTextViewRatio = bubbleMetadata.getTextViewRatio()
        let scrollViewOriginRect = bubbleMetadata.getScrollOriginRect()
        let bubbleMinRadio = bubbleMetadata.getMinRadio()
        let bubbleMaxRadio = bubbleMetadata.getMaxRadio()
        let bubbleOriginSize = self.bubbleMetadata.getOriginSize()
        let bubbleStartPointRatio = bubbleMetadata.getStartPointRatio()
 
        for widthRadio in bubbleMinRadio.stride(to: bubbleMaxRadio, by: 0.01){
            textViewFinalWidth = containerWidth * widthRadio
            textViewFinalHeight = textViewFinalWidth * bubbleTextViewRatio
            tv.hidden = false
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
    
    var messages = [String]()
    var messageIndex = -1{
        didSet{
            if messageIndex >= 0 {
                let m = messages[messageIndex]
                chatBubble?.setBubbleText(m)
                debugLog("Text Message:%@", m)
            }
        }
    }
    
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
        self.chatBubble = FaceTextChatBubble()
        self.chatBubble.initSubviews()
        self.imageView = UIImageView()
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
    
    private static let sentenceRegex = "[^,.;!?，。；！？\\n]+[,.;!?，。；！？\\n]+"
    private static let messageEndWithSeparatorPrefix = "[,.;!?，。；！？\n]+$"
    
    static func separatMessage(message:String) -> [String]{
        var msgs = [String]()
        var tmpMessage = message
        let maxBubbleLimit = FaceTextBubbleConfig.maxTextLengthBubble.textLimit
        
        var hasSuffix = false
        
        if let regex = RegexMatcher(messageEndWithSeparatorPrefix).regex{
            if regex.matchesInString(tmpMessage, options: [], range: NSMakeRange(0, tmpMessage.characters.count)).count > 0{
                hasSuffix = true
            }
        }
        
        if !hasSuffix {
            tmpMessage = "\(tmpMessage)."
        }
        
        let rm = RegexMatcher(FaceTextImageView.sentenceRegex)
        let range = NSMakeRange(0, tmpMessage.characters.count)
        //let range = NSMakeRange(0, tmpMessage.lengthOfBytesUsingEncoding(NSUnicodeStringEncoding))
        if let matches = rm.regex?.matchesInString(tmpMessage, options: [],range: range){
            for match in matches {
                if let r = match.range.toRange(){
                    let msg = tmpMessage.substringWithRange(r)
                    msgs.append(msg)
                }
            }
        }else{
            msgs.append(message)
        }
        var tmpMsgs = [String]()
        var i = 0
        while i < msgs.count {
            let m = msgs[i]
            let l = m.lengthOfBytesUsingEncoding(NSUnicodeStringEncoding)
            if i < msgs.count - 2{
                let m1 = msgs[i + 1]
                let l1 = m.lengthOfBytesUsingEncoding(NSUnicodeStringEncoding)
                if l + l1 < maxBubbleLimit{
                    msgs[i + 1] = "\(m)\(m1)"
                }else{
                    tmpMsgs.append(msgs[i])
                }
            }else{
                tmpMsgs.append(msgs[i])
            }
            i += 1
        }
        msgs = tmpMsgs
        
        #if DEBUG
            debugPrint("___________________________________")
            msgs.forEach({ (m) in
                debugPrint(m)
            })
            debugPrint("___________________________________")
        #endif
        
        return msgs
    }
    
    func setTextImage(fileId:String!,message:String!,onMessagePresented:(()->Void)? = nil) {
        self.imageLoaded = false
        self.render()
        self.chatBubble.containerWidth = self.container.bounds.width
        //self.chatBubble.setBubbleText(message)
        messages.removeAll()
        messages.appendContentsOf(FaceTextImageView.separatMessage(message))
        messageIndex = messages.count > 0 ? 0 : -1
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
    
    var hasNextText:Bool{
        return messages.count > 0 && messageIndex < messages.count - 1
    }
    
    var hasPreviousText:Bool{
        return messages.count > 0 && messageIndex > 0
    }
    
    func showNextText() -> Bool {
        if hasNextText {
            messageIndex += 1
            return true
        }
        return false
    }
    
    func showPreviousText() -> Bool {
        if hasPreviousText {
            messageIndex -= 1
            return true
        }
        return false
    }
    
    func scrollBubbleText(y:CGFloat) ->Bool {
        return chatBubble?.scrollText(y) ?? false
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
