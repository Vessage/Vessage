//
//  ShareHelper.swift
//  Vessage
//
//  Created by AlexChow on 16/5/30.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let kShareHelperShareType = "kShareHelperShareType"

enum ShareHelperShareType:Int {
    case SMS = 0
    case WX_SESSION = 1
    case WX_TIME_LINE = 2
}

class ShareHelper:NSNotificationCenter{
    static let onShareSuccess = "onShareSuccess"
    static let onShareFail = "onShareFail"
    static let onShareCancel = "onShareCancel"
    
    static private(set) var instance:ShareHelper = {
        let helper = ShareHelper()
        NSNotificationCenter.defaultCenter().addObserver(helper, selector: #selector(ShareHelper.onWXShareResponse(_:)), name: OnWXShareResponse, object: nil)
        return helper
    }()
    
    func onWXShareResponse(a:NSNotification) {
        if let resp = a.userInfo?[kWXShareResponseValue] as? SendMessageToWXResp {
            let type = ShareHelperShareType.WX_SESSION.rawValue
            let userInfo = [kShareHelperShareType:type]
            if resp.errCode == WXSuccess.rawValue{
                self.postNotificationName(ShareHelper.onShareSuccess, object: self, userInfo: userInfo)
            }else if resp.errCode == WXErrCodeUserCancel.rawValue{
                self.postNotificationName(ShareHelper.onShareFail, object: self, userInfo: userInfo)
            }else{
                self.postNotificationName(ShareHelper.onShareFail, object: self, userInfo: userInfo)
            }
        }
    }
    
    private func sendTellFriendWX(type:UInt32,textMsg:String?){
        let url = "http://a.app.qq.com/o/simple.jsp?pkgname=cn.bahamut.vessage"
        let msg = WXMediaMessage()
        msg.title = WXSceneSession.rawValue == type ? String(format: "WX_SHARE_TITLE_FORMAT".localizedString(), UserSetting.lastLoginAccountId) : "SHARE_FUN_APP".localizedString()
        msg.description = textMsg
        msg.setThumbImage(UIImage(named: "shareIcon"))
        
        let wxobj = WXWebpageObject()
        wxobj.webpageUrl = url
        
        msg.mediaObject = wxobj
        
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = msg
        req.scene = Int32(type)
        MobClick.event("Vege_ShareWX")
        WXApi.sendReq(req)
    }
    
    func showTellVegeToFriendsAlert(vc:UIViewController,message:String,alertMsg:String! = nil,title:String = "TELL_FRIENDS".localizedString()){
        
        let alert = UIAlertController(title: title, message: alertMsg, preferredStyle: .ActionSheet)

        let wxAction = UIAlertAction(title: "WECHAT_SESSION".localizedString(), style: .Default) { (ac) in
            self.sendTellFriendWX(WXSceneSession.rawValue,textMsg: message)
        }
        
        wxAction.setValue(UIImage(named: "share_wechat")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        alert.addAction(wxAction)
        
        let wxTimeLineAction = UIAlertAction(title: "WECHAT_TIMELINE".localizedString(), style: .Default) { (ac) in
            self.sendTellFriendWX(WXSceneTimeline.rawValue,textMsg: message)
        }
        wxTimeLineAction.setValue(UIImage(named: "share_wechat_moment")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        alert.addAction(wxTimeLineAction)
        
        let smsAction = UIAlertAction(title: "SMS".localizedString(), style: .Default) { (ac) in
            let url = "http://t.cn/RqW8tuW"
            let accountInfo = String(format: "WX_SHARE_TITLE_FORMAT".localizedString(), UserSetting.lastLoginAccountId)
            vc.showSendSMSTextView([], body: "\(message)\n\(url)\n\(accountInfo)")
        }
        smsAction.setValue(UIImage(named: "share_sms")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        alert.addAction(smsAction)
        alert.addAction(ALERT_ACTION_CANCEL)
        
        
        vc.showAlert(alert)
    }
    
    func showTellTextMsgToFriendsAlert(vc:UIViewController,content:String,smsReceiver:String? = nil){
        let alert = UIAlertController(title: "TELL_FRIENDS".localizedString(), message: nil, preferredStyle: .ActionSheet)
        let wxAction = UIAlertAction(title: "WECHAT_SESSION".localizedString(), style: .Default) { (ac) in
            self.sendTellFriendWX(WXSceneSession.rawValue, textMsg: content)
        }
        wxAction.setValue(UIImage(named: "share_wechat")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        alert.addAction(wxAction)
        
        let smsAction = UIAlertAction(title: "SMS".localizedString(), style: .Default) { (ac) in
            let url = "http://t.cn/RqW8tuW"
            let body = "\(content)\n\(url)"
            if let receiver = smsReceiver{
                vc.showSendSMSTextView([receiver], body: body)
            }else{
                vc.showSendSMSTextView([], body: body)
            }
            
        }
        smsAction.setValue(UIImage(named: "share_sms")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        alert.addAction(smsAction)
        alert.addAction(ALERT_ACTION_CANCEL)
        vc.showAlert(alert)
    }
}


extension UIViewController:MFMessageComposeViewControllerDelegate,UINavigationControllerDelegate{
    public func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true) {
            switch result{
            case MessageComposeResult.Cancelled:
                self.playCrossMark("CANCEL".localizedString())
                ShareHelper.instance.postNotificationName(ShareHelper.onShareCancel, object: ShareHelper.instance, userInfo: [kShareHelperShareType:ShareHelperShareType.SMS.rawValue])
                MobClick.event("Vege_CancelSendNotifySMS")
            case MessageComposeResult.Failed:
                self.playCrossMark("FAIL".localizedString())
                ShareHelper.instance.postNotificationName(ShareHelper.onShareFail, object: ShareHelper.instance, userInfo: [kShareHelperShareType:ShareHelperShareType.SMS.rawValue])
            case MessageComposeResult.Sent:
                self.playCheckMark("SUCCESS".localizedString())
                ShareHelper.instance.postNotificationName(ShareHelper.onShareSuccess, object: ShareHelper.instance, userInfo: [kShareHelperShareType:ShareHelperShareType.SMS.rawValue])
                MobClick.event("Vege_UserSendSMSToFriend")
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
                MobClick.event("Vege_OpenSendNotifySMS")
            })
        }else{
            self.showAlert("REQUIRE_SMS_FUNCTION_TITLE".localizedString(), msg: "REQUIRE_SMS_FUNCTION_MSG".localizedString())
        }
    }
}
