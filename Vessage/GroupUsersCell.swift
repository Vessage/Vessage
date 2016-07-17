//
//  GroupUsersCell.swift
//  Vessage
//
//  Created by AlexChow on 16/7/16.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class GroupUserCollectionCell: UICollectionViewCell {
    static let reuseId = "GroupUserCollectionCell"
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var nick: UILabel!
}
//
//class GroupUsersCell: ChatGroupProfileCellBase,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
//    static let reuseId = "GroupUsersCell"
//    
//    @IBOutlet weak var collectionHeightConstraints: NSLayoutConstraint!
//    
//    @IBOutlet weak var collectionView: UICollectionView!{
//        didSet{
//            collectionView.delegate = self
//            collectionView.dataSource = self
//        }
//    }
//    
//    
//}
