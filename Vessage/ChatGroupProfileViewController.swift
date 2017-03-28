//
//  ChatGroupProfileViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/16.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ChatGroupProfileCellBase: UITableViewCell {
    weak var rootController:ChatGroupProfileViewController!
    var chatGroup:ChatGroup!{
        return rootController.chatGroup
    }
}

class ChatGroupProfileViewController: UIViewController,SelectVessageUserViewControllerDelegate {

    fileprivate(set) var chatGroup:ChatGroup!{
        didSet{
            if chatGroup.hosters.contains(UserSetting.userId) {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ChatGroupProfileViewController.addUserToGroup(_:)))
                self.navigationItem.rightBarButtonItem?.tintColor = UIColor.themeColor
            }
        }
    }
    let userService = ServiceContainer.getUserService()
    let fileService = ServiceContainer.getFileService()
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.tableFooterView = UIView()
            tableView.tableFooterView?.backgroundColor = UIColor.clear
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.getChatGroupService().addObserver(self, selector: #selector(ChatGroupProfileViewController.onChatGroupUpdated(_:)), name: ChatGroupService.OnChatGroupUpdated, object: nil)
        userService.addObserver(self, selector: #selector(ChatGroupProfileViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getChatGroupService().removeObserver(self)
        userService.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionViewHeight.constant = collectionView.contentSize.height
    }
    
    func onChatGroupUpdated(_ a:Notification){
        if let g = a.userInfo?[kChatGroupValue] as? ChatGroup{
            if g.groupId == self.chatGroup.groupId {
                self.chatGroup = g
                self.collectionView?.reloadData()
                self.tableView?.reloadData()
            }
        }
    }
    
    func onUserProfileUpdated(_ a:Notification) {
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            if let index = (chatGroup.chatters.index{$0 == user.userId}){
                collectionView.reloadItems(at: [IndexPath(row:index,section: 0)])
            }
        }
    }
    
    func addUserToGroup(_ sender: AnyObject) {
        let controller = SelectVessageUserViewController.showSelectVessageUserViewController(self.navigationController!)
        controller.delegate = self
        controller.allowsMultipleSelection = false
        controller.showNearUsers = false
        controller.showActiveUsers = false
        controller.title = "SELECT_GROUP_CHAT_PEOPLE".localizedString()
    }
    
    func canSelect(_ sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) -> Bool {
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
    
    func onFinishSelect(_ sender: SelectVessageUserViewController, selectedUsers: [VessageUser]) {
        let selectUserId = selectedUsers.first!.userId!
        ServiceContainer.getChatGroupService().addUserJoinChatGroup(chatGroup.groupId, userId: selectUserId){ suc in
            if suc{
                self.playCheckMark("ADD_USER_TO_GROUP_SUCCESS".localizedString())
            }else{
                self.playCrossMark("ADD_USER_TO_GROUP_ERROR".localizedString())
            }
        }
    }
    static func showProfileViewController(_ vc:UINavigationController, chatGroup:ChatGroup){
        let controller = instanceFromStoryBoard("Conversation", identifier: "ChatGroupProfileViewController") as! ChatGroupProfileViewController
        controller.chatGroup = chatGroup
        vc.pushViewController(controller, animated: true)
    }
}

extension ChatGroupProfileViewController{
    
    fileprivate func showEditGroupNameAlert(){
        let title = "EDIT_GROUP_CHAT_NAME".localizedString()
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { (textfield) -> Void in
            textfield.placeholder = "GROUP_CHAT_NAME".localizedString()
            textfield.borderStyle = .none
            textfield.text = self.chatGroup.groupName
        })
        
        let yes = UIAlertAction(title: "YES".localizedString() , style: .default, handler: { (action) -> Void in
            let newNoteName = alertController.textFields?[0].text ?? ""
            if String.isNullOrEmpty(newNoteName)
            {
                self.playToast("GROUP_NAME_CANT_NULL".localizedString())
            }else{
                let hud = self.showAnimationHud()
                ServiceContainer.getChatGroupService().editChatGroupName(self.chatGroup.groupId, inviteCode: self.chatGroup.inviteCode, newName: newNoteName){ suc in
                    hud.hide(animated: true)
                    if suc{
                        self.playCheckMark("GROUP_NAME_EDITED".localizedString())
                    }else{
                        self.playCrossMark("GROUP_NAME_EDIT_ERROR".localizedString())
                    }
                }
            }
        })
        let no = UIAlertAction(title: "NO".localizedString(), style: .cancel,handler:nil)
        alertController.addAction(no)
        alertController.addAction(yes)
        self.showAlert(alertController)
    }
}

extension ChatGroupProfileViewController{
    func exitChatGroup() {
        let okAction = UIAlertAction(title: "YES".localizedString(), style: .default) { (ac) in
            let hud = self.showAnimationHud()
            ServiceContainer.getChatGroupService().quitChatGroup(self.chatGroup.groupId){ suc in
                hud.hide(animated: true)
                if suc{
                    self.playToast("YOU_EXITED_GROUP_CHAT".localizedString()){
                        let _ = self.navigationController?.popViewController(animated: true)
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupNameCell.reuseId, for: indexPath) as! GroupNameCell
            cell.rootController = self
            cell.groupName.text = chatGroup.groupName
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExitGroupChatCell", for: indexPath)
            cell.setSeparatorFullWidth()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        if indexPath.section == 0{
            showEditGroupNameAlert()
        }else if indexPath.section == 1{
            exitChatGroup()
        }
    }
}


//MARK: Users CollectionView
extension ChatGroupProfileViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = chatGroup.chatters?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupUserCollectionCell.reuseId, for: indexPath) as! GroupUserCollectionCell
        let userId = self.chatGroup.chatters[indexPath.row]
        if let user = userService.getCachedUserProfile(userId) {
            self.updateCell(cell, user: user)
        }else{
            cell.nick.text = "UNLOADED_USER".localizedString()
            userService.fetchUserProfile(userId)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let userId = self.chatGroup.chatters[indexPath.row]
        if let user = userService.getCachedUserProfile(userId) {
            let delegate = UserProfileViewControllerDelegateAddConversation()
            delegate.beforeRemoveTimeSpan = ConversationMaxTimeUpMS
            delegate.createActivityId = VGActivityGroupChatActivityId
            let controller = userService.showUserProfile(self, user: user,delegate: delegate)
            controller.accountIdHidden = true
            controller.snsButtonEnabled = false
        }else{
            userService.fetchUserProfile(userId)
            self.playToast("USER_DATA_NOT_READY_RETRY".localizedString())
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    fileprivate func updateCell(_ cell:GroupUserCollectionCell,user:VessageUser){
        fileService.setImage(cell.avatar, iconFileId: user.avatar,defaultImage: getDefaultAvatar(user.accountId ?? "",sex: user.sex))
        cell.nick.text = userService.getUserNotedName(user.userId)
    }
}
