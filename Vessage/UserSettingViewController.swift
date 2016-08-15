//
//  UserSettingViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import MBProgressHUD

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

struct MyDetailCellModel {
    var propertySet:UIEditTextPropertySet!
    var editable:Bool = false
    var selector:Selector!
}

//MARK:UserSettingViewController
class UserSettingViewController: UIViewController,UITableViewDataSource,UITableViewDelegate //,ChatBackgroundPickerControllerDelegate
{
    static let aboutAppReuseId = "aboutApp"
    static let clearCacheCellReuseId = "clearCache"
    static let exitAccountCellReuseId = "ExitAccountCell"
    
    static let avatarWidth:CGFloat = 128
    static let avatarQuality:CGFloat = 0.8
    
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
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.lightTextColor()
        myProfile = ServiceContainer.getUserService().myProfile
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        initPropertySet()
        tableView.reloadData()
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    private(set) var myProfile:VessageUser!
    
    private func initPropertySet()
    {
        textPropertyCells.removeAll()
        var propertySet = UIEditTextPropertySet()
        
        /*
        propertySet.propertyIdentifier = InfoIds.nickName
        propertySet.propertyLabel = "NICK".localizedString()
        propertySet.propertyValue = myProfile.nickName
        textPropertyCells.append(MyDetailCellModel(propertySet: propertySet, editable: true, selector: #selector(UserSettingViewController.tapTextProperty(_:))))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "CHANGE_CHAT_BCG".localizedString()
        propertySet.propertyValue = ""
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.changeChatBcg(_:))))
        */
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "CHANGE_PSW".localizedString()
        propertySet.propertyValue = ""
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.changePassword(_:))))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "BIND_MOBILE".localizedString()
        if let mobile = myProfile.mobile{
            let length = mobile.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            let subfix = mobile.substringFromIndex(length - 4)
            propertySet.propertyValue = "***\(subfix)"
        }else{
            propertySet.propertyValue = "NOT_SET".localizedString()
        }
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.bindMobile(_:))))
        
    }
    
    func logout(sender: AnyObject)
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
    
    private func cancelLogout()
    {
        
    }
    
    private func logout()
    {
        self.navigationController?.popToRootViewControllerAnimated(true)
        ServiceContainer.instance.userLogout()
        EntryNavigationController.start()
    }
    
    //MARK: table view delegate
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 20
    }
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.dataSource = self
            tableView.delegate = self
            let uiview = UIView()
            uiview.backgroundColor = UIColor.lightTextColor()
            tableView.tableFooterView = uiview
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0
        {
            return 200
        }
        return UITableViewAutomaticDimension
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //user infos + about + clear tmp file + exit account
        return textPropertyCells.count > 0 ? 2 : 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            return 1 + textPropertyCells.count
        }else
        {
            return 3
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var resultCell:UITableViewCell!
        if indexPath.section == 0
        {
            if indexPath.row == 0
            {
                resultCell = getAvatarCell()
            }else if indexPath.row > 0 && indexPath.row <= textPropertyCells.count
            {
                resultCell = getTextPropertyCell(indexPath.row - 1)
            }else{
                resultCell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier, forIndexPath: indexPath)
            }
        }else
        {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(UserSettingViewController.clearCacheCellReuseId,forIndexPath: indexPath)
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.clearTempDir(_:))))
                resultCell = cell
            }else if indexPath.row == 1{
                let cell = tableView.dequeueReusableCellWithIdentifier(UserSettingViewController.aboutAppReuseId,forIndexPath: indexPath)
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.aboutApp(_:))))
                resultCell = cell
            }else{
                
                let cell = tableView.dequeueReusableCellWithIdentifier(UserSettingViewController.exitAccountCellReuseId,forIndexPath: indexPath)
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.logout(_:))))
                resultCell = cell
            }
        }
        resultCell.preservesSuperviewLayoutMargins = false
        resultCell.separatorInset = UIEdgeInsetsZero
        resultCell.layoutMargins = UIEdgeInsetsZero
        return resultCell
    }
    
    /*
    //MARK: change chat background
    func chatBackgroundPickerSetedImage(sender: ChatBackgroundPickerController) {
        sender.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func chatBackgroundPickerSetImageCancel(sender: ChatBackgroundPickerController) {
        
    }
    
    func changeChatBcg(_:UITapGestureRecognizer)
    {
        ChatImageMgrViewController.showChatImageMgrVeiwController(self)
    }
 */
    
    //MARK: bind mobile
    func bindMobile(_:UITapGestureRecognizer)
    {
        #if RELEASE
            SMSSDKUI.showVerificationCodeViewWithMetohd(SMSGetCodeMethodSMS) { (responseState, phoneNo, zone,code, error) -> Void in
                if responseState == SMSUIResponseStateSelfVerify{
                    self.validateMobile(phoneNo, zone: zone, code: code)
                }
            }
        #else
            let title = "输入手机号"
            let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
            alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
                textfield.placeholder = "手机号"
                textfield.borderStyle = .None
            })
            
            let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
                let phoneNo = alertController.textFields?[0].text ?? ""
                if String.isNullOrEmpty(phoneNo)
                {
                    self.playToast("手机号不能为空")
                }else{
                    self.validateMobile(phoneNo, zone: "86", code: "1234")
                }
            })
            let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
            alertController.addAction(no)
            alertController.addAction(yes)
            self.showAlert(alertController)
        #endif
        
    }
    
    private func validateMobile(phoneNo:String,zone:String,code:String){
        let hud = self.showAnimationHud()
        ServiceContainer.getUserService().validateMobile(VessageConfig.bahamutConfig.smsSDKAppkey,mobile: phoneNo, zone: zone, code: code, callback: { (suc,newUserId) -> Void in
            hud.hideAsync(false)
            if let newId = newUserId{
                ServiceContainer.getAccountService().reBindUserId(newId)
                EntryNavigationController.start()
            }else if suc{
                self.tableView.reloadData()
            }
        })
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
    func getAvatarCell() -> MyDetailAvatarCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailAvatarCell.reuseIdentifier) as! MyDetailAvatarCell
        ServiceContainer.getService(FileService).setAvatar(cell.avatarImageView, iconFileId: myProfile.avatar)
        ServiceContainer.getUserService().setUserSexImageView(cell.sexImageView, sexValue: myProfile.sex)
        cell.nickNameLabel.text = myProfile.nickName
        cell.accountIdLabel.text = String(format: "USER_ACCOUNT_FORMAT".localizedString(), myProfile.accountId)
        cell.rootController = self
        return cell
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
    
    /*
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
 */
    
    static func showUserSettingViewController(navController:UINavigationController){
        navController.pushViewController(instanceFromStoryBoard(), animated: true)
    }
    
    static func instanceFromStoryBoard()->UserSettingViewController{
        return instanceFromStoryBoard("User", identifier: "UserSettingViewController") as! UserSettingViewController
    }
}
