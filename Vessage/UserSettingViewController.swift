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
    func showMyDetailView(_ currentViewController:UIViewController)
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
                editableMark.isHidden = !info!.editable
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
                editableMark.isHidden = !i.editable
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
class UserSettingViewController: UIViewController,UITableViewDataSource,UITableViewDelegate
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
    
    var basicMode = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.lightText
        myProfile = ServiceContainer.getUserService().myProfile
        self.tableView.alpha = 0.1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initPropertySet()
        tableView.reloadData()
        UIView.animate(withDuration: 0.3, animations: { 
            self.tableView.alpha = 1
        }) 
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    fileprivate(set) var myProfile:VessageUser!
    
    fileprivate func initPropertySet()
    {
        textPropertyCells.removeAll()
        var propertySet = UIEditTextPropertySet()
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "CHANGE_PSW".localizedString()
        propertySet.propertyValue = ""
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.changePassword(_:))))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = "BIND_MOBILE".localizedString()
        if ServiceContainer.getUserService().isTempMobileUser {
            propertySet.propertyValue = "NOT_SET".localizedString()
        }else if let mobile = myProfile.mobile{
            let length = mobile.lengthOfBytes(using: String.Encoding.utf8)
            let subfix = mobile.substringFromIndex(length - 4)
            propertySet.propertyValue = "***\(subfix)"
        }else{
            propertySet.propertyValue = "NOT_SET".localizedString()
        }
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: #selector(UserSettingViewController.bindMobile(_:))))
        
    }
    
    func logout(_ sender: AnyObject)
    {
        let alert = UIAlertController(title: "LOGOUT_CONFIRM_TITLE".localizedString(),
            message: "USER_DATA_WILL_SAVED".localizedString(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES".localizedString(), style: .default) { _ in
            self.logout()
            })
        alert.addAction(UIAlertAction(title: "NO".localizedString(), style: .cancel) { _ in
            self.cancelLogout()
            })
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func cancelLogout()
    {
        
    }
    
    fileprivate func logout()
    {
        let _ = self.navigationController?.popToRootViewController(animated: true)
        ServiceContainer.instance.userLogout()
        EntryNavigationController.start()
    }
    
    //MARK: table view delegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
            uiview.backgroundColor = UIColor.lightText
            tableView.tableFooterView = uiview
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0
        {
            return 200
        }
        return UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if basicMode {
            return textPropertyCells.count > 0 ? 1 : 0
        }
        return textPropertyCells.count > 0 ? 2 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //user infos + about + clear tmp file + exit account
        if section == 0
        {
            return 1 + textPropertyCells.count
        }else
        {
            return 3
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
                resultCell = tableView.dequeueReusableCell(withIdentifier: MyDetailTextPropertyCell.reuseIdentifier, for: indexPath)
            }
        }else
        {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: UserSettingViewController.clearCacheCellReuseId,for: indexPath)
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.clearTempDir(_:))))
                resultCell = cell
            }else if indexPath.row == 1{
                let cell = tableView.dequeueReusableCell(withIdentifier: UserSettingViewController.aboutAppReuseId,for: indexPath)
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.aboutApp(_:))))
                resultCell = cell
            }else{
                
                let cell = tableView.dequeueReusableCell(withIdentifier: UserSettingViewController.exitAccountCellReuseId,for: indexPath)
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserSettingViewController.logout(_:))))
                resultCell = cell
            }
        }
        resultCell.setSeparatorFullWidth()
        return resultCell
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
            UIAlertAction(title: "YES".localizedString(), style: .default, handler: { (action) -> Void in
                PersistentManager.sharedInstance.clearFileCacheFiles()
                PersistentManager.sharedInstance.resetTmpDir()
                self.showAlert("CLEAR_CACHE_SUCCESS".localizedString() , msg: "")
            }),
            UIAlertAction(title: "CANCEL".localizedString(), style: .cancel, handler: nil)
        ]
        showAlert("CONFIRM_CLEAR_CACHE_TITLE".localizedString() , msg: nil, actions: actions)
    }
    
    //MARK: Avatar
    func getAvatarCell() -> MyDetailAvatarCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyDetailAvatarCell.reuseIdentifier) as! MyDetailAvatarCell
        
        let defaultAvatar = getDefaultAvatar(myProfile.accountId, sex: myProfile.sex)
        ServiceContainer.getFileService().setImage(cell.avatarImageView, iconFileId: myProfile.avatar,defaultImage: defaultAvatar)
        ServiceContainer.getUserService().setUserSexImageView(cell.sexImageView, sexValue: myProfile.sex)
        cell.mottoLabel.text = myProfile.motto ?? "DEFAULT_SELF_MOTTO".localizedString()
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
    
    func getTextPropertyCell(_ index:Int) -> MyDetailTextPropertyCell
    {
        let info = textPropertyCells[index]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: MyDetailTextPropertyCell.reuseIdentifier) as! MyDetailTextPropertyCell
        if info.selector != nil
        {
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: info.selector))
        }
        cell.info = info
        return cell
    }
    
    static func showUserSettingViewController(_ navController:UINavigationController,basicMode:Bool = true){
        let controller = instanceFromStoryBoard()
        controller.basicMode = basicMode
        navController.pushViewController(controller, animated: true)
    }
    
    static func instanceFromStoryBoard()->UserSettingViewController{
        return instanceFromStoryBoard("User", identifier: "UserSettingViewController") as! UserSettingViewController
    }
}

extension UserSettingViewController:ValidateMobileViewControllerDelegate{
    //MARK: bind mobile
    func bindMobile(_:UITapGestureRecognizer)
    {
        let controller = ValidateMobileViewController.showValidateMobileViewController(self,delegate: self)
        controller.exitButton?.setTitle("CANCEL".localizedString(), for: UIControlState())
    }
    
    func validateMobileCancel(_ sender: ValidateMobileViewController) {
        sender.dismiss(animated: true, completion: nil)
    }
    
    func validateMobileIsTryBindExistsUser(_ sender: ValidateMobileViewController) -> Bool {
        return false
    }
    
    func validateMobile(_ sender: ValidateMobileViewController, suc: Bool) {
        self.tableView.reloadData()
    }
}
