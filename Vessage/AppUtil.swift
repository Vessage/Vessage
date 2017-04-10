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
import MBProgressHUD
import EVReflection
import SDWebImage

func selectPersonMobile(_ vc:UIViewController,person:ABRecord,onSelectedMobile:@escaping (_ mobile:String,_ personTitle:String)->Void) {
    let fname = ABRecordCopyValue(person, kABPersonFirstNameProperty)?.takeRetainedValue() as? String ?? ""
    let lname = ABRecordCopyValue(person, kABPersonLastNameProperty)?.takeRetainedValue() as? String ?? ""
    let title = "\(lname)\(fname)"
    if let phones = ABRecordCopyValue(person, kABPersonPhoneProperty)?.takeRetainedValue(){
        if ABMultiValueGetCount(phones) > 0{
            var actions = [UIAlertAction]()
            var phoneNos = [String]()
            for i in 0 ..< ABMultiValueGetCount(phones){
                
                let phoneLabel = ABMultiValueCopyLabelAtIndex(phones, i).takeRetainedValue()
                    as CFString;
                let localizedPhoneLabel = ABAddressBookCopyLocalizedLabel(phoneLabel)
                    .takeRetainedValue() as String
                
                let value = ABMultiValueCopyValueAtIndex(phones, i)
                var phone = value?.takeRetainedValue() as! String
                phone = phone.replacingOccurrences(of: "+86", with: "").replacingOccurrences(of: "-", with: "")
                if(phone.hasBegin("86")){
                    phone = phone.substring(from: phone.index(phone.startIndex, offsetBy: 2))
                }
                if phone.isMobileNumber(){
                    phoneNos.append(phone)
                    let action = UIAlertAction(title: "\(localizedPhoneLabel):\(phone)", style: .default, handler: { (action) -> Void in
                        if let i = actions.index(of: action){
                            MobClick.event("Vege_SelectContactMobile")
                            onSelectedMobile(phoneNos[i],title)
                            
                        }
                    })
                    actions.append(action)
                }
            }
            if actions.count > 0{
                if actions.count == 1 {
                    onSelectedMobile(phoneNos[0], title)
                }else{
                    let msg = "CHOOSE_PHONE_NO".localizedString()
                    let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
                    actions.forEach{alertController.addAction($0)}
                    let cancel = UIAlertAction(title: "CANCEL".localizedString(), style: .cancel, handler: { (ac) -> Void in
                        MobClick.event("Vege_CancelSelectContactMobile")
                    })
                    alertController.addAction(cancel)
                    vc.showAlert(alertController)
                }
                return
            }
        }
    }
    vc.playToast("PEOPLE_NO_MOBILE".localizedString())
}

extension String
{
    func localizedString() -> String{
        return NSLocalizedString(self, tableName: "Localizable", bundle: Bundle.main, value: "", comment: "")
    }
}

//MARK: Set avatar Util

func getDefaultFace() -> UIImage {
    return UIImage(named: "default_face")!
}

func getDefaultAvatar(_ accountId:String = UserSetting.lastLoginAccountId,sex:Int = 0) -> UIImage {
    
    if let id = Int(accountId){
        var index = 0
        if(sex > 0){
            index = 2 + id % 2
        }else if(sex < 0){
            index = 4 + id % 3
        }else{
            index = id % 7
        }
        return UIImage(named: "default_avatar_\(index)") ?? UIImage(named: "defaultAvatar")!
    }
    return UIImage(named: "defaultAvatar")!
}

extension FileService
{
    func getImage(iconFileId fileId:String!,callback:@escaping ((_ image:UIImage?)->Void))
    {
        if String.isNullOrWhiteSpace(fileId) == false
        {
            if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: Bundle.main)
            {
                callback(uiimage)
            }else
            {
                self.fetchFile(fileId, fileType: FileType.image, callback: { (filePath) -> Void in
                    if filePath != nil
                    {
                        DispatchQueue.main.async(execute: { () -> Void in
                            let image = PersistentManager.sharedInstance.getImage(fileId,bundle: Bundle.main)
                            callback(image)
                        })
                    }else{
                        callback(nil)
                    }
                })
            }
        }else{
            callback(nil)
        }
    }
    
    func setImage(_ imageView:UIImageView,iconFileId fileId:String!, defaultImage:UIImage? = getDefaultAvatar(),callback:((_ suc:Bool)->Void)! = nil)
    {
        imageView.image = defaultImage
        if let imgl = fileId?.lowercased(), imgl.hasPrefix("http://") || imgl.hasPrefix("https://") {
            imageView.sd_setImage(with: URL(string: fileId), completed: { (image, error, cacheType, url) in
                callback?(error == nil)
            })
        }else{
            getImage(iconFileId: fileId) { (img) in
                if let image = img{
                    imageView.image = image
                    callback?(true)
                }else{
                    callback?(false)
                }
            }
        }
    }
    
    func setImage(_ button:UIButton,iconFileId fileId:String!)
    {
        let image = UIImage(named: "defaultAvatar")
        button.setImage(image, for: UIControlState())
        getImage(iconFileId: fileId) { (img) in
            if let image = img{
                button.setImage(image, for: UIControlState())
            }
        }
    }
}

extension String{
    func isBahamutAccount() -> Bool{
        if let aId = Int(self) {
            return (aId >= 10000 && aId <= 20000) || (self.isRegexMatch(pattern:"^\\d{6,9}$") && aId >= 147258)
        }
        return false
    }
}


func setBadgeLabelValue(_ badgeLabel:UILabel!,value:Int!,autoHide:Bool = true){
    badgeLabel?.text = intToBadgeString(value)
    if autoHide {
        badgeLabel?.isHidden = badgeLabel?.text == nil
    }else{
        badgeLabel?.text = badgeLabel?.text ?? "0"
    }
    badgeLabel?.animationMaxToMin()
}

let hudSpinImageArray:[UIImage] = {
    var spins = [UIImage]()
    for i in 1...20{
        //spins.append(UIImage(named:"spin_\(i)")!)
    }
    return spins
}()

extension UIBarButtonItem{
    func showMiniBadge(){
        badgeMinSize = 8
        badgeOriginX = 26
        badgeOriginY = 2
        badge.clipsToBounds = true
        badgeValue = " "
        badge.frame.size = CGSize(width: 8, height: 8)
        badge.layer.cornerRadius = 4
    }
    
    func hideMiniBadge() {
        badgeValue = nil
    }
}

extension UIViewController{
    
    func showAnimationHud(_ title:String! = "",message:String! = "",async:Bool = true,completionHandler: HudHiddenCompletedHandler! = nil) -> MBProgressHUD {
        /*
        let imv = UIImageView(frame: CGRectMake(0, 0, 64, 46))
        imv.animationImages = hudSpinImageArray
        imv.animationRepeatCount = 0
        imv.animationDuration = 0.6
        imv.startAnimating()
        let hud = self.showActivityHudWithMessage(title, message: message, async: async, completionHandler: completionHandler)
        hud.mode = .CustomView
        hud.customView = imv
        hud.bezelView.style = .SolidColor
        hud.bezelView.color = UIColor.clearColor()
        return hud
        */
        return self.showActivityHudWithMessage(title, message: message, async: async, completionHandler: completionHandler)
    }
}

func getRandomConversationBackground() -> UIImage {
    return UIImage(named: "vg_default_bcg_\(random() % 5)") ?? UIImage(named: "vg_default_bcg_0")!
}

extension EVObject{
    func toMiniJsonString() -> String {
        let json = toJsonString()
        return json.split("\n").map{$0.trim()}.joined(separator: " ")
    }
}

extension EVReflection{
    static func toMiniJsonString(_ theObject:NSObject)->String{
        return EVReflection.toJsonString(theObject).split("\n").map{$0.trim()}.joined(separator: " ")
    }
}

