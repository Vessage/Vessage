//
//  BubbleVessageHandler.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/27.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

protocol BubbleVessageHandler {
    func getContentViewSize(vessage:Vessage,maxLimitedSize:CGSize,contentView:UIView) -> CGSize
    func getContentView(vessage:Vessage) -> UIView
    func presentContent(oldVessage:Vessage?,newVessage:Vessage,contentView:UIView)
}

protocol PreparePresentContentHandler:BubbleVessageHandler {
    func preparePresentContent(vessage:Vessage)
}

protocol UnloadPresentContentHandler:BubbleVessageHandler {
    func unloadPresentContent(vessage:Vessage)
}

private let NoBubbleVessageHandlerInstance:NoBubbleVessageHandler = NoBubbleVessageHandler()
private let UnknowBubbleVessageHandlerInstance:UnknowBubbleVessageHandler = UnknowBubbleVessageHandler()
class NoBubbleVessageHandler:NSObject, BubbleVessageHandler {
    
    func presentContent(oldVessage: Vessage?, newVessage: Vessage, contentView: UIView) {
        if let label = contentView as? UILabel{
            label.text = "NO_VESSAGE_TIPS".localizedString()
        }
    }
    
    func getContentView(vessage: Vessage) -> UIView {
        let noVessageLabel = UILabel()
        noVessageLabel.textAlignment = .Center
        noVessageLabel.numberOfLines = 0
        return noVessageLabel
    }
    
    func getContentViewSize(vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel {
            label.text = "NO_VESSAGE_TIPS".localizedString()
            return label.sizeThatFits(maxLimitedSize)
        }
        return CGSizeZero
    }
}

class UnknowBubbleVessageHandler: NSObject,BubbleVessageHandler {
    
    func presentContent(oldVessage: Vessage?, newVessage: Vessage, contentView: UIView) {
        if let label = contentView as? UILabel{
            label.text = "UNKNOW_VESSAGE_TYPE".localizedString()
        }
    }
    
    func getContentView(vessage: Vessage) -> UIView {
        let label = UILabel()
        label.textAlignment = .Center
        label.numberOfLines = 0
        label.userInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UnknowBubbleVessageHandler.onTapContentView(_:))))
        return label
    }
    
    func getContentViewSize(vessage: Vessage, maxLimitedSize: CGSize,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel {
            label.text = "UNKNOW_VESSAGE_TYPE".localizedString()
            return label.sizeThatFits(maxLimitedSize)
        }
        return CGSizeZero
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
