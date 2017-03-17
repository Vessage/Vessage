//
//  TextBubbleVessageHandler.swift
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(TextFullScreen.onTap(_:)))
        self.view.addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TextFullScreen.longPress(_:)))
        self.view.addGestureRecognizer(longPress)
        
    }
    
    func onTap(ges:UIGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func longPress(ges:UILongPressGestureRecognizer) {
        if ges.state == .Began {
            showCopyTextAlert()
        }
    }
    
    private func showCopyTextAlert() {
        let alert = UIAlertController.create(title: nil, message: nil, preferredStyle: .ActionSheet)
        let copyContent = UIAlertAction(title: "COPY_CONTENT".localizedString(), style: .Default) { (ac) in
            UIPasteboard.generalPasteboard().string = self.textLabel.text
            self.showAlert(nil, msg: "TEXT_COPIED".localizedString())
        }
        let cancel = ALERT_ACTION_CANCEL
        alert.addAction(copyContent)
        alert.addAction(cancel)
        self.showAlert(alert)
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

class TextBubbleVessageHandler: NSObject,BubbleVessageHandler {
    
    static let viewPool:ViewPool<VessageContentLabel> = {
        return ViewPool<VessageContentLabel>()
    }()
    
    class VessageContentLabel: UILabel {
        weak var vc:UIViewController!
        weak var vessage:Vessage!
        
        func initLabel(vc:UIViewController,vessage: Vessage){
            self.vc = vc
            self.vessage = vessage
            self.numberOfLines = 0
            self.userInteractionEnabled = true
            let ges = UITapGestureRecognizer(target: self, action: #selector(VessageContentLabel.onTapTextLabel(_:)))
            self.addGestureRecognizer(ges)
            self.textAlignment = .Center
        }
        
        override func removeFromSuperview() {
            text = nil
            vc = nil
            vessage = nil
            setNeedsLayout()
            layoutIfNeeded()
            super.removeFromSuperview()
        }
        
        func onTapTextLabel(ges:UITapGestureRecognizer) {
            if let label = ges.view as? UILabel,let controller = self.vc{
                let c = TextFullScreen()
                controller.presentViewController(c, animated: true, completion: {
                    c.text = label.text
                    c.date = self.vessage?.getSendTime()
                })
            }
        }
    }
    
    func getContentViewSize(vc:UIViewController,vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel{
            label.text = vessage.getBodyDict()["textMessage"] as? String
            
            var size = label.sizeThatFits(maxLimitedSize)
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
    
    func getContentView(vc:UIViewController,vessage: Vessage) -> UIView {
        if let label = TextBubbleVessageHandler.viewPool.getFreeView() {
            label.initLabel(vc, vessage: vessage)
            return label
        }else{
            let label = VessageContentLabel()
            label.initLabel(vc, vessage: vessage)
            TextBubbleVessageHandler.viewPool.pushNewPooledView(label)
            return label
        }
        
    }
    
    func presentContent(vc:UIViewController, vessage: Vessage,contentView:UIView) {
        if let label = contentView as? UILabel {
            dispatch_async(dispatch_get_main_queue(), { 
                let bodyDict = vessage.getBodyDict()
                let msg = bodyDict["textMessage"] as? String
                label.text = msg
                ServiceContainer.getVessageService().readVessage(vessage)
            })
            
        }
    }
    
    
}
