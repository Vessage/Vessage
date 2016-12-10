//
//  FaceTextBubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class TextFullScreen: UIViewController {
    private var scrollView:UIScrollView!
    private var textLabel:UILabel!
    private var dateTimeLabel:UILabel!
    
    var date:NSDate?{
        didSet{
            updateDateTimeLabel()
        }
    }
    
    var text:String!{
        didSet{
            textLabel?.text = text
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalTransitionStyle = .CrossDissolve
        self.view.backgroundColor = UIColor.whiteColor()
        self.scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        self.textLabel = UILabel()
        self.textLabel.numberOfLines = 0
        self.scrollView.addSubview(textLabel)
        self.dateTimeLabel = UILabel()
        self.dateTimeLabel.textColor = UIColor.lightGrayColor()
        self.view.addSubview(dateTimeLabel)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TextFullScreen.onTap(_:))))
    }
    
    func onTap(_:UITapGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.frame = self.view.bounds
        textLabel.textAlignment = .Center
        textLabel.font = UIFont.systemFontOfSize(20)
        textLabel.text = text
        var size = textLabel.sizeThatFits(self.scrollView.bounds.size)
        if size.height < self.scrollView.bounds.height {
            size.height = self.scrollView.bounds.height
        }
        
        if size.width < self.scrollView.bounds.width {
            size.width = self.scrollView.bounds.width
        }
        
        textLabel.frame = CGRect(origin: CGPointZero, size: size)
        dateTimeLabel.font = UIFont.systemFontOfSize(18)
        
    }
    
    func updateDateTimeLabel() {
        dateTimeLabel.text = date?.toFriendlyString()
        dateTimeLabel.sizeToFit()
        dateTimeLabel.frame.origin.x = self.view.frame.width - 10 - dateTimeLabel.frame.width
        dateTimeLabel.frame.origin.y = self.view.frame.height - 6 - dateTimeLabel.frame.height
    }
}

class FaceTextBubbleVessageHandler: NSObject,BubbleVessageHandler,RequestPlayVessageManagerDelegate {
    
    private var getPlayVessageManagerDelegate:GetPlayVessageManagerDelegate?
    
    private var vessage:Vessage?
    
    private var playVessageManager:PlayVessageManager?{
        return getPlayVessageManagerDelegate?.getPlayVessageManager()
    }
    
    func setGetPlayVessageManagerDelegate(delegate: GetPlayVessageManagerDelegate) {
        self.getPlayVessageManagerDelegate = delegate
    }
    
    func unsetGetPlayVessageManagerDelegate() {
        self.getPlayVessageManagerDelegate = nil
    }
    
    func getContentViewSize(vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel{
            label.text = vessage.getBodyDict()["textMessage"] as? String
            
            let mSize = CGSize(width: maxLimitedSize.width * CGFloat(0.8), height: maxLimitedSize.height)
            var size = label.sizeThatFits(mSize)
            if size.width < 48 {
                size.width = 48
                label.textAlignment = .Center
            }else{
                label.textAlignment = .Left
            }
            return size
        }
        return CGSizeZero
    }
    
    func getContentView(vessage: Vessage) -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.userInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FaceTextBubbleVessageHandler.onTapTextLabel(_:))))
        label.textAlignment = .Center
        return label
    }
    
    func presentContent(oldVessage: Vessage?, newVessage: Vessage,contentView:UIView) {
        if let label = contentView as? UILabel {
            let bodyDict = newVessage.getBodyDict()
            label.text = bodyDict["textMessage"] as? String
            self.vessage = newVessage
            ServiceContainer.getVessageService().readVessage(newVessage)
        }
    }
    
    func onTapTextLabel(ges:UITapGestureRecognizer) {
        if let label = ges.view as? UILabel{
            let c = TextFullScreen()
            playVessageManager?.rootController.presentViewController(c, animated: true, completion: {
                c.text = label.text
                c.date = self.vessage?.getSendTime()
            })
        }
    }
}
