//
//  VessageHandlerFactory.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VessageHandlerFactory{
    
    private var manager:PlayVessageManager
    private var vessageView:UIView
    
    init(manager:PlayVessageManager,vessageView:UIView) {
        self.manager = manager
        self.vessageView = vessageView
    }
    
    private var vessageHandlers = [Int:VessageHandler]()
    
    func generateNoVessageHandler() -> VessageHandler{
        if let h = vessageHandlers[Vessage.typeNoVessage]{
            return h
        }else{
            let handler = NoVessageHandler(manager: self.manager, container: self.vessageView)
            vessageHandlers.updateValue(handler, forKey: Vessage.typeNoVessage)
            return handler
        }
    }
    
    func generateVessageHandler(typeId:Int) -> VessageHandler{
        var handler:VessageHandler? = vessageHandlers[typeId]
        if handler != nil {
            return handler!
        }
        switch typeId {
        case Vessage.typeChatVideo:
            handler = VideoVessageHandler(manager: self.manager,container: self.vessageView)
        case Vessage.typeFaceText:
            handler = FaceTextVessageHandler(manager: self.manager, container: self.vessageView)
        case Vessage.typeImage:
            handler = ImageVessageHandler(manager: self.manager, container: self.vessageView)
        default:
            if let h = vessageHandlers[Vessage.typeUnknow]{
                handler = h
            }else{
                handler = UnknowVessageHandler(manager: self.manager, container: self.vessageView)
                vessageHandlers.updateValue(handler!, forKey: Vessage.typeUnknow)
            }
            debugLog("Unknow Vessage TypeId:\(typeId)")
            return handler!
        }
        vessageHandlers.updateValue(handler!, forKey: typeId)
        return handler!
    }
    
    func release() {
        vessageHandlers.forEach { (key,handler) in
            handler.releaseHandler()
        }
        vessageHandlers.removeAll()
    }
}
