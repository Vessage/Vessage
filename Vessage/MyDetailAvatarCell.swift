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
    
    @IBOutlet weak var sexImageView: UIImageView!{
        didSet{
            sexImageView.userInteractionEnabled = true
            sexImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyDetailAvatarCell.onTapSexImageView(_:))))
        }
    }
    @IBOutlet weak var accountIdLabel: LTMorphingLabel!{
        didSet{
            accountIdLabel.morphingEffect = .Pixelate
        }
    }
    
    @IBOutlet weak var nickNameLabel: LTMorphingLabel!{
        didSet{
            nickNameLabel.morphingEffect = .Pixelate
            nickNameLabel.userInteractionEnabled = true
            nickNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyDetailAvatarCell.onTapNick(_:))))
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.userInteractionEnabled = true
            avatarImageView.clipsToBounds = true
            avatarImageView.layer.cornerRadius = avatarImageView.frame.height / 2
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyDetailAvatarCell.tapAvatar(_:))))
        }
    }
    
    //MARK: Sex Value
    
    func onTapSexImageView(a:AnyObject) {
        UserSexValueViewController.showUserProfileViewController(self.rootController, sexValue: self.rootController.myProfile.sex){ newValue in
            let hud = self.rootController.showAnimationHud()
            ServiceContainer.getUserService().setUserSexValue(newValue){ suc in
                hud.hideAnimated(true)
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
    
    func tapAvatar(aTap:UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: "CHANGE_AVATAR".localizedString(), message: nil, preferredStyle: .ActionSheet)
        let camera = UIAlertAction(title: "TAKE_NEW_PHOTO".localizedString(), style: .Default) { _ in
            self.newPictureWithCamera()
        }
        camera.setValue(UIImage(named: "avartar_camera")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        alert.addAction(camera)
        let album = UIAlertAction(title:"SELECT_PHOTO".localizedString(), style: .Default) { _ in
            self.selectPictureFromAlbum()
        }
        album.setValue(UIImage(named: "avartar_select")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        alert.addAction(album)
        alert.addAction(UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel){ _ in})
        self.rootController.showAlert(alert)
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
        self.rootController.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    private func selectPictureFromAlbum()
    {
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.rootController.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    //MARK: upload avatar
    private var taskFileMap = [String:FileAccessInfo]()
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePickerController.dismissViewControllerAnimated(true)
        {
            let avatarImage = image.scaleToWidthOf(UserSettingViewController.avatarWidth, quality: UserSettingViewController.avatarQuality)
            self.avatarImageView.image = avatarImage
            let fService = ServiceContainer.getService(FileService)
            let imageData = UIImageJPEGRepresentation(avatarImage,1)
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
                self.rootController.playToast("SET_AVATAR_FAILED".localizedString())
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
                    self.rootController.myProfile.avatar = fileKey.accessKey
                    self.rootController.myProfile.saveModel()
                    self.avatarImageView.image = PersistentManager.sharedInstance.getImage(fileKey.accessKey)
                    self.rootController.playCheckMark("SET_AVATAR_SUC".localizedString())
                }
            }
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        taskFileMap.removeValueForKey(taskIdentifier)
        self.rootController.playToast("SET_AVATAR_FAILED".localizedString())
    }
    
    
    //MARK: Nick
    
    func onTapNick(a:AnyObject) {
        let propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "nickname"
        propertySet.propertyLabel = "NICK".localizedString()
        propertySet.propertyValue = rootController.myProfile.nickName
        UIEditTextPropertyViewController.showEditPropertyViewController(self.rootController.navigationController!, propertySet:propertySet, controllerTitle: propertySet.propertyLabel, delegate: self)
    }
    
    func editPropertySave(propertyIdentifier: String!, newValue: String!)
    {
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
}

