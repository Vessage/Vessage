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
    
    @IBOutlet weak var titleLabel: UILabel!
    override func onCellClicked() {
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
        let hud = self.rootController.showActivityHud()
        self.rootController.presentViewController(controller, animated: true) { () -> Void in
            MobClick.event("OpenContactView")
            hud.hideAsync(true)
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
                        if(phone.hasBegin("86")){
                            phone = phone.substringFromIndex(2)
                        }
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
