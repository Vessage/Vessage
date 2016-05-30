//
//  ShareHelper.swift
//  Vessage
//
//  Created by AlexChow on 16/5/30.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class ShareHelper{
    
    private static func sendTellFriendWX(type:UInt32){
        let url = "http://a.app.qq.com/o/simple.jsp?pkgname=cn.bahamut.vessage"
        let textMsg = "TELL_FRIEND_MESSAGE".localizedString()
        let msg = WXMediaMessage()
        msg.title = VessageConfig.appName
        msg.description = textMsg
        msg.setThumbImage(UIImage(named: "shareIcon"))
        
        let wxobj = WXWebpageObject()
        wxobj.webpageUrl = url
        
        msg.mediaObject = wxobj
        
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = msg
        req.scene = Int32(type)
        
        WXApi.sendReq(req)
    }
    
    static func showTellVegeToFriendsAlert(vc:UIViewController){
        
        let alert = UIAlertController(title: "TELL_FRIENDS".localizedString(), message: nil, preferredStyle: .ActionSheet)
        let wxAction = UIAlertAction(title: "WECHAT_SESSION".localizedString(), style: .Default) { (ac) in
            sendTellFriendWX(WXSceneSession.rawValue)
        }
        alert.addAction(wxAction)
        
        let wxTimeLineAction = UIAlertAction(title: "WECHAT_TIMELINE".localizedString(), style: .Default) { (ac) in
            sendTellFriendWX(WXSceneTimeline.rawValue)
        }
        alert.addAction(wxTimeLineAction)
        
        let smsAction = UIAlertAction(title: "SMS".localizedString(), style: .Default) { (ac) in
            let url = "http://t.cn/RqW8tuW"
            let textMsg = "TELL_FRIEND_MESSAGE".localizedString()
            vc.showSendSMSTextView([], body: "\(textMsg) \(url)")
        }
        
        alert.addAction(smsAction)
        alert.addAction(ALERT_ACTION_CANCEL)
        vc.showAlert(alert)
    }
    
    static func showTellTextMsgToFriendsAlert(vc:UIViewController,content:String,smsReceiver:String? = nil){
        let alert = UIAlertController(title: "TELL_FRIENDS".localizedString(), message: nil, preferredStyle: .ActionSheet)
        let wxAction = UIAlertAction(title: "WECHAT_SESSION".localizedString(), style: .Default) { (ac) in
            let msg = WXMediaMessage()
            msg.title = VessageConfig.appName
            msg.description = content
            msg.setThumbImage(UIImage(named: "shareIcon"))
            
            let wxobj = WXTextObject()
            wxobj.contentText = content
            
            msg.mediaObject = wxobj
            
            let req = SendMessageToWXReq()
            req.bText = false
            req.message = msg
            req.scene = Int32(WXSceneSession.rawValue)
            
            WXApi.sendReq(req)
        }
        alert.addAction(wxAction)
        
        let smsAction = UIAlertAction(title: "SMS".localizedString(), style: .Default) { (ac) in
            if let receiver = smsReceiver{
                vc.showSendSMSTextView([receiver], body: content)
            }else{
                vc.showSendSMSTextView([], body: content)
            }
            
        }
        
        alert.addAction(smsAction)
        alert.addAction(ALERT_ACTION_CANCEL)
        vc.showAlert(alert)
    }
}


extension UIViewController:MFMessageComposeViewControllerDelegate,UINavigationControllerDelegate{
    public func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true) {
            switch result{
            case MessageComposeResultCancelled:
                self.playCrossMark("CANCEL".localizedString())
                MobClick.event("CancelSendNotifySMS")
            case MessageComposeResultFailed:
                self.playCrossMark("FAIL".localizedString())
            case MessageComposeResultSent:
                self.playCheckMark("SUCCESS".localizedString())
                MobClick.event("UserSendSMSToFriend")
            default:break;
            }
        }
    }
    
    func showSendSMSTextView(phones:[String],body:String){
        if MFMessageComposeViewController.canSendText(){
            let controller = MFMessageComposeViewController()
            controller.recipients = phones
            controller.body = body
            controller.delegate = self
            controller.messageComposeDelegate = self
            self.presentViewController(controller, animated: true, completion: { () -> Void in
                MobClick.event("OpenSendNotifySMS")
            })
        }else{
            self.showAlert("REQUIRE_SMS_FUNCTION_TITLE".localizedString(), msg: "REQUIRE_SMS_FUNCTION_MSG".localizedString())
        }
    }
}