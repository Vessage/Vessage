//
//  SelectVessageUserViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

protocol SelectVessageUserViewControllerDelegate {
    func onFinishSelect(sender:SelectVessageUserViewController, selectedUsers:[VessageUser])
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
            nickLabel.text = user.nickName
            ServiceContainer.getService(FileService).setAvatar(avatarImage, iconFileId: user.avatar)
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

class SelectVessageUserViewController: UITableViewController {
    var delegate:SelectVessageUserViewControllerDelegate!
    private var userInfos = [VessageUser](){
        didSet{
            tableView.reloadData()
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
            if tableView != nil{
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            }
        }
    }
    var activeUsers = [VessageUser]()
    
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
                handler(self, selectedUsers: rows.map{userInfos[$0.row]})
            }else{
                handler(self, selectedUsers: [])
            }
        }
    }
    
    //MARK: Table View delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return activeUsers.count
        }
        return userInfos.count
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath){
            cell.selected = false
        }
        if let rows = tableView.indexPathsForSelectedRows {
            self.navigationItem.rightBarButtonItem?.enabled = rows.count > 0
        }else{
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath){
            cell.selected = true
        }
        if let rows = tableView.indexPathsForSelectedRows {
            self.navigationItem.rightBarButtonItem?.enabled = rows.count > 0
        }else{
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return showActiveUsers && activeUsers.count > 0 ? "ACTIVE_USERS".localizedString() : nil
        }
        return userInfos.count > 0 ? "CONTACTS".localizedString() : "INVITE_FRIENDS_TO_CONVERSATION".localizedString()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SelectVessageUserListCell.reuseId, forIndexPath: indexPath) as! SelectVessageUserListCell
        if indexPath.section == 0 {
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