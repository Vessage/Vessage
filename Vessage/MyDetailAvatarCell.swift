//
//  MyDetailAvatarCell.swift
//  Vessage
//
//  Created by AlexChow on 16/8/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import LTMorphingLabel

//MARK: MyDetailAvatarCell
class MyDetailAvatarCell:UITableViewCell,UIEditTextPropertyViewControllerDelegate,UIImagePickerControllerDelegate,ProgressTaskDelegate,UINavigationControllerDelegate
{
    static let reuseIdentifier = "MyDetailAvatarCell"
    var rootController:UserSettingViewController!
    
    @IBOutlet weak var mottoLabel: LTMorphingLabel!{
        didSet{
            mottoLabel.morphingEffect = .pixelate
            mottoLabel.isUserInteractionEnabled = true
            mottoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyDetailAvatarCell.onTapMotto(_:))))
        }
    }
    
    @IBOutlet weak var sexImageView: UIImageView!{
        didSet{
            sexImageView.isUserInteractionEnabled = true
            sexImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyDetailAvatarCell.onTapSexImageView(_:))))
        }
    }
    @IBOutlet weak var accountIdLabel: LTMorphingLabel!{
        didSet{
            accountIdLabel.morphingEffect = .pixelate
        }
    }
    
    @IBOutlet weak var nickNameLabel: LTMorphingLabel!{
        didSet{
            nickNameLabel.morphingEffect = .pixelate
            nickNameLabel.isUserInteractionEnabled = true
            nickNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyDetailAvatarCell.onTapNick(_:))))
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layoutIfNeeded()
            avatarImageView.isUserInteractionEnabled = true
            avatarImageView.clipsToBounds = true
            avatarImageView.layer.cornerRadius = avatarImageView.frame.height / 2
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyDetailAvatarCell.tapAvatar(_:))))
        }
    }
    
    //MARK: Sex Value
    
    func onTapSexImageView(_ a:AnyObject) {
        UserSexValueViewController.showSexValueViewController(self.rootController, sexValue: self.rootController.myProfile.sex){ newValue in
            let hud = self.rootController.showAnimationHud()
            ServiceContainer.getUserService().setUserSexValue(newValue){ suc in
                hud.hide(animated: true)
                if suc{
                    self.rootController.playCheckMark("EDIT_SEX_VALUE_SUC".localizedString()){
                        ServiceContainer.getUserService().setUserSexImageView(self.sexImageView, sexValue: newValue)
                    }
                }else{
                    self.rootController.playCrossMark("EDIT_SEX_VALUE_ERROR".localizedString())
                }
            }
        }
    }
    
    //MARK: Avatar
    
    func tapAvatar(_ aTap:UITapGestureRecognizer)
    {
        let imagePicker = UIImagePickerController.showUIImagePickerAlert(self.rootController, title: "CHANGE_AVATAR".localizedString(), message: nil,allowsEditing: true)
        imagePicker.delegate = self
    }
    
    //MARK: upload avatar
    fileprivate var taskFileMap = [String:FileAccessInfo]()
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        {
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage{
                let avatarImage = image.scaleToWidthOf(UserSettingViewController.avatarWidth, quality: UserSettingViewController.avatarQuality)
                self.avatarImageView.image = avatarImage
                let fService = ServiceContainer.getFileService()
                let imageData = UIImageJPEGRepresentation(avatarImage,1)
                let localPath = PersistentManager.sharedInstance.createTmpFileName(.image)
                if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
                {
                    fService.sendFileToAliOSS(localPath, type: FileType.image, callback: { (taskId, fileKey) -> Void in
                        ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                        if let fk = fileKey
                        {
                            self.taskFileMap[taskId] = fk
                        }
                    })
                }else
                {
                    self.rootController.playToast("SET_AVATAR_FAILED".localizedString())
                }
            }
        }
    }
    
    func taskCompleted(_ taskIdentifier: String, result: Any!) {
        if let fileKey = taskFileMap.removeValue(forKey: taskIdentifier)
        {
            let uService = ServiceContainer.getUserService()
            uService.setMyAvatar(fileKey.fileId){ (isSuc) -> Void in
                if isSuc
                {
                    self.avatarImageView.image = PersistentManager.sharedInstance.getImage(fileKey.accessKey)
                    self.rootController.playCheckMark("SET_AVATAR_SUC".localizedString())
                }
            }
        }
    }
    
    func taskFailed(_ taskIdentifier: String, result: Any!) {
        taskFileMap.removeValue(forKey: taskIdentifier)
        self.rootController.playToast("SET_AVATAR_FAILED".localizedString())
    }
    
    //MARK: Motto
    func onTapMotto(_ a:AnyObject) {
        let propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "motto"
        propertySet.propertyLabel = "MOTTO".localizedString()
        propertySet.propertyValue = rootController.myProfile.motto
        propertySet.isOneLineValue = false
        propertySet.valueTextViewHolder = "VGER_MOTTO_HOLDER".localizedString()
        UIEditTextPropertyViewController.showEditPropertyViewController(self.rootController.navigationController!, propertySet:propertySet, controllerTitle: propertySet.propertyLabel, delegate: self)
    }
    
    fileprivate func modifyMotto(_ newValue: String!){
        
        ServiceContainer.getUserService().changeUserMotto(newValue){ isSuc in
            if isSuc
            {
                self.mottoLabel.text = newValue
                self.rootController.playCheckMark(String(format: "MODIFY_KEY_SUC".localizedString(), "MOTTO".localizedString()))
            }else
            {
                self.rootController.playToast(String(format: "SET_KEY_FAILED".localizedString(), "MOTTO".localizedString()))
            }
            
        }
    }
    
    //MARK: Nick
    func onTapNick(_ a:AnyObject) {
        let propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "nickname"
        propertySet.propertyLabel = "NICK".localizedString()
        propertySet.propertyValue = rootController.myProfile.nickName
        propertySet.valueTextViewHolder = "NICK_HOLDER".localizedString()
        UIEditTextPropertyViewController.showEditPropertyViewController(self.rootController.navigationController!, propertySet:propertySet, controllerTitle: propertySet.propertyLabel, delegate: self)
    }
    
    fileprivate func modifyNick(_ newValue: String!){
        ServiceContainer.getUserService().changeUserNickName(newValue){ isSuc in
            if isSuc
            {
                self.nickNameLabel.text = newValue
                self.rootController.playCheckMark(String(format: "MODIFY_KEY_SUC".localizedString(), "NICK".localizedString()))
            }else
            {
                self.rootController.playToast(String(format: "SET_KEY_FAILED".localizedString(), "NICK".localizedString()))
            }
            
        }
    }
    
    //MARK: Edit Property Delegate
    
    func editPropertySave(_ sender: UIEditTextPropertyViewController, propertyIdentifier: String!, newValue: String!, userInfo: [String : AnyObject?]?) {
        switch propertyIdentifier {
        case "motto":modifyMotto(newValue)
        case "nickname":modifyNick(newValue)
        default:
            break;
        }
    }
}

