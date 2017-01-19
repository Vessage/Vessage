//
//  ConversationListContactCell.swift
//  Vessage
//
//  Created by AlexChow on 16/3/16.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI
let SHOW_OPEN_MOBILE_CONVERSATION_KEY = "SHOW_OPEN_MOBILE_CONVERSATION_KEY"

//MARK: ConversationListContactCell
class ConversationListContactCellDelegate:NSObject,ConversationTitleCellDelegate,ABPeoplePickerNavigationControllerDelegate{
    
    private var rootController:ConversationListController!
    
    func conversationTitleCell(sender: ConversationTitleCell, controller: ConversationListController!) {
        self.rootController = controller
        if !tryShowTips() {
            showContact()
        }
    }
    
    private func tryShowTips()->Bool{
        if UserSetting.isSettingEnable(SHOW_OPEN_MOBILE_CONVERSATION_KEY) {
            return false
        }else{
            let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                self.showContact()
            })
            self.rootController.showAlert("OPEN_MOBILE_CON_FST_TIPS_TITLE".localizedString(), msg: "OPEN_MOBILE_CON_FST_TIPS_MSG".localizedString(), actions: [ok])
            UserSetting.enableSetting(SHOW_OPEN_MOBILE_CONVERSATION_KEY)
            return true
        }
    }
    
    private func showContact(){
        let authStatus = ABAddressBookGetAuthorizationStatus();
        if authStatus == .NotDetermined {
            
            let action = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                if let addressBookRef = ABAddressBookCreateWithOptions(nil , nil){
                    let addressBook = addressBookRef.takeRetainedValue()
                    ABAddressBookRequestAccessWithCompletion(addressBook, { (granted, error) in
                        dispatch_async(dispatch_get_main_queue(), {
                            if error != nil{
                                self.showNoPersimissionAlert()
                            }else if granted {
                                self.showContactView()
                            }else{
                                self.showNoPersimissionAlert()
                            }
                        })
                    })
                    
                }else{
                    self.showNoPersimissionAlert()
                }
            })
            self.rootController.showAlert("REQUEST_ACCESS_CONTACT_TITLE".localizedString(), msg: "REQUEST_ACCESS_CONTACT".localizedString(), actions: [action])
        }else if authStatus == .Authorized{
            showContactView()
        }else{
            self.showNoPersimissionAlert()
        }
    }
    
    private func showNoPersimissionAlert(){
        self.rootController.showAlert("NO_CONTACT_PERSIMISSION_TITLE".localizedString(), msg: "NO_CONTACT_PERSIMISSION".localizedString())
    }
    
    private func showContactView(){
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        let hud = self.rootController.showAnimationHud()
        self.rootController.presentViewController(controller, animated: true) { () -> Void in
            MobClick.event("Vege_OpenContactView")
            hud.hideAsync(true)
        }
    }
    
    //MARK: ABPeoplePickerNavigationControllerDelegate
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
        peoplePicker.dismissViewControllerAnimated(true) { () -> Void in
            selectPersonMobile(self.rootController,person: person, onSelectedMobile: { (mobile,title) in
                self.rootController.openConversationWithMobile(mobile, noteName: title)
            })
        }
    }
}
