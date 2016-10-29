//
//  FaceTextBubbleConfig.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
private let faceTextConfig = [
    ["bubbleId":"face_text_bubble_0","type":BubbleMetadata.typeEmbeded,"size":[600,442],"scrollableRect":[142,157,285,184],"radio":[0.18,0.48],"startPoint":[300,60],"textLimit":36],
    ["bubbleId":"face_text_bubble_1","type":BubbleMetadata.typeEmbeded,"size":[600,523],"scrollableRect":[100,130,366,304],"radio":[0.18,0.48],"startPoint":[297,5],"textLimit":26],
    ["bubbleId":"face_text_bubble_2","type":BubbleMetadata.typeEmbeded,"size":[600,400],"scrollableRect":[129,145,331,135],"radio":[0.18,0.48],"startPoint":[280,27],"textLimit":30]
]

class BubbleMetadata: BahamutObject {
    static let typeEmbeded = 0;
    static let typeExternal = 1;
    override func getObjectUniqueIdName() -> String {
        return "bubbleId"
    }
    var bubbleId:String!
    var type:Int = BubbleMetadata.typeEmbeded
    var size:[Double]!
    var scrollableRect:[Double]!
    var radio:[Double]!
    var startPoint:[Double]!
    var textLimit:Int = 0
    
}

class FaceTextBubbleConfig {
    private static var externalBubblesMap = { return [String:BubbleMetadata]()}()
    static var defaultBubble:BubbleMetadata = {
        return BubbleMetadata(dictionary:["bubbleId":"face_text_bubble_default","type":BubbleMetadata.typeEmbeded,"size":[793,569],"scrollableRect":[156,156,474,315],"radio":[0.3,0.67],"startPoint":[420,0],"textLimit":32])
    }()
    
    private(set) static var maxTextLengthBubble = defaultBubble
    
    static func getSutableBubble(textLength:Int) -> BubbleMetadata{
        for b in bubbles {
            if b.textLimit > textLength {
                return b
            }
        }
        return bubbles.last ?? defaultBubble
    }
    
    static func registBubble(bubble:BubbleMetadata){
        bubbles.append(bubble)
        bubbles.sortInPlace { (a, b) -> Bool in
            return a.textLimit < b.textLimit
        }
        if bubble.textLimit > maxTextLengthBubble.textLimit{
            maxTextLengthBubble = bubble
        }
        externalBubblesMap.updateValue(bubble, forKey: bubble.bubbleId)
    }
    
    static private var bubbles:[BubbleMetadata] = {
        return faceTextConfig.map({ (config) -> BubbleMetadata in
            let bubble = BubbleMetadata(dictionary:config)
            if bubble.textLimit > maxTextLengthBubble.textLimit{
                maxTextLengthBubble = bubble
            }
            return bubble
        }).sort({ (a, b) -> Bool in
            return a.textLimit < b.textLimit
        })
    }()
}




