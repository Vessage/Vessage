//
//  UserProfileController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: Show Chatter Profile
extension UserService{
    func showUserProfile(vc:UIViewController,user:VessageUser) {
        let noteName = self.getUserNotedName(user.userId)
        if String.isNullOrWhiteSpace(user.accountId) {
            vc.showAlert(noteName, msg: "MOBILE_USER".localizedString())
        }else{
            let noteNameAction = UIAlertAction(title: "NOTE".localizedString(), style: .Default, handler: { (ac) in
                self.showNoteConversationAlert(vc,user: user)
            })
            vc.showAlert(user.nickName ?? noteName, msg:String(format: "USER_ACCOUNT_FORMAT".localizedString(),user.accountId),actions: [noteNameAction,ALERT_ACTION_CANCEL])
        }
    }
    
    private func showNoteConversationAlert(vc:UIViewController,user:VessageUser){
        let title = "NOTE_CONVERSATION_A_NAME".localizedString()
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
            textfield.placeholder = "CONVERSATION_NAME".localizedString()
            textfield.borderStyle = .None
            textfield.text = ServiceContainer.getUserService().getUserNotedName(user.userId)
        })
        
        let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
            let newNoteName = alertController.textFields?[0].text ?? ""
            if String.isNullOrEmpty(newNoteName)
            {
                vc.playToast("NEW_NOTE_NAME_CANT_NULL".localizedString())
            }else{
                if String.isNullOrWhiteSpace(user.userId) == false{
                    ServiceContainer.getUserService().setUserNoteName(user.userId, noteName: newNoteName)
                }
                vc.playCheckMark("SAVE_NOTE_NAME_SUC".localizedString())
            }
        })
        let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
        alertController.addAction(no)
        alertController.addAction(yes)
        vc.showAlert(alertController)
    }
}
