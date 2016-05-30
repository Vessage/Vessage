//
//  UserSettingViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

extension UserService
{
    func showMyDetailView(currentViewController:UIViewController)
    {
        let controller = UserSettingViewController.instanceFromStoryBoard()
        currentViewController.navigationController?.pushViewController(controller, animated: true)
    }
}

class MyDetailTextPropertyCell:UITableViewCell
{
    static let reuseIdentifier = "MyDetailTextPropertyCell"
    var info:MyDetailCellModel!{
        didSet{
            if propertyNameLabel != nil
            {
                propertyNameLabel.text = info?.propertySet?.propertyLabel
            }
            
            if propertyValueLabel != nil
            {
                propertyValueLabel.text = info?.propertySet?.propertyValue
            }
            
            if editableMark != nil
            {
                editableMark.hidden = !info!.editable
            }
        }
    }
    @IBOutlet weak var propertyNameLabel: UILabel!{
        didSet{
            propertyNameLabel.text = info?.propertySet?.propertyLabel
        }
    }
    @IBOutlet weak var propertyValueLabel: UILabel!{
        didSet{
            propertyValueLabel.text = info?.propertySet?.propertyValue
        }
    }
    @IBOutlet weak var editableMark: UIImageView!{
        didSet{
            if let i = info
            {
                editableMark.hidden = !i.editable
            }
        }
    }
    
}

class MyDetailAvatarCell:UITableViewCell
{
    static let reuseIdentifier = "MyDetailAvatarCell"
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.clipsToBounds = true
            avatarImageView.layer.cornerRadius = 7
        }
    }
}


struct MyDetailCellModel {
    var propertySet:UIEditTextPropertySet!
    var editable:Bool = false
    var selector:Selector!
}

//MARK:UserSettingViewController
class UserSettingViewController: UIViewController,UITableViewDataSource,UIEditTextPropertyViewControllerDelegate,UITableViewDelegate,UIImagePickerControllerDelegate,ProgressTaskDelegate
{
    static let aboutAppReuseId = "aboutApp"
    static let clearCacheCellReuseId = "clearCache"
    struct InfoIds
    {
        static let nickName = "nickname"
        static let level = "level"
        static let levelScore = "levelScore"
        static let motto = "signtext"
        static let createTime = "createtime"
        static let changePsw = "changePsw"
        static let useTink = "useTink"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myInfo = ServiceContainer.getUserService().myProfile
        self.navigationItem.title = UserSetting.lastLoginAccountId
        initPropertySet()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let uiview = UIView()
        tableView.backgroundColor = UIColor.footerColor
        tableView.tableFooterView = uiview
    }
    
    private var myInfo:VessageUser!
    
    private func initPropertySet()
    {
        var propertySet = UIEditTextPropertySet()
        
        propertySet.propertyIdentifier = InfoIds.nickName
        propertySet.propertyLabel = "NICK".localizedString()
        propertySet.propertyValue = myInfo.nickName
        textPropertyCells.append(MyDetailCellModel(propertySet: propertySet, editable: true, selector: #selector(UserSettingViewController.tapTextProperty(_:))))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "CHANGE_CHAT_BCG".localizedString()
        propertySet.propertyValue = ""
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.changeChatBcg(_:))))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "CHANGE_PSW".localizedString()
        propertySet.propertyValue = ""
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.changePassword(_:))))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "BIND_MOBILE".localizedString()
        if let mobile = myInfo.mobile{
            let length = mobile.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            let subfix = mobile.substringFromIndex(length - 4)
            propertySet.propertyValue = "***\(subfix)"
        }else{
            propertySet.propertyValue = "NOT_SET".localizedString()
        }
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.bindMobile(_:))))
        
    }
    
    @IBAction func logout(sender: AnyObject)
    {
        let alert = UIAlertController(title: "LOGOUT_CONFIRM_TITLE".localizedString(),
            message: "USER_DATA_WILL_SAVED".localizedString(), preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "YES".localizedString(), style: .Default) { _ in
            self.logout()
            })
        alert.addAction(UIAlertAction(title: "NO".localizedString(), style: .Cancel) { _ in
            self.cancelLogout()
            })
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelLogout()
    {
        
    }
    
    func logout()
    {
        ServiceContainer.instance.userLogout()
        EntryNavigationController.start()
    }
    
    //MARK: table view delegate
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 21
    }
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.dataSource = self
            tableView.delegate = self
            let uiview = UIView()
            uiview.backgroundColor = UIColor.clearColor()
            tableView.tableFooterView = uiview
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0
        {
            return 84
        }
        return UITableViewAutomaticDimension
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //user infos + about + clear tmp file
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            return 1 + textPropertyCells.count
        }else
        {
            return 1
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0
        {
            if indexPath.row == 0
            {
                return getAvatarCell()
            }else if indexPath.row > 0 && indexPath.row <= textPropertyCells.count
            {
                return getTextPropertyCell(indexPath.row - 1)
            }
            let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier, forIndexPath: indexPath)
            return cell
        }else if indexPath.section == 1
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UserSettingViewController.clearCacheCellReuseId,forIndexPath: indexPath)
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.clearTempDir(_:))))
            return cell
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UserSettingViewController.aboutAppReuseId,forIndexPath: indexPath)
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.aboutApp(_:))))
            return cell
        }
    }
    
    //MARK: change chat background
    func changeChatBcg(_:UITapGestureRecognizer)
    {
        ChatBackgroundPickerController.showPickerController(self) { (sender) -> Void in
            sender.dismissViewControllerAnimated(true, completion: { () -> Void in
                
            })
        }
    }
    
    //MARK: bind mobile
    func bindMobile(_:UITapGestureRecognizer)
    {
        SMSSDKUI.showVerificationCodeViewWithMetohd(SMSGetCodeMethodSMS) { (responseState, phoneNo, zone,code, error) -> Void in
            if responseState == SMSUIResponseStateSelfVerify{
                let hud = self.showActivityHud()
                ServiceContainer.getUserService().validateMobile(phoneNo, zone: zone, code: code, callback: { (suc) -> Void in
                    hud.hideAsync(false)
                    if suc{   
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    //MARK: change password
    func changePassword(_:UITapGestureRecognizer)
    {
        self.navigationController?.pushViewController(ChangePasswordViewController.instanceFromStoryBoard(), animated: true)
    }
    
    //MARK: Clear User Tmp Dir
    func clearTempDir(_:UITapGestureRecognizer)
    {
        let actions =
        [
            UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (action) -> Void in
                PersistentManager.sharedInstance.clearFileCacheFiles()
                PersistentManager.sharedInstance.resetTmpDir()
                self.showAlert("CLEAR_CACHE_SUCCESS".localizedString() , msg: "")
            }),
            UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: nil)
        ]
        showAlert("CONFIRM_CLEAR_CACHE_TITLE".localizedString() , msg: nil, actions: actions)
    }
    
    //MARK: Avatar
    var avatarImageView:UIImageView!
    func getAvatarCell() -> MyDetailAvatarCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailAvatarCell.reuseIdentifier) as! MyDetailAvatarCell
        
        let tapCell = UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.tapAvatarCell(_:)))
        cell.addGestureRecognizer(tapCell)
        ServiceContainer.getService(FileService).setAvatar(cell.avatarImageView, iconFileId: myInfo.avatar)
        let tapIcon = UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.tapAvatar(_:)))
        cell.avatarImageView?.addGestureRecognizer(tapIcon)
        cell.avatarImageView.userInteractionEnabled = true
        avatarImageView = cell.avatarImageView
        return cell
    }
    
    func tapAvatar(_:UITapGestureRecognizer)
    {
    }
    
    func tapAvatarCell(aTap:UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: "CHANGE_AVATAR".localizedString(), message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "TAKE_NEW_PHOTO".localizedString(), style: .Destructive) { _ in
            self.newPictureWithCamera()
            })
        alert.addAction(UIAlertAction(title:"SELECT_PHOTO".localizedString(), style: .Destructive) { _ in
            self.selectPictureFromAlbum()
            })
        alert.addAction(UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private var imagePickerController:UIImagePickerController! = UIImagePickerController()
    {
        didSet{
            imagePickerController.delegate = self
        }
    }
    
    private func newPictureWithCamera()
    {
        imagePickerController.sourceType = .Camera
        imagePickerController.allowsEditing = true
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    private func selectPictureFromAlbum()
    {
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    //MARK: upload avatar
    private var taskFileMap = [String:FileAccessInfo]()
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePickerController.dismissViewControllerAnimated(true)
        {
            self.avatarImageView.image = image
            let fService = ServiceContainer.getService(FileService)
            let imageData = UIImageJPEGRepresentation(image, 0.7)
            let localPath = fService.createLocalStoreFileName(FileType.Image)
            if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
            {
                fService.sendFileToAliOSS(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                    if let fk = fileKey
                    {
                        self.taskFileMap[taskId] = fk
                    }
                })
            }else
            {
                self.playToast("SET_AVATAR_FAILED".localizedString())
            }
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let fileKey = taskFileMap.removeValueForKey(taskIdentifier)
        {
            let uService = ServiceContainer.getUserService()
            uService.setMyAvatar(fileKey.fileId){ (isSuc) -> Void in
                if isSuc
                {
                    self.myInfo.avatar = fileKey.accessKey
                    self.myInfo.saveModel()
                    self.avatarImageView.image = PersistentManager.sharedInstance.getImage(fileKey.accessKey)
                    self.playCheckMark("SET_AVATAR_SUC".localizedString())
                }
            }
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        taskFileMap.removeValueForKey(taskIdentifier)
        self.playToast("SET_AVATAR_FAILED".localizedString())
    }
    
    func aboutApp(_:UITapGestureRecognizer)
    {
        AboutViewController.showAbout(self)
    }

    
    //MARK: Property Cell
    var textPropertyCells:[MyDetailCellModel] = [MyDetailCellModel]()
    
    func getTextPropertyCell(index:Int) -> MyDetailTextPropertyCell
    {
        let info = textPropertyCells[index]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier) as! MyDetailTextPropertyCell
        if info.selector != nil
        {
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: info.selector))
        }
        cell.info = info
        return cell
    }
    
    func tapTextProperty(aTap:UITapGestureRecognizer)
    {
        let cell = aTap.view as! MyDetailTextPropertyCell
        if cell.info!.editable
        {
            let propertySet = cell.info!.propertySet
            UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertySet:propertySet, controllerTitle: propertySet.propertyLabel, delegate: self)
        }
    }
    
    func editPropertySave(propertyIdentifier: String!, newValue: String!)
    {
        let userService = ServiceContainer.getUserService()
        let ppt = self.textPropertyCells.filter{$0.propertySet.propertyIdentifier == propertyIdentifier}.first!
        ppt.propertySet.propertyValue = newValue
        switch propertyIdentifier
        {
            
            case InfoIds.nickName:
                userService.changeUserNickName(newValue){ isSuc in
                    if isSuc
                    {
                        self.tableView.reloadData()
                        self.playCheckMark(String(format: "MODIFY_KEY_SUC".localizedString(), "NICK".localizedString()))
                    }else
                    {
                        self.playToast(String(format: "SET_KEY_FAILED".localizedString(), "NICK".localizedString()))
                    }
                    
                }
        default: break
        }
    }
    
    static func showUserSettingViewController(navController:UINavigationController){
        let c = instanceFromStoryBoard()
        navController.pushViewController(c, animated: true)
    }
    
    static func instanceFromStoryBoard()->UserSettingViewController{
        return instanceFromStoryBoard("User", identifier: "UserSettingViewController") as! UserSettingViewController
    }
}
