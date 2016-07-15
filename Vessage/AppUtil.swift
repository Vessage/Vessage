//
//  AppUtil.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI

func selectPersonMobile(vc:UIViewController,person:ABRecord,onSelectedMobile:(mobile:String,personTitle:String)->Void) {
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
                            MobClick.event("Vege_SelectContactMobile")
                            onSelectedMobile(mobile: phoneNos[i],personTitle: title)
                            
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
                    MobClick.event("Vege_CancelSelectContactMobile")
                })
                alertController.addAction(cancel)
                vc.showAlert(alertController)
                return
            }
        }
    }
    vc.playToast("PEOPLE_NO_MOBILE".localizedString())
}
extension String
{
    func localizedString() -> String{
        return NSLocalizedString(self, tableName: "Localizable", bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}

//MARK: Set avatar Util

func getDefaultAvatar(accountId:String = UserSetting.lastLoginAccountId) -> UIImage {
    if let id = Int(accountId){
        let index = id % 7
        return UIImage(named: "default_avatar_\(index)") ?? UIImage(named: "defaultAvatar")!
    }
    return UIImage(named: "defaultAvatar")!
}

extension FileService
{
    func setAvatar(imageView:UIImageView,iconFileId fileId:String!, defaultImage:UIImage = getDefaultAvatar(),callback:((suc:Bool)->Void)! = nil)
    {
        imageView.image = defaultImage
        if String.isNullOrWhiteSpace(fileId) == false
        {
            if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: NSBundle.mainBundle())
            {
                imageView.image = uiimage
                if let handler = callback{
                    handler(suc:true)
                }
            }else
            {
                self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                    if filePath != nil
                    {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            imageView.image = PersistentManager.sharedInstance.getImage(fileId,bundle: NSBundle.mainBundle())
                            if let handler = callback{
                                handler(suc:true)
                            }
                        })
                    }else{
                        if let handler = callback{
                            handler(suc:false)
                        }
                    }
                })
            }
        }else{
            if let handler = callback{
                handler(suc:false)
            }
        }
    }
    
    func setAvatar(button:UIButton,iconFileId fileId:String!)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let image = UIImage(named: "defaultAvatar")
            button.setImage(image, forState: .Normal)
            if String.isNullOrWhiteSpace(fileId) == false
            {
                if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: NSBundle.mainBundle())
                {
                    button.setImage(uiimage, forState: .Normal)
                }else
                {
                    self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                        if filePath != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                let img = PersistentManager.sharedInstance.getImage(fileId,bundle: NSBundle.mainBundle())
                                button.setImage(img, forState: .Normal)
                            })
                        }
                    })
                }
            }
        }
    }
}

extension String{
    func isBahamutAccount() -> Bool{
        
        if self =~ "^\\d{6,9}$"{
            if let aId = Int(self){
                return aId >= 147258
            }
        }
        return false
    }
}