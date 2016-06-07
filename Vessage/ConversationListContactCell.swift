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
            selectPersonMobile(self.rootController,person: person, onSelectedMobile: { (mobile,title) in
                self.rootController.openConversationWithMobile(mobile, noteName: title)
            })
        }
    }
}
