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
class ConversationListContactCellDelegate:NSObject,ConversationClickCellDelegate,ABPeoplePickerNavigationControllerDelegate{
    
    fileprivate var rootController:ConversationListController!
    
    func conversationTitleCell(_ sender: ConversationListCellBase, controller: ConversationListController!) {
        self.rootController = controller
        showContact()
    }
    
    fileprivate func tryShowTips()->Bool{
        if UserSetting.isSettingEnable(SHOW_OPEN_MOBILE_CONVERSATION_KEY) {
            return false
        }else{
            let ok = UIAlertAction(title: "OK".localizedString(), style: .default, handler: { (ac) in
                self.showContact()
            })
            self.rootController.showAlert("OPEN_MOBILE_CON_FST_TIPS_TITLE".localizedString(), msg: "OPEN_MOBILE_CON_FST_TIPS_MSG".localizedString(), actions: [ok])
            UserSetting.enableSetting(SHOW_OPEN_MOBILE_CONVERSATION_KEY)
            return true
        }
    }
    
    fileprivate func showContact(){
        let authStatus = ABAddressBookGetAuthorizationStatus();
        if authStatus == .notDetermined {
            let action = UIAlertAction(title: "OK".localizedString(), style: .default, handler: { (ac) in
                if let addressBookRef = ABAddressBookCreateWithOptions(nil , nil){
                    let addressBook = addressBookRef.takeRetainedValue()
                    ABAddressBookRequestAccessWithCompletion(addressBook, { (granted, error) in
                        DispatchQueue.main.async(execute: {
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
        }else if authStatus == .authorized{
            self.showContactView()
        }else{
            self.showNoPersimissionAlert()
        }
    }
    
    fileprivate func showNoPersimissionAlert(){
        self.rootController.showAlert("NO_CONTACT_PERSIMISSION_TITLE".localizedString(), msg: "NO_CONTACT_PERSIMISSION".localizedString())
    }
    
    fileprivate func showContactView(){
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        let hud = self.rootController.showAnimationHud()
        self.rootController.present(controller, animated: true) { () -> Void in
            MobClick.event("Vege_OpenContactView")
            hud.hideAsync(true)
        }
    }
    
    //MARK: ABPeoplePickerNavigationControllerDelegate
    func peoplePickerNavigationController(_ peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
        peoplePicker.dismiss(animated: true) { () -> Void in
            selectPersonMobile(self.rootController,person: person, onSelectedMobile: { (mobile,title) in
                self.rootController.openConversationWithMobile(mobile, noteName: title)
            })
        }
    }
    
    func peoplePickerNavigationControllerDidCancel(_ peoplePicker: ABPeoplePickerNavigationController) {
        peoplePicker.dismiss(animated: true, completion: nil)
    }
}
