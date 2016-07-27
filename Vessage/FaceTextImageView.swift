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
    
    @IBOutlet weak var messageContentTextView: UILabel!
    
    static func instanceFromXib() -> FaceTextChatBubble{
        let view = NSBundle.mainBundle().loadNibNamed("FaceTextChatBubble", owner: nil, options: nil)[0] as! FaceTextChatBubble
        view.backgroundColor = UIColor.clearColor()
        return view
    }
}

class FaceTextImageView: UIView {
    private var container:UIView!
    private var imageView:UIImageView!{
        didSet{
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
        }
    }
    private var chatBubble:FaceTextChatBubble!
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
    
    func initContainer(container:UIView) {
        self.container = container
        self.imageView = UIImageView()
        self.chatBubble = FaceTextChatBubble.instanceFromXib()
        self.subviews.forEach{$0.removeFromSuperview()}
        self.addSubview(self.imageView)
        self.addSubview(self.chatBubble)
        
        self.chatBubble.hidden = true
    }
    
    private func render(){
        self.frame = container.bounds
        self.imageView.frame = self.bounds
    }
    
    func setTextImage(fileId:String,message:String!) {
        self.render()
        self.chatBubble.messageContent = message
        self.chatBubble.hidden = true
        ServiceContainer.getFileService().setAvatar(self.imageView, iconFileId: fileId, defaultImage: getDefaultFace()) { (suc) in
            self.adjustChatBubble()
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
        setChatBubblePosition(self.center)
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