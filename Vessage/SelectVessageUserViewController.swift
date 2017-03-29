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
    func onFinishSelect(_ sender:SelectVessageUserViewController, selectedUsers:[VessageUser])
    func canSelect(_ sender:SelectVessageUserViewController, selectedUsers:[VessageUser]) -> Bool
}

class SelectVessageUserContactCell: UITableViewCell {
    static let reuseId = "SelectVessageUserContactCell"
}


class SelectVessageUserListCell: UITableViewCell {
    static let reuseId = "SelectVessageUserListCell"
    
    override var isSelected: Bool{
        didSet{
            if checkedImage != nil{
                checkedImage.isHidden = !isSelected
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
            checkedImage.isHidden = !isSelected
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
    fileprivate var userInfos = [VessageUser](){
        didSet{
            tableView?.reloadSections(IndexSet(integer: SECTION_CONTACT_USER), with: .automatic)
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
            tableView?.reloadSections(IndexSet(integer: SECTION_ACTIVE_USER), with: .automatic)
        }
    }
    
    var showNearUsers:Bool = false{
        didSet{
            tableView?.reloadSections(IndexSet(integer: SECTION_NEAR_USER), with: .automatic)
        }
    }
    
    fileprivate var activeUsers = [VessageUser](){
        didSet{
            tableView?.reloadSections(IndexSet(integer: SECTION_ACTIVE_USER), with: .automatic)
        }
    }
    
    fileprivate var nearUsers = [VessageUser](){
        didSet{
            tableView?.reloadSections(IndexSet(integer: SECTION_NEAR_USER), with: .automatic)
        }
    }
    
    fileprivate var activeUserExpanded = false{
        didSet{
            tableView?.reloadSections(IndexSet(integer: SECTION_ACTIVE_USER), with: .automatic)
        }
    }
    
    fileprivate var nearUserExpanded = false{
        didSet{
            tableView?.reloadSections(IndexSet(integer: SECTION_NEAR_USER), with: .automatic)
        }
    }
    
    fileprivate var contactUserHeader = SelectVessageExpandableHeader.instanceFromXib()
    
    fileprivate var activeUserHeader = SelectVessageExpandableHeader.instanceFromXib()
    
    fileprivate var nearUserHeader = SelectVessageExpandableHeader.instanceFromXib()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        let conversations = ServiceContainer.getConversationService().conversations.filter{!String.isNullOrEmpty($0.chatterId) && String.isNullOrWhiteSpace($0.acId) && $0.type == Conversation.typeSingleChat }
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

    @IBAction func finishSelect(_ sender: AnyObject) {
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
                let _ = self.navigationController?.popViewController(animated: true)
                dg.onFinishSelect(self, selectedUsers: selectedUsers)
            }
        }else{
            let _ = self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    fileprivate func showContactView(){
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        let hud = self.showAnimationHud()
        self.present(controller, animated: true) { () -> Void in
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
    func peoplePickerNavigationController(_ peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecord) {
        peoplePicker.dismiss(animated: true) { () -> Void in
            selectPersonMobile(self,person: person, onSelectedMobile: { (mobile,title) in
                let userService = ServiceContainer.getUserService()
                let user = userService.getCachedUserByMobile(mobile)
                if user == nil{
                    let hud = self.showAnimationHud()
                    userService.fetchUserProfileByMobile(mobile, lastUpdatedTime: nil, updatedCallback: { (mUser) in
                        hud.hide(animated: true)
                        if let u = mUser{
                            self.userInfos.insert(u, at: 0)
                            let indexPath = IndexPath(row: 0,section: self.SECTION_CONTACT_USER)
                            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                            self.tableView(self.tableView, didSelectRowAt: indexPath)
                        }else{
                            let title = "NO_USER_OF_MOBILE".localizedString()
                            let msg = String(format: "MOBILE_X_INVITE_JOIN_VG".localizedString(), mobile)
                            let invite = UIAlertAction(title: "INVITE".localizedString(), style: .default, handler: { (ac) in
                                ShareHelper.instance.showTellVegeToFriendsAlert(self,message: "TELL_FRIEND_MESSAGE".localizedString(),alertMsg: "TELL_FRIENDS_ALERT_MSG".localizedString())
                            })
                            
                            self.showAlert(title, msg: msg,actions: [ALERT_ACTION_CANCEL,invite])
                        }
                    })
                    
                }else{
                    var indexPath = IndexPath(row: 0,section: self.SECTION_CONTACT_USER)
                    if let index = self.userInfos.index(where: { (u) -> Bool in
                        VessageUser.isTheSameUser(u, userb: user)
                    }){
                        indexPath = IndexPath(row: index,section: self.SECTION_CONTACT_USER)
                    }else{
                        self.userInfos.insert(user!, at: 0)
                    }
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                    self.tableView(self.tableView, didSelectRowAt: indexPath)
                }
            })
        }
    }
    
    //MARK: Table View delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath){
            cell.isSelected = false
        }
        updateDoneButton()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == SECTION_CHOOSE_MOBILE {
            cell?.isSelected = false
            tableView.deselectRow(at: indexPath, animated: true)
            showContactView()
        }else{
            cell?.isSelected = true
            updateDoneButton()
        }
    }
    
    fileprivate func updateDoneButton(){
        var count = 0
        if let rows = tableView.indexPathsForSelectedRows {
            self.navigationItem.rightBarButtonItem?.isEnabled = rows.count > 0
            count = rows.count
        }else{
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        self.navigationItem.rightBarButtonItem?.title = "CONFIRM".localizedString() + (count > 0 ? "(\(count))" : "")
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_CHOOSE_MOBILE {
            return tableView.dequeueReusableCell(withIdentifier: SelectVessageUserContactCell.reuseId, for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectVessageUserListCell.reuseId, for: indexPath) as! SelectVessageUserListCell
        if indexPath.section == SECTION_ACTIVE_USER {
            cell.user = activeUsers[indexPath.row]
        }else if(indexPath.section == SECTION_NEAR_USER){
            cell.user = nearUsers[indexPath.row]
        }
        else{
            cell.user = userInfos[indexPath.row]
        }
        cell.isSelected = false
        return cell
    }
    
    static func showSelectVessageUserViewController(_ nvc:UINavigationController) -> SelectVessageUserViewController{
        let controller = instanceFromStoryBoard("User", identifier: "SelectVessageUserViewController") as! SelectVessageUserViewController
        nvc.pushViewController(controller, animated: true)
        return controller
    }
}
