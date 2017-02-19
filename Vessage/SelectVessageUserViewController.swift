//
//  SelectVessageUserViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import AddressBook
import AddressBookUI

@objc protocol SelectVessageUserViewControllerDelegate {
    func onFinishSelect(sender:SelectVessageUserViewController, selectedUsers:[VessageUser])
    func canSelect(sender:SelectVessageUserViewController, selectedUsers:[VessageUser]) -> Bool
}

class SelectVessageUserContactCell: UITableViewCell {
    static let reuseId = "SelectVessageUserContactCell"
}


class SelectVessageUserListCell: UITableViewCell {
    static let reuseId = "SelectVessageUserListCell"
    
    override var selected: Bool{
        didSet{
            if checkedImage != nil{
                checkedImage.hidden = !selected
            }
        }
    }
    
    var user:VessageUser!{
        didSet{
            if let u = user{
                nickLabel.text = ServiceContainer.getUserService().getUserNotedNameIfExists(u.userId) ?? u.nickName
                if String.isNullOrEmpty(u.avatar) {
                    avatarImage.image = getDefaultAvatar(u.accountId ?? "0",sex: u.sex)
                }else{
                    ServiceContainer.getFileService().setImage(avatarImage, iconFileId: user.avatar)
                }
            }
        }
    }
    
    @IBOutlet weak var checkedImage: UIImageView!{
        didSet{
            checkedImage.hidden = !selected
        }
    }
    @IBOutlet weak var nickLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!{
        didSet{
            avatarImage.clipsToBounds = true
            avatarImage.layer.cornerRadius = 3
        }
    }
}

class SelectVessageUserViewController: UITableViewController,ABPeoplePickerNavigationControllerDelegate {
    weak var delegate:SelectVessageUserViewControllerDelegate!
    let SECTION_CHOOSE_MOBILE = 0
    let SECTION_ACTIVE_USER = 1
    let SECTION_NEAR_USER = 2
    let SECTION_CONTACT_USER = 3
    private var userInfos = [VessageUser](){
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_CONTACT_USER), withRowAnimation: .Automatic)
        }
    }
    
    var allowsMultipleSelection:Bool{
        get{
            return tableView.allowsMultipleSelection
        }
        set{
            tableView.allowsMultipleSelection = newValue
        }
    }
    
    var showActiveUsers:Bool = false{
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_ACTIVE_USER), withRowAnimation: .Automatic)
        }
    }
    
    var showNearUsers:Bool = false{
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_NEAR_USER), withRowAnimation: .Automatic)
        }
    }
    
    private var activeUsers = [VessageUser](){
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_ACTIVE_USER), withRowAnimation: .Automatic)
        }
    }
    
    private var nearUsers = [VessageUser](){
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_NEAR_USER), withRowAnimation: .Automatic)
        }
    }
    
    private var activeUserExpanded = false{
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_ACTIVE_USER), withRowAnimation: .Automatic)
        }
    }
    
    private var nearUserExpanded = false{
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_NEAR_USER), withRowAnimation: .Automatic)
        }
    }
    
    private var contactUserHeader = SelectVessageExpandableHeader.instanceFromXib()
    
    private var activeUserHeader = SelectVessageExpandableHeader.instanceFromXib()
    
    private var nearUserHeader = SelectVessageExpandableHeader.instanceFromXib()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        let conversations = ServiceContainer.getConversationService().conversations.filter{!String.isNullOrEmpty($0.chatterId) && String.isNullOrWhiteSpace($0.acId) }
        let userService = ServiceContainer.getUserService()
        activeUsers = userService.activeUsers
        nearUsers = userService.nearUsers
        
        userInfos = conversations.filter{!$0.isGroupChat}.map { (c) -> VessageUser in
            if let res = userService.getCachedUserProfile(c.chatterId){
                return res
            }else{
                let res = VessageUser()
                res.userId = c.chatterId
                userService.getUserProfile(c.chatterId, updatedCallback: { (user) in
                    if let u = user{
                        res.accountId = u.accountId
                        res.avatar = u.avatar
                        res.motto = u.motto
                        res.mobile = u.mobile
                        res.nickName = u.nickName
                    }
                })
                return res
            }
        }
        activeUserHeader.title.text = "ACTIVE_USER".localizedString()
        nearUserHeader.title.text = "NEAR_USER".localizedString()
        contactUserHeader.title.text = userInfos.count > 0 ? "CONVERSATION_USERS".localizedString() : "INVITE_FRIENDS_TO_CONVERSATION".localizedString()
        contactUserHeader.expanded = true
        activeUserHeader.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SelectVessageUserViewController.onClickActiveUserHeader(_:))))
        nearUserHeader.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SelectVessageUserViewController.onClickNearUserHeader(_:))))
        if showNearUsers {
            if let location = ServiceContainer.getLocationService().hereLocationString{
                userService.getNearUsers(location, callback: { (nearUsers) in
                    if nearUsers.count > 0{
                        self.nearUsers = nearUsers
                    }
                })
            }
        }
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }

    @IBAction func finishSelect(sender: AnyObject) {
        if let dg = delegate{
            var selectedUsers = [VessageUser]()
            if let rows = tableView.indexPathsForSelectedRows{
                selectedUsers = rows.map{
                    if $0.section == SECTION_ACTIVE_USER{
                        return activeUsers[$0.row]
                    }
                    return userInfos[$0.row]
                }
            }
            if dg.canSelect(self, selectedUsers: selectedUsers) {
                self.navigationController?.popViewControllerAnimated(true)
                dg.onFinishSelect(self, selectedUsers: selectedUsers)
            }
        }else{
            self.navigationController?.popViewControllerAnimated(true)
        }
        
    }
    
    private func showContactView(){
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        let hud = self.showAnimationHud()
        self.presentViewController(controller, animated: true) { () -> Void in
            MobClick.event("Vege_OpenContactView")
            hud.hideAsync(true)
        }
    }
    
    func onClickActiveUserHeader(_:UITapGestureRecognizer) {
        activeUserExpanded = !activeUserExpanded
    }
    
    func onClickNearUserHeader(_:UITapGestureRecognizer) {
        nearUserExpanded = !nearUserExpanded
    }
    
    //MARK: ABPeoplePickerNavigationControllerDelegate
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
        peoplePicker.dismissViewControllerAnimated(true) { () -> Void in
            selectPersonMobile(self,person: person, onSelectedMobile: { (mobile,title) in
                let userService = ServiceContainer.getUserService()
                let user = userService.getCachedUserByMobile(mobile)
                if user == nil{
                    let hud = self.showAnimationHud()
                    userService.fetchUserProfileByMobile(mobile, lastUpdatedTime: nil, updatedCallback: { (mUser) in
                        hud.hideAnimated(true)
                        if let u = mUser{
                            self.userInfos.insert(u, atIndex: 0)
                            let indexPath = NSIndexPath(forRow: 0,inSection: self.SECTION_CONTACT_USER)
                            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Top)
                            self.tableView(self.tableView, didSelectRowAtIndexPath: indexPath)
                        }else{
                            let title = "NO_USER_OF_MOBILE".localizedString()
                            let msg = String(format: "MOBILE_X_INVITE_JOIN_VG".localizedString(), mobile)
                            let invite = UIAlertAction(title: "INVITE".localizedString(), style: .Default, handler: { (ac) in
                                ShareHelper.instance.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString())
                            })
                            
                            self.showAlert(title, msg: msg,actions: [ALERT_ACTION_CANCEL,invite])
                        }
                    })
                    
                }else{
                    var indexPath = NSIndexPath(forRow: 0,inSection: self.SECTION_CONTACT_USER)
                    if let index = self.userInfos.indexOf({ (u) -> Bool in
                        VessageUser.isTheSameUser(u, userb: user)
                    }){
                        indexPath = NSIndexPath(forRow: index,inSection: self.SECTION_CONTACT_USER)
                    }else{
                        self.userInfos.insert(user!, atIndex: 0)
                    }
                    self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Top)
                    self.tableView(self.tableView, didSelectRowAtIndexPath: indexPath)
                }
            })
        }
    }
    
    //MARK: Table View delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_CHOOSE_MOBILE {
            return 1
        }else if section == SECTION_ACTIVE_USER {
            return showActiveUsers ? (activeUserExpanded ? activeUsers.count : 0) : 0
        }else if section == SECTION_NEAR_USER{
            return showNearUsers ? (nearUserExpanded ? nearUsers.count : 0) : 0
        }else{
            return userInfos.count
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath){
            cell.selected = false
        }
        updateDoneButton()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = indexPath != 0
        if indexPath.section == SECTION_CHOOSE_MOBILE {
            showContactView()
        }else{
            updateDoneButton()
        }
    }
    
    private func updateDoneButton(){
        var count = 0
        if let rows = tableView.indexPathsForSelectedRows {
            self.navigationItem.rightBarButtonItem?.enabled = rows.count > 0
            count = rows.count
        }else{
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
        
        self.navigationItem.rightBarButtonItem?.title = "CONFIRM".localizedString() + (count > 0 ? "(\(count))" : "")
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == SECTION_CHOOSE_MOBILE {
            return super.tableView(tableView, viewForHeaderInSection: section)
        }else if section == SECTION_CONTACT_USER{
            return contactUserHeader
        }
        else if section == SECTION_ACTIVE_USER{
            if showActiveUsers && activeUsers.count > 0{
                activeUserHeader.expanded = activeUserExpanded
                return activeUserHeader
            }
            return nil
        }else if section == SECTION_NEAR_USER{
            if showNearUsers && nearUsers.count > 0{
                
                nearUserHeader.expanded = nearUserExpanded
                return nearUserHeader
            }
            return nil
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == SECTION_CHOOSE_MOBILE {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }else if section == SECTION_CONTACT_USER{
            return 43
        }
        else if section == SECTION_ACTIVE_USER{
            if showActiveUsers && activeUsers.count > 0{
                return 43
            }
            return 0
        }else if section == SECTION_NEAR_USER{
            if showNearUsers && nearUsers.count > 0{
                return 43
            }
            return 0
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_CHOOSE_MOBILE {
            return tableView.dequeueReusableCellWithIdentifier(SelectVessageUserContactCell.reuseId, forIndexPath: indexPath)
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(SelectVessageUserListCell.reuseId, forIndexPath: indexPath) as! SelectVessageUserListCell
        if indexPath.section == SECTION_ACTIVE_USER {
            cell.user = activeUsers[indexPath.row]
        }else if(indexPath.section == SECTION_NEAR_USER){
            cell.user = nearUsers[indexPath.row]
        }
        else{
            cell.user = userInfos[indexPath.row]
        }
        cell.selected = false
        return cell
    }
    
    static func showSelectVessageUserViewController(nvc:UINavigationController) -> SelectVessageUserViewController{
        let controller = instanceFromStoryBoard("User", identifier: "SelectVessageUserViewController") as! SelectVessageUserViewController
        nvc.pushViewController(controller, animated: true)
        return controller
    }
}
