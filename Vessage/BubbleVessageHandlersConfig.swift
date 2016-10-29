//
//  BubbleVessageHandlersConfig.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
extension BubbleVessageHandlerManager{
    static func loadEmbededHandlers(){
        registHandler(Vessage.typeImage, handler: ImageBubbleVessageHandler())
        registHandler(Vessage.typeFaceText, handler: FaceTextBubbleVessageHandler())
        registHandler(Vessage.typeChatVideo, handler: VideoBubbleVessageHandler())
    }
}
