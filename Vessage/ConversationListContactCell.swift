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
//MARK: ConversationListContactCell
class ConversationListContactCell:ConversationListCellBase,ABPeoplePickerNavigationControllerDelegate{
    static let reuseId = "ConversationListContactCell"
    
    override func onCellClicked() {
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        self.rootController.presentViewController(controller, animated: true) { () -> Void in
            MobClick.event("OpenContactView")
        }
    }
    
    //MARK: ABPeoplePickerNavigationControllerDelegate
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
        peoplePicker.dismissViewControllerAnimated(true) { () -> Void in
            let fname = ABRecordCopyValue(person, kABPersonFirstNameProperty)?.takeRetainedValue() ?? ""
            let lname = ABRecordCopyValue(person, kABPersonLastNameProperty)?.takeRetainedValue() ?? ""
            let title = "\(lname!)\(fname!)"
            if let phones = ABRecordCopyValue(person, kABPersonPhoneProperty)?.takeRetainedValue(){
                if ABMultiValueGetCount(phones) > 0{
                    var actions = [UIAlertAction]()
                    var phoneNos = [String]()
                    for i in 0 ..< ABMultiValueGetCount(phones){
                        
                        let phoneLabel = ABMultiValueCopyLabelAtIndex(phones, i).takeRetainedValue()
                            as CFStringRef;
                        let localizedPhoneLabel = ABAddressBookCopyLocalizedLabel(phoneLabel)
                            .takeRetainedValue() as String
                        
                        let value = ABMultiValueCopyValueAtIndex(phones, i)
                        var phone = value.takeRetainedValue() as! String
                        phone = phone.stringByReplacingOccurrencesOfString("+86", withString: "").stringByReplacingOccurrencesOfString("-", withString: "")
                        if phone.isMobileNumber(){
                            phoneNos.append(phone)
                            let action = UIAlertAction(title: "\(localizedPhoneLabel):\(phone)", style: .Default, handler: { (action) -> Void in
                                if let i = actions.indexOf(action){
                                    MobClick.event("SelectContactMobile")
                                    let conversation = self.rootController.conversationService.openConversationByMobile(phoneNos[i],noteName: title)
                                    ConversationViewController.showConversationViewController(self.rootController.navigationController!, conversation: conversation)
                                }
                            })
                            actions.append(action)
                        }
                    }
                    if actions.count > 0{
                        
                        let msg = "CHOOSE_PHONE_NO".localizedString()
                        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
                        actions.forEach{alertController.addAction($0)}
                        let cancel = UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: { (ac) -> Void in
                            MobClick.event("CancelSelectContactMobile")
                        })
                        alertController.addAction(cancel)
                        self.rootController.showAlert(alertController)
                        return
                    }
                }
            }
            self.rootController.playToast("PEOPLE_NO_MOBILE".localizedString())
        }
    }
}
