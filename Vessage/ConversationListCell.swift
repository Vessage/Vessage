//
//  ConversationListCell.swift
//  Vessage
//
//  Created by AlexChow on 16/3/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI

//MARK: ConversationListCellBase
class ConversationListCellBase:UITableViewCell{
    var rootController:ConversationListController!
    
    func onCellClicked(){
        
    }
}

//MARK: ConversationListCell
typealias ConversationListCellHandler = (cell:ConversationListCell)->Void
class ConversationListCell:ConversationListCellBase{
    static let reuseId = "ConversationListCell"
    var originModel:AnyObject?
    var avatar:String!{
        didSet{
            if let imgView = self.avatarView{
                ServiceContainer.getService(FileService).setAvatar(imgView, iconFileId: avatar)
            }
        }
    }
    var headLine:String!{
        didSet{
            self.headLineLabel?.text = headLine
        }
    }
    var subLine:String!{
        didSet{
            self.subLineLabel?.text = subLine
        }
    }
    
    var badge:Int = 0{
        didSet{
            if badge == 0{
                badgeButton.badgeValue = ""
            }else{
                badgeButton.badgeValue = "\(badge)"
            }
        }
    }
    
    var conversationListCellHandler:ConversationListCellHandler!
    override func onCellClicked() {
        if let handler = conversationListCellHandler{
            handler(cell: self)
        }
    }
    @IBOutlet weak var badgeButton: UIButton!{
        didSet{
            badgeButton.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var headLineLabel: UILabel!
    @IBOutlet weak var subLineLabel: UILabel!
}

//MARK: ConversationListContactCell
class ConversationListContactCell:ConversationListCellBase,ABPeoplePickerNavigationControllerDelegate{
    static let reuseId = "ConversationListContactCell"
    
    override func onCellClicked() {
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        self.rootController.presentViewController(controller, animated: true) { () -> Void in
            
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
                        if phone.isChinaMobileNo(){
                            phoneNos.append(phone)
                            let action = UIAlertAction(title: "\(localizedPhoneLabel):\(phone)", style: .Default, handler: { (action) -> Void in
                                if let i = actions.indexOf(action){
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
                        alertController.addAction(UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: nil))
                        self.rootController.showAlert(alertController)
                        return
                    }
                }
            }
            self.rootController.playToast("PEOPLE_NO_MOBILE".localizedString())
        }
    }
}
