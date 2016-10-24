//
//  FaceTextBubbleConfig.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/24.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
private let faceTextConfig = [
    ["bubbleId":"face_text_bubble_0","type":BubbleMetadata.typeEmbeded,"size":[600,442],"scrollableRect":[142,157,285,184],"radio":[0.23,0.48],"startPoint":[300,60]],
    ["bubbleId":"face_text_bubble_1","type":BubbleMetadata.typeEmbeded,"size":[600,523],"scrollableRect":[100,130,366,304],"radio":[0.23,0.48],"startPoint":[297,5]],
    ["bubbleId":"face_text_bubble_2","type":BubbleMetadata.typeEmbeded,"size":[600,400],"scrollableRect":[129,145,331,135],"radio":[0.23,0.48],"startPoint":[280,27]],
 
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
}

class FaceTextBubbleConfig {
    private static var externalBubbles = { return [BubbleMetadata]()}()
    private static var externalBubblesMap = { return [String:BubbleMetadata]()}()
    static var defaultBubble:BubbleMetadata = {
        return BubbleMetadata(dictionary:["bubbleId":"face_text_bubble_default","type":BubbleMetadata.typeEmbeded,"size":[793,569],"scrollableRect":[156,156,474,315],"radio":[0.3,0.67],"startPoint":[420,0]])
    }()
    
    static var randomBubble:BubbleMetadata{
        if random() % 10 > 5 || externalBubbles.count == 0{
            return embededBubbles[random() % embededBubbles.count]
        }else{
            return externalBubbles[random() % externalBubbles.count]
        }
    }
    
    static func registBubble(bubble:BubbleMetadata){
        externalBubbles.append(bubble)
        externalBubblesMap.updateValue(bubble, forKey: bubble.bubbleId)
    }
    
    static private(set) var embededBubbles:[BubbleMetadata] = {
        return faceTextConfig.map({ (config) -> BubbleMetadata in
            return BubbleMetadata(dictionary:config)
        })
    }()
}




