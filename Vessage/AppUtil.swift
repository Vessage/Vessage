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
import ImageSlideshow

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

func getDefaultFace() -> UIImage {
    return UIImage(named: "default_face")!
}

func getDefaultAvatar(accountId:String = UserSetting.lastLoginAccountId) -> UIImage {
    if let id = Int(accountId){
        let index = id % 7
        return UIImage(named: "default_avatar_\(index)") ?? UIImage(named: "defaultAvatar")!
    }
    return UIImage(named: "defaultAvatar")!
}

extension FileService
{
    func getImage(iconFileId fileId:String!,callback:((image:UIImage?)->Void))
    {
        if String.isNullOrWhiteSpace(fileId) == false
        {
            if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: NSBundle.mainBundle())
            {
                callback(image: uiimage)
            }else
            {
                self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                    if filePath != nil
                    {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let image = PersistentManager.sharedInstance.getImage(fileId,bundle: NSBundle.mainBundle())
                            callback(image: image)
                        })
                    }else{
                        callback(image: nil)
                    }
                })
            }
        }else{
            callback(image: nil)
        }
    }
    
    func setImage(imageView:UIImageView,iconFileId fileId:String!, defaultImage:UIImage? = getDefaultAvatar(),callback:((suc:Bool)->Void)! = nil)
    {
        imageView.image = defaultImage
        getImage(iconFileId: fileId) { (img) in
            if let image = img{
                imageView.image = image
                callback?(suc: true)
            }else{
                callback?(suc: false)
            }
        }
    }
    
    func setImage(button:UIButton,iconFileId fileId:String!)
    {
        let image = UIImage(named: "defaultAvatar")
        button.setImage(image, forState: .Normal)
        getImage(iconFileId: fileId) { (img) in
            if let image = img{
                button.setImage(image, forState: .Normal)
            }
        }
    }
}

extension String{
    func isBahamutAccount() -> Bool{
        if let aId = Int(self) {
            return (aId >= 10000 && aId <= 20000) || (self =~ "^\\d{6,9}$" && aId >= 147258)
        }
        return false
    }
}


func setBadgeLabelValue(badgeLabel:UILabel!,value:Int!,autoHide:Bool = true){
    badgeLabel?.text = intToBadgeString(value)
    if autoHide {
        badgeLabel?.hidden = badgeLabel?.text == nil
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

extension UIViewController{
    
    func showAnimationHud(title:String! = "",message:String! = "",async:Bool = true,completionHandler: HudHiddenCompletedHandler! = nil) -> MBProgressHUD {
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
        return json.split("\n").map{$0.trim()}.joinWithSeparator(" ")
    }
}

extension EVReflection{
    static func toMiniJsonString(theObject:NSObject)->String{
        return EVReflection.toJsonString(theObject).split("\n").map{$0.trim()}.joinWithSeparator(" ")
    }
}

extension UITableViewCell{
    func setSeparatorFullWidth() {
        self.preservesSuperviewLayoutMargins = false
        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero
    }
}

extension UIImageView{
    func slideShowFullScreen(vc:UIViewController) {
        if let img = self.image {
            let slideshow = ImageSlideshow()
            slideshow.setImageInputs([ImageSource(image: img)])
            slideshow.pageControlPosition = .Hidden
            let ctr = FullScreenSlideshowViewController()
            // called when full-screen VC dismissed and used to set the page to our original slideshow
            ctr.pageSelected = { page in
                slideshow.setScrollViewPage(page, animated: false)
            }
            ctr.modalTransitionStyle = .CoverVertical
            // set the initial page
            ctr.initialImageIndex = slideshow.scrollViewPage
            // set the inputs
            ctr.inputs = slideshow.images
            ctr.slideshow.pageControlPosition = .Hidden
            ctr.modalTransitionStyle = .CrossDissolve
            let slideshowTransitioningDelegate = ZoomAnimatedTransitioningDelegate(slideshowView: slideshow, slideshowController: ctr)
            ctr.transitioningDelegate = slideshowTransitioningDelegate
            vc.presentViewController(ctr, animated: true){
                ctr.enableTapViewCloseController()
            }
        }
    }
}

extension FullScreenSlideshowViewController{
    func enableTapViewCloseController(hideCloseButton:Bool = true) {
        if hideCloseButton {
            self.closeButton.hidden = hideCloseButton
        }
        let ges = UITapGestureRecognizer(target: self, action: #selector(FullScreenSlideshowViewController.onTapView(_:)))
        ges.numberOfTapsRequired = 1
        self.slideshow.slideshowItems.forEach { (item) in
            if let iges = item.gestureRecognizer{
                ges.requireGestureRecognizerToFail(iges)
            }
        }
        self.view.addGestureRecognizer(ges)
    }
    
    func disableTapViewCloseController() {
        self.closeButton.hidden = false
        if let gess = self.view.gestureRecognizers{
            gess.forEach({ (ges) in
                if let g = ges as? UITapGestureRecognizer{
                    g.removeTarget(self, action: #selector(FullScreenSlideshowViewController.onTapView(_:)))
                }
            })
        }
    }
    
    func onTapView(tap:UITapGestureRecognizer) {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(page: slideshow.scrollViewPage)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
