//
//  AppUtil.swift
//  Vessage
//
//  Created by AlexChow on 16/3/3.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

extension String
{
    func localizedString() -> String{
        return NSLocalizedString(self, tableName: "Localizable", bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}

//MARK: Set avatar Util
extension FileService
{
    func setAvatar(imageView:UIImageView,iconFileId fileId:String!, defaultImage:UIImage = UIImage(named: "defaultAvatar")!,callback:((suc:Bool)->Void)! = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            imageView.image = defaultImage
            if String.isNullOrWhiteSpace(fileId) == false
            {
                if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: NSBundle.mainBundle())
                {
                    imageView.image = uiimage
                    if let handler = callback{
                        handler(suc:true)
                    }
                }else
                {
                    self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                        if filePath != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                imageView.image = PersistentManager.sharedInstance.getImage(fileId,bundle: NSBundle.mainBundle())
                                if let handler = callback{
                                    handler(suc:true)
                                }
                            })
                        }else{
                            if let handler = callback{
                                handler(suc:false)
                            }
                        }
                    })
                }
            }else{
                if let handler = callback{
                    handler(suc:false)
                }
            }
        }
    }
    
    func setAvatar(button:UIButton,iconFileId fileId:String!)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let image = UIImage(named: "defaultAvatar")
            button.setImage(image, forState: .Normal)
            if String.isNullOrWhiteSpace(fileId) == false
            {
                if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: NSBundle.mainBundle())
                {
                    button.setImage(uiimage, forState: .Normal)
                }else
                {
                    self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                        if filePath != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                let img = PersistentManager.sharedInstance.getImage(fileId,bundle: NSBundle.mainBundle())
                                button.setImage(img, forState: .Normal)
                            })
                        }
                    })
                }
            }
        }
    }
}

extension String{
    func isBahamutAccount() -> Bool{
        
        if self =~ "^\\d{6,9}$"{
            if let aId = Int(self){
                return aId >= 147258
            }
        }
        return false
    }
}

//MARK: NSNotificationCenter Extension
extension NSNotificationCenter{
    func postNotificationNameWithMainAsync(aName: String, object: AnyObject?, userInfo: [NSObject : AnyObject]?){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.postNotificationName(aName, object: object, userInfo: userInfo)
        }
    }
}