//
//  MatchContactUserViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AddressBook

class MatchContactUserCell: UITableViewCell {
    static let reuseId = "MatchContactUserCell"
    var user:ContactUser!
    
    @IBOutlet weak var checkedImage: UIImageView!{
        didSet{
            checkedImage?.hidden = true
        }
    }
    
    @IBOutlet weak var VGInfoLabel: UILabel!
    @IBOutlet weak var nick: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var inviteButton: UIButton!{
        didSet{
            inviteButton?.hidden = true
        }
    }
    
    @IBAction func onClickInviteButton(sender: AnyObject) {
        
    }
    
    func updateCell(fileService:FileService) {
        nick.text = user?.name
        if user?.matchedPhoneUsers.count > 0 {
            if let (_,info) = user?.matchedPhoneUsers.first{
                if let aId = info.account {
                    avatar.image = getDefaultAvatar(aId)
                }else{
                    avatar.image = UIImage(named: "vg_smile")
                }
                fileService.setImage(avatar, iconFileId: info.avatar)
                VGInfoLabel.text = "VG:\(info.nick)"
            }
        }else{
            avatar.image = UIImage(named: "defaultAvatar")
            VGInfoLabel.text = "点击检查Ta是否加入VG"
        }
    }
}

class ContactUser {
    var name:String!
    var phone = [String]()
    var abRecord:ABRecord?
    var account:String!
    var checked = false
    var matchedPhoneUsers = [String:MobileMatchedUser]()
    
}

class MatchContactUserViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.allowsMultipleSelection = false
            tableView.allowsSelection = true
        }
    }
    @IBOutlet weak var searchBar: UISearchBar!
    private let userService = ServiceContainer.getUserService()
    private let fileService = ServiceContainer.getFileService()
    private var addressBook:ABAddressBookRef?
    private var contactUsers = [ContactUser]()
    
}

extension MatchContactUserViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
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
                                self.readRecords()
                                self.tableView?.reloadData()
                            }else{
                                self.showNoPersimissionAlert()
                            }
                        })
                    })
                    
                }else{
                    self.showNoPersimissionAlert()
                }
            })
            self.showAlert("REQUEST_ACCESS_CONTACT_TITLE".localizedString(), msg: "REQUEST_ACCESS_CONTACT".localizedString(), actions: [action])
        }else if authStatus == .Authorized{
            self.readRecords()
        }else{
            self.showNoPersimissionAlert()
        }
    }
    
    private func showNoPersimissionAlert(){
        self.showAlert("NO_CONTACT_PERSIMISSION_TITLE".localizedString(), msg: "NO_CONTACT_PERSIMISSION".localizedString())
    }
    
    //获取并遍历所有联系人记录
    private func readRecords(){
        let sysContacts:NSArray = ABAddressBookCopyArrayOfAllPeople(addressBook)
            .takeRetainedValue() as NSArray
        contactUsers.removeAll()
        for contact in sysContacts {
            let contactUser = ContactUser()
            contactUser.abRecord = contact
            //获取姓
            let lastName = ABRecordCopyValue(contact, kABPersonLastNameProperty)?
                .takeRetainedValue() as! String? ?? ""
            debugPrint("姓：\(lastName)")
            
            //获取名
            let firstName = ABRecordCopyValue(contact, kABPersonFirstNameProperty)?
                .takeRetainedValue() as! String? ?? ""
            debugPrint("名：\(firstName)")
            
            contactUser.name = "\(lastName)\(firstName)"
            
            //获取电话
            let phoneValues:ABMutableMultiValueRef? =
                ABRecordCopyValue(contact, kABPersonPhoneProperty).takeRetainedValue()
            if phoneValues != nil {
                debugPrint("电话：")
                for i in 0 ..< ABMultiValueGetCount(phoneValues){
                    // 获得标签名
                    let phoneLabel = ABMultiValueCopyLabelAtIndex(phoneValues, i).takeRetainedValue()
                        as CFStringRef;
                    // 转为本地标签名（能看得懂的标签名，比如work、home）
                    let localizedPhoneLabel = ABAddressBookCopyLocalizedLabel(phoneLabel)
                        .takeRetainedValue() as String?
                    
                    let value = ABMultiValueCopyValueAtIndex(phoneValues, i)
                    if let phone = value.takeRetainedValue() as? String{
                        
                        var mobile = phone.stringByReplacingOccurrencesOfString("+86", withString: "").stringByReplacingOccurrencesOfString("-", withString: "")
                        if(mobile.hasBegin("86")){
                            mobile = mobile.substringFromIndex(2)
                        }
                        if mobile.isMobileNumber(){
                            contactUser.phone.append(phone)
                            debugPrint("  \(localizedPhoneLabel):\(phone)")
                        }
                    }
                }
            }
            
            if contactUser.phone.count > 0 {
                contactUsers.append(contactUser)
            }
        }
    }
}

extension MatchContactUserViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactUsers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MatchContactUserCell.reuseId, forIndexPath: indexPath) as! MatchContactUserCell
        cell.setSeparatorFullWidth()
        cell.user = contactUsers[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? MatchContactUserCell,let contactUser = c.user{
            if contactUser.matchedPhoneUsers.count == 0 {
                for phone in contactUser.phone {
                    if let user = userService.getCachedUserByMobile(phone){
                        let matchUser = MobileMatchedUser(user: user)
                        contactUser.matchedPhoneUsers[matchUser.usrId] = matchUser
                        contactUsers[indexPath.row] = contactUser
                        break
                    }
                }
            }
            c.updateCell(fileService)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MatchContactUserCell{
            cell.selected = false
            if cell.user.matchedPhoneUsers.count > 0 {
                
            }else if !cell.user.checked {
                checkUserJoinVG(cell,indexPath:indexPath)
            }
        }
    }
    
    func checkUserJoinVG(cell:MatchContactUserCell,indexPath:NSIndexPath) {
        if cell.user?.matchedPhoneUsers.count == 0 {
            let hud = self.showActivityHud()
            userService.matchUserProfilesByMobiles(cell.user.phone, callback: { (matched) in
                hud.hideAnimated(true)
                if let m = matched{
                    for item in m{
                        cell.user?.matchedPhoneUsers[item.usrId] = item
                    }
                }
                if cell.user?.matchedPhoneUsers.count > 0{
                    self.contactUsers[indexPath.row] = cell.user
                }
                cell.updateCell(self.fileService)
            })
        }
    }
}

extension MobileMatchedUser{
    convenience init(user:VessageUser) {
        self.init()
        self.account = user.accountId
        self.avatar = user.avatar
        self.mobile = user.mobile
        self.nick = user.nickName
        self.usrId = user.userId
    }
}


/*
 //昵称
 let nikeName = ABRecordCopyValue(contact, kABPersonNicknameProperty)?
 .takeRetainedValue() as! String? ?? ""
 debugPrint("昵称：\(nikeName)")
 
 //公司（组织）
 let organization = ABRecordCopyValue(contact, kABPersonOrganizationProperty)?
 .takeRetainedValue() as! String? ?? ""
 debugPrint("公司（组织）：\(organization)")
 
 //职位
 let jobTitle = ABRecordCopyValue(contact, kABPersonJobTitleProperty)?
 .takeRetainedValue() as! String? ?? ""
 debugPrint("职位：\(jobTitle)")
 
 //部门
 let department = ABRecordCopyValue(contact, kABPersonDepartmentProperty)?
 .takeRetainedValue() as! String? ?? ""
 debugPrint("部门：\(department)")
 
 //备注
 let note = ABRecordCopyValue(contact, kABPersonNoteProperty)?
 .takeRetainedValue() as! String? ?? ""
 debugPrint("备注：\(note)")
 */


/*
 //获取Email
 let emailValues:ABMutableMultiValueRef? =
 ABRecordCopyValue(contact, kABPersonEmailProperty).takeRetainedValue()
 if emailValues != nil {
 debugPrint("Email：")
 for i in 0 ..< ABMultiValueGetCount(emailValues){
 
 // 获得标签名
 let label = ABMultiValueCopyLabelAtIndex(emailValues, i).takeRetainedValue()
 as CFStringRef;
 let localizedLabel = ABAddressBookCopyLocalizedLabel(label)
 .takeRetainedValue() as String?
 
 let value = ABMultiValueCopyValueAtIndex(emailValues, i)
 let email = value.takeRetainedValue() as! String
 debugPrint("  \(localizedLabel):\(email)")
 }
 }
 
 //获取地址
 let addressValues:ABMutableMultiValueRef? =
 ABRecordCopyValue(contact, kABPersonAddressProperty).takeRetainedValue()
 if addressValues != nil {
 debugPrint("地址：")
 for i in 0 ..< ABMultiValueGetCount(addressValues){
 
 // 获得标签名
 let label = ABMultiValueCopyLabelAtIndex(addressValues, i).takeRetainedValue()
 as CFStringRef;
 let localizedLabel = ABAddressBookCopyLocalizedLabel(label)
 .takeRetainedValue() as String?
 
 let value = ABMultiValueCopyValueAtIndex(addressValues, i)
 let addrNSDict:NSMutableDictionary = value.takeRetainedValue()
 as! NSMutableDictionary
 let country:String = addrNSDict.valueForKey(kABPersonAddressCountryKey as String)
 as? String ?? ""
 let state:String = addrNSDict.valueForKey(kABPersonAddressStateKey as String)
 as? String ?? ""
 let city:String = addrNSDict.valueForKey(kABPersonAddressCityKey as String)
 as? String ?? ""
 let street:String = addrNSDict.valueForKey(kABPersonAddressStreetKey as String)
 as? String ?? ""
 let contryCode:String = addrNSDict
 .valueForKey(kABPersonAddressCountryCodeKey as String) as? String ?? ""
 print("  \(localizedLabel): Contry:\(country) State:\(state) ")
 debugPrint("City:\(city) Street:\(street) ContryCode:\(contryCode) ")
 }
 }
 
 //获取纪念日
 let dateValues:ABMutableMultiValueRef? =
 ABRecordCopyValue(contact, kABPersonDateProperty).takeRetainedValue()
 if dateValues != nil {
 debugPrint("纪念日：")
 for i in 0 ..< ABMultiValueGetCount(dateValues){
 
 // 获得标签名
 let label = ABMultiValueCopyLabelAtIndex(emailValues, i).takeRetainedValue()
 as CFStringRef;
 let localizedLabel = ABAddressBookCopyLocalizedLabel(label)
 .takeRetainedValue() as String?
 
 let value = ABMultiValueCopyValueAtIndex(dateValues, i)
 let date = (value.takeRetainedValue() as? NSDate)?.description ?? ""
 debugPrint("  \(localizedLabel):\(date)")
 }
 }
 
 //获取即时通讯(IM)
 let imValues:ABMutableMultiValueRef? =
 ABRecordCopyValue(contact, kABPersonInstantMessageProperty).takeRetainedValue()
 if imValues != nil {
 debugPrint("即时通讯(IM)：")
 for i in 0 ..< ABMultiValueGetCount(imValues){
 
 // 获得标签名
 let label = ABMultiValueCopyLabelAtIndex(imValues, i).takeRetainedValue()
 as CFStringRef;
 let localizedLabel = ABAddressBookCopyLocalizedLabel(label)
 .takeRetainedValue() as String?
 
 let value = ABMultiValueCopyValueAtIndex(imValues, i)
 let imNSDict:NSMutableDictionary = value.takeRetainedValue()
 as! NSMutableDictionary
 let serves:String = imNSDict
 .valueForKey(kABPersonInstantMessageServiceKey as String) as? String ?? ""
 let userName:String = imNSDict
 .valueForKey(kABPersonInstantMessageUsernameKey as String) as? String ?? ""
 debugPrint("  \(localizedLabel): Serves:\(serves) UserName:\(userName)")
 
 
 }
 }
 */
