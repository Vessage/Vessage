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
    func setAvatar(imageView:UIImageView,iconFileId fileId:String!)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            imageView.image = UIImage(named: "defaultAvatar")
            if String.isNullOrWhiteSpace(fileId) == false
            {
                if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: NSBundle.mainBundle())
                {
                    imageView.image = uiimage
                }else
                {
                    self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                        if filePath != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                imageView.image = PersistentManager.sharedInstance.getImage(fileId,bundle: NSBundle.mainBundle())
                            })
                        }
                    })
                }
            }
        }
    }
}