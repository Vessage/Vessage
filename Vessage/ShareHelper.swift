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
    case sms = 0
    case wx_SESSION = 1
    case wx_TIME_LINE = 2
}

class ShareHelper:NotificationCenter{
    static let onShareSuccess = "onShareSuccess"
    static let onShareFail = "onShareFail"
    static let onShareCancel = "onShareCancel"
    
    static fileprivate(set) var instance:ShareHelper = {
        let helper = ShareHelper()
        NotificationCenter.default.addObserver(helper, selector: #selector(ShareHelper.onWXShareResponse(_:)), name: NSNotification.Name(rawValue: OnWXShareResponse), object: nil)
        return helper
    }()
    
    func onWXShareResponse(_ a:Notification) {
        if let resp = a.userInfo?[kWXShareResponseValue] as? SendMessageToWXResp {
            let type = ShareHelperShareType.wx_SESSION.rawValue
            let userInfo = [kShareHelperShareType:type]
            if resp.errCode == WXSuccess.rawValue{
                self.post(name: Notification.Name(rawValue: ShareHelper.onShareSuccess), object: self, userInfo: userInfo)
                MobClick.event("ShareApp_ShareWXSuc")
            }else if resp.errCode == WXErrCodeUserCancel.rawValue{
                self.post(name: Notification.Name(rawValue: ShareHelper.onShareFail), object: self, userInfo: userInfo)
                MobClick.event("ShareApp_ShareWXCancel")
            }else{
                self.post(name: Notification.Name(rawValue: ShareHelper.onShareFail), object: self, userInfo: userInfo)
                MobClick.event("ShareApp_ShareWXErr")
            }
        }
    }
    
    fileprivate func sendTellFriendWX(_ type:UInt32,textMsg:String?){
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
        MobClick.event("ShareApp_ShareWX")
        WXApi.send(req)
    }
    
    func showTellVegeToFriendsAlert(_ vc:UIViewController,message:String,alertMsg:String! = nil,title:String = "TELL_FRIENDS".localizedString(),copyLink:Bool = false){
        
        let alert = UIAlertController.create(title: title, message: alertMsg, preferredStyle: .actionSheet)

        let wxAction = UIAlertAction(title: "WECHAT_SESSION".localizedString(), style: .default) { (ac) in
            self.sendTellFriendWX(WXSceneSession.rawValue,textMsg: message)
        }
        
        wxAction.setValue(UIImage(named: "share_wechat")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alert.addAction(wxAction)
        
        let wxTimeLineAction = UIAlertAction(title: "WECHAT_TIMELINE".localizedString(), style: .default) { (ac) in
            self.sendTellFriendWX(WXSceneTimeline.rawValue,textMsg: message)
        }
        wxTimeLineAction.setValue(UIImage(named: "share_wechat_moment")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alert.addAction(wxTimeLineAction)
        
        let url = "http://t.cn/RqW8tuW"
        let accountInfo = String(format: "WX_SHARE_TITLE_FORMAT".localizedString(), UserSetting.lastLoginAccountId)
        let inviteMsg = "\(message)\n\(url)\n\(accountInfo)"
        
        let smsAction = UIAlertAction(title: "SMS".localizedString(), style: .default) { (ac) in
            vc.showSendSMSTextView([], body: inviteMsg)
        }
        
        smsAction.setValue(UIImage(named: "share_sms")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alert.addAction(smsAction)
        
        if copyLink {
            let copyLinkAction = UIAlertAction(title: "COPY_INVITE_LINK".localizedString(), style: .default, handler: { (ac) in
                UIPasteboard.general.string = inviteMsg
                vc.playToast("COPY_INVITE_LINK_SUC".localizedString())
            })
            copyLinkAction.setValue(UIImage(named: "share_link_icon")?.withRenderingMode(.alwaysOriginal), forKey: "image")
            alert.addAction(copyLinkAction)
        }
        
        alert.addAction(ALERT_ACTION_CANCEL)
        MobClick.event("ShareApp_ShowShareAlert")
        vc.showAlert(alert)
    }
    
    func showTellTextMsgToFriendsAlert(_ vc:UIViewController,content:String,smsReceiver:String? = nil){
        let alert = UIAlertController.create(title: "TELL_FRIENDS".localizedString(), message: nil, preferredStyle: .actionSheet)
        let wxAction = UIAlertAction(title: "WECHAT_SESSION".localizedString(), style: .default) { (ac) in
            self.sendTellFriendWX(WXSceneSession.rawValue, textMsg: content)
        }
        wxAction.setValue(UIImage(named: "share_wechat")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alert.addAction(wxAction)
        
        let smsAction = UIAlertAction(title: "SMS".localizedString(), style: .default) { (ac) in
            let url = "http://t.cn/RqW8tuW"
            let body = "\(content)\n\(url)"
            if let receiver = smsReceiver{
                vc.showSendSMSTextView([receiver], body: body)
            }else{
                vc.showSendSMSTextView([], body: body)
            }
            
        }
        smsAction.setValue(UIImage(named: "share_sms")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alert.addAction(smsAction)
        alert.addAction(ALERT_ACTION_CANCEL)
        MobClick.event("ShareApp_ShowShareAlert")
        vc.showAlert(alert)
    }
}


extension UIViewController:MFMessageComposeViewControllerDelegate,UINavigationControllerDelegate{
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) {
            switch result{
            case MessageComposeResult.cancelled:
                self.playCrossMark("CANCEL".localizedString())
                ShareHelper.instance.post(name: Notification.Name(rawValue: ShareHelper.onShareCancel), object: ShareHelper.instance, userInfo: [kShareHelperShareType:ShareHelperShareType.sms.rawValue])
                MobClick.event("ShareApp_CancelSendNotifySMS")
            case MessageComposeResult.failed:
                self.playCrossMark("FAIL".localizedString())
                ShareHelper.instance.post(name: Notification.Name(rawValue: ShareHelper.onShareFail), object: ShareHelper.instance, userInfo: [kShareHelperShareType:ShareHelperShareType.sms.rawValue])
            case MessageComposeResult.sent:
                self.playCheckMark("SUCCESS".localizedString())
                ShareHelper.instance.post(name: Notification.Name(rawValue: ShareHelper.onShareSuccess), object: ShareHelper.instance, userInfo: [kShareHelperShareType:ShareHelperShareType.sms.rawValue])
                MobClick.event("ShareApp_UserSendSMSToFriend")
            }
        }
    }
    
    func showSendSMSTextView(_ phones:[String],body:String){
        if MFMessageComposeViewController.canSendText(){
            let controller = MFMessageComposeViewController()
            controller.recipients = phones
            controller.body = body
            controller.delegate = self
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: { () -> Void in
                MobClick.event("ShareApp_OpenSendNotifySMS")
            })
        }else{
            self.showAlert("REQUIRE_SMS_FUNCTION_TITLE".localizedString(), msg: "REQUIRE_SMS_FUNCTION_MSG".localizedString())
        }
    }
}
