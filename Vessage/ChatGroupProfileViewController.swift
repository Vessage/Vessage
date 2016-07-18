//
//  ChatGroupProfileViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/16.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ChatGroupProfileCellBase: UITableViewCell {
    var rootController:ChatGroupProfileViewController!
    var chatGroup:ChatGroup!{
        return rootController.chatGroup
    }
    
    static func getReuseId()->String{
        return "ChatGroupProfileCellBase"
    }
}

class ChatGroupProfileViewController: UIViewController,SelectVessageUserViewControllerDelegate {

    private(set) var chatGroup:ChatGroup!{
        didSet{
            if chatGroup.hosters.contains(userService.myProfile.userId) {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ChatGroupProfileViewController.addUserToGroup(_:)))
            }
        }
    }
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getService(FileService)
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.tableFooterView = UIView()
            tableView.tableFooterView?.backgroundColor = UIColor.clearColor()
        }
    }
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!{
        didSet{
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.getChatGroupService().addObserver(self, selector: #selector(ChatGroupProfileViewController.onChatGroupUpdated(_:)), name: ChatGroupService.OnChatGroupUpdated, object: nil)
        userService.addObserver(self, selector: #selector(ChatGroupProfileViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getChatGroupService().removeObserver(self)
        userService.removeObserver(self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        collectionViewHeight.constant = collectionView.contentSize.height
    }
    
    func onChatGroupUpdated(a:NSNotification){
        if let g = a.userInfo?[kChatGroupValue] as? ChatGroup{
            if g.groupId == self.chatGroup.groupId {
                self.chatGroup = g
                self.tableView.reloadData()
            }
        }
    }
    
    func onUserProfileUpdated(a:NSNotification) {
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if let index = (chatGroup.chatters.indexOf{$0 == user.userId}){
                collectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow:index,inSection: 0)])
            }
        }
    }
    
    func addUserToGroup(sender: AnyObject) {
        let controller = SelectVessageUserViewController.showSelectVessageUserViewController(self.navigationController!)
        controller.delegate = self
        controller.allowsMultipleSelection = false
        controller.showNearUsers = false
        controller.showActiveUsers = false
        controller.title = "SELECT_GROUP_CHAT_PEOPLE".localizedString()
    }
    
    func canSelect(sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) -> Bool {
        if selectedUsers.count + chatGroup.chatters.count > maxGroupChatUserCount {
            sender.playToast("GROUP_CHAT_PEOPLE_NUM_LIMIT".localizedString())
            return false
        }else if selectedUsers.count > 0{
            if chatGroup.chatters.contains(selectedUsers.first!.userId) {
                sender.playToast("USER_ALREADY_IN_GROUP".localizedString())
                return false
            }
            return true
        }else{
            return false
        }
    }
    
    func onFinishSelect(sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) {
        ServiceContainer.getChatGroupService().addUserJoinChatGroup(chatGroup.groupId, userId: selectedUsers.first!.userId){ suc in
            if suc{
                self.playCheckMark("ADD_USER_TO_GROUP_SUCCESS".localizedString())
            }else{
                self.playCrossMark("ADD_USER_TO_GROUP_ERROR".localizedString())
            }
        }
    }
    static func showProfileViewController(vc:UINavigationController, chatGroup:ChatGroup){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ChatGroupProfileViewController") as! ChatGroupProfileViewController
        controller.chatGroup = chatGroup
        vc.pushViewController(controller, animated: true)
    }
}

extension ChatGroupProfileViewController{
    
    private func showEditGroupNameAlert(){
        let title = "EDIT_GROUP_CHAT_NAME".localizedString()
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
            textfield.placeholder = "GROUP_CHAT_NAME".localizedString()
            textfield.borderStyle = .None
            textfield.text = self.chatGroup.groupName
        })
        
        let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
            let newNoteName = alertController.textFields?[0].text ?? ""
            if String.isNullOrEmpty(newNoteName)
            {
                self.playToast("GROUP_NAME_CANT_NULL".localizedString())
            }else{
                let hud = self.showActivityHud()
                ServiceContainer.getChatGroupService().editChatGroupName(self.chatGroup.groupId, inviteCode: self.chatGroup.inviteCode, newName: newNoteName){ suc in
                    hud.hide(true)
                    if suc{
                        self.playCheckMark("GROUP_NAME_EDITED".localizedString())
                    }else{
                        self.playCrossMark("GROUP_NAME_EDIT_ERROR".localizedString())
                    }
                }
            }
        })
        let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
        alertController.addAction(no)
        alertController.addAction(yes)
        self.showAlert(alertController)
    }
}

extension ChatGroupProfileViewController{
    func exitChatGroup() {
        let okAction = UIAlertAction(title: "YES".localizedString(), style: .Default) { (ac) in
            let hud = self.showActivityHud()
            ServiceContainer.getChatGroupService().quitChatGroup(self.chatGroup.groupId){ suc in
                hud.hide(true)
                if suc{
                    self.playToast("YOU_EXITED_GROUP_CHAT".localizedString()){
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }else{
                    self.playCrossMark("EXITING_GROUP_CHAT_ERROR".localizedString())
                }
            }
        }
        
        self.showAlert("EXIT_GROUP_CHAT_ASK_TITLE".localizedString(), msg: chatGroup.groupName, actions: [okAction,ALERT_ACTION_CANCEL])
    }
}

//MARK: Table View Delegate
extension ChatGroupProfileViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(GroupNameCell.reuseId, forIndexPath: indexPath) as! GroupNameCell
            cell.rootController = self
            cell.groupName.text = chatGroup.groupName
            return cell
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier("ExitGroupChatCell", forIndexPath: indexPath)
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
        if indexPath.section == 0{
            showEditGroupNameAlert()
        }else if indexPath.section == 1{
            exitChatGroup()
        }
    }
}


//MARK: Users CollectionView
extension ChatGroupProfileViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = chatGroup.chatters?.count {
            return count
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(GroupUserCollectionCell.reuseId, forIndexPath: indexPath) as! GroupUserCollectionCell
        let userId = self.chatGroup.chatters[indexPath.row]
        if let user = userService.getCachedUserProfile(userId) {
            self.updateCell(cell, user: user)
        }else{
            cell.nick.text = "UNLOADED_USER".localizedString()
            userService.fetchUserProfile(userId)
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let userId = self.chatGroup.chatters[indexPath.row]
        if let user = userService.getCachedUserProfile(userId) {
            userService.showUserProfile(self, user: user)
        }else{
            userService.fetchUserProfile(userId)
            self.playToast("USER_DATA_NOT_READY_RETRY".localizedString())
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(60, 80)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    private func updateCell(cell:GroupUserCollectionCell,user:VessageUser){
        fileService.setAvatar(cell.avatar, iconFileId: user.avatar,defaultImage: getDefaultAvatar(user.accountId ?? ""))
        cell.nick.text = userService.getUserNotedName(user.userId)
    }
}
