//
//  SelectVessageUserViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import AddressBook
import AddressBookUI

protocol SelectVessageUserViewControllerDelegate {
    func onFinishSelect(sender:SelectVessageUserViewController, selectedUsers:[VessageUser])
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
            nickLabel.text = ServiceContainer.getUserService().getUserNotedName(user.userId)
            if String.isNullOrEmpty(user.avatar) {
                avatarImage.image = UIImage(named: "defaultAvatar")!
            }else{
                ServiceContainer.getService(FileService).setAvatar(avatarImage, iconFileId: user.avatar)
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
    var delegate:SelectVessageUserViewControllerDelegate!
    let SECTION_CHOOSE_MOBILE = 0
    let SECTION_ACTIVE_USER = 1
    let SECTION_CONTACT_USER = 2
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
    var activeUsers = [VessageUser](){
        didSet{
            tableView?.reloadSections(NSIndexSet(index: SECTION_ACTIVE_USER), withRowAnimation: .Automatic)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        let conversations = ServiceContainer.getConversationService().conversations.filter{!String.isNullOrEmpty($0.chatterId)}
        let userService = ServiceContainer.getUserService()
        activeUsers = userService.activeUsers
        userInfos = conversations.map { (c) -> VessageUser in
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
    }

    @IBAction func finishSelect(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
        if let handler = delegate?.onFinishSelect{
            if let rows = tableView.indexPathsForSelectedRows{
                handler(self, selectedUsers: rows.map{
                    if $0.section == SECTION_ACTIVE_USER{
                        return activeUsers[$0.row]
                    }
                        return userInfos[$0.row]
                    }
                )
            }else{
                handler(self, selectedUsers: [])
            }
        }
    }
    
    private func showContactView(){
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        let hud = self.showActivityHud()
        self.presentViewController(controller, animated: true) { () -> Void in
            MobClick.event("OpenContactView")
            hud.hideAsync(true)
        }
    }
    
    //MARK: ABPeoplePickerNavigationControllerDelegate
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
        peoplePicker.dismissViewControllerAnimated(true) { () -> Void in
            selectPersonMobile(self,person: person, onSelectedMobile: { (mobile,title) in
                let userService = ServiceContainer.getUserService()
                let user = userService.getCachedUserByMobile(mobile)
                if user == nil{
                    let hud = self.showActivityHud()
                    userService.registNewUserByMobile(mobile, noteName: title, updatedCallback: { (mUser) in
                        hud.hide(true)
                        if mUser != nil{
                            self.userInfos.insert(mUser!, atIndex: 0)
                            let indexPath = NSIndexPath(forRow: 0,inSection: self.SECTION_CONTACT_USER)
                            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Top)
                            self.tableView(self.tableView, didSelectRowAtIndexPath: indexPath)
                        }else{
                            self.playToast("NO_SUCH_USER".localizedString())
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
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_CHOOSE_MOBILE {
            return 1
        }else if section == SECTION_ACTIVE_USER {
            return showActiveUsers ? activeUsers.count : 0
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
        if let rows = tableView.indexPathsForSelectedRows {
            self.navigationItem.rightBarButtonItem?.enabled = rows.count > 0
        }else{
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_CHOOSE_MOBILE{
            return nil
        }else if section == SECTION_ACTIVE_USER {
            return showActiveUsers && activeUsers.count > 0 ? "ACTIVE_USERS".localizedString() : nil
        }
        return userInfos.count > 0 ? "CONTACTS".localizedString() : "INVITE_FRIENDS_TO_CONVERSATION".localizedString()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_CHOOSE_MOBILE {
            return tableView.dequeueReusableCellWithIdentifier(SelectVessageUserContactCell.reuseId, forIndexPath: indexPath)
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(SelectVessageUserListCell.reuseId, forIndexPath: indexPath) as! SelectVessageUserListCell
        if indexPath.section == SECTION_ACTIVE_USER {
            cell.user = activeUsers[indexPath.row]
        }else{
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