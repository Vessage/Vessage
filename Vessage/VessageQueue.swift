//
//  VessageQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class VessageQueue{
    
    static var sharedInstance:VessageQueue{
        return VessageQueue()
    }
    
    func pushNewVideoTo(conversationId:String,fileUrl:NSURL){
        //TODO: delete test
        let testMark = "tn" + ""
        if testMark == "tn"{
            return
        }
        
        ServiceContainer.getService(FileService).sendFileToAliOSS(fileUrl.path!, type: .Video) { (taskId, fileKey) -> Void in
            if fileKey != nil{
                let vessage = Vessage()
                vessage.conversationId = conversationId
                vessage.fileId = fileKey.fileId
                ServiceContainer.getService(VessageService).sendVessage(vessage)
            }else{
                
            }
        }
    }
}