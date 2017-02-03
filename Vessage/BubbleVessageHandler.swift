//
//  BubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/27.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

protocol BubbleVessageHandler {
    func getContentViewSize(vc:UIViewController,vessage:Vessage,maxLimitedSize:CGSize,contentView:UIView) -> CGSize
    func getContentView(vc:UIViewController,vessage:Vessage) -> UIView
    func presentContent(vc:UIViewController,vessage:Vessage,contentView:UIView)
}

class TipsBubbleVessageHandler:NSObject, BubbleVessageHandler {
    
    func getVessageTipsMessage(vessage:Vessage) -> String {
        let dict = vessage.getBodyDict()
        if let locMsg = dict["locMsg"] as? String{
            return locMsg
        }else if let msg = dict["msg"] as? String{
            return msg
        }else{
            return ""
        }
    }
    
    func presentContent(vc:UIViewController, vessage: Vessage, contentView: UIView) {
        
    }
    
    func getContentView(vc:UIViewController,vessage: Vessage) -> UIView {
        let label = UILabel()
        label.textAlignment = .Center
        label.numberOfLines = 0
        return label
    }
    
    func getContentViewSize(vc:UIViewController,vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel {
            label.text = getVessageTipsMessage(vessage)
            return label.sizeThatFits(maxLimitedSize)
        }
        return CGSizeZero
    }
}

private let NoBubbleVessageHandlerInstance:NoBubbleVessageHandler = NoBubbleVessageHandler()
private let UnknowBubbleVessageHandlerInstance:UnknowBubbleVessageHandler = UnknowBubbleVessageHandler()

class NoBubbleVessageHandler:TipsBubbleVessageHandler {
    override func getVessageTipsMessage(vessage: Vessage) -> String {
        return "NO_VESSAGE_TIPS".localizedString()
    }
}

class UnknowBubbleVessageHandler:TipsBubbleVessageHandler {
    
    override func getVessageTipsMessage(vessage: Vessage) -> String {
        return "UNKNOW_VESSAGE_TYPE".localizedString()
    }
    
    override func getContentView(vc:UIViewController,vessage: Vessage) -> UIView {
        let label = UILabel()
        label.textAlignment = .Center
        label.numberOfLines = 0
        label.userInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UnknowBubbleVessageHandler.onTapContentView(_:))))
        return label
    }
    
    func onTapContentView(_:UITapGestureRecognizer) -> Void {
        #if DEBUG
            debugLog("Go Appstore")
        #else
            let url = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=\(VessageConfig.bahamutConfig.appStoreId)"
            UIApplication.sharedApplication().openURL(NSURL(string: url)!)
        #endif
    }
}

class BubbleVessageHandlerManager {
    private static var handlerMap = [Int:BubbleVessageHandler]()
    
    static func release(){
        handlerMap.removeAll()
    }
    
    static func registHandler<T:BubbleVessageHandler>(vessageType:Int,handler:T){
        handlerMap.updateValue(handler, forKey: vessageType)
    }
    
    static func getNoVessageHandler() -> BubbleVessageHandler{
        return NoBubbleVessageHandlerInstance
    }
    
    static func getBubbleVessageHandler(vessage:Vessage) -> BubbleVessageHandler{
        if let handler = handlerMap[vessage.typeId]{
            return handler
        }
        return UnknowBubbleVessageHandlerInstance
    }
}
