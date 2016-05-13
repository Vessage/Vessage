//
//  UserCollectionViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class UserCollectionViewCell: UICollectionViewCell {
    static let reuseId = "UserCollectionViewCell"
    
    var user:VessageUser!{
        didSet{
            nickLabel.text = user.nickName
            ServiceContainer.getService(FileService).setAvatar(avatarImage, iconFileId: user.avatar)
        }
    }
    
    @IBOutlet weak var avatarImage: UIImageView!{
        didSet{
            avatarImage.clipsToBounds = true
            avatarImage.layer.cornerRadius = 3
        }
    }
    @IBOutlet weak var nickLabel: UILabel!
    
}

class UserCollectionViewController: UICollectionViewController {
    
    var users = [VessageUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.reloadData()
        collectionView?.allowsSelection = true
        collectionView?.allowsMultipleSelection = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ServiceContainer.getUserService().addObserver(self, selector: #selector(UserCollectionViewController.onUserProfileUpdated(_:)), name: UserService.userProfileUpdated, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getUserService().removeObserver(self)
    }
    
    func onUserProfileUpdated(a:NSNotification){
        if let user = a.userInfo?[UserProfileUpdatedUserValue] as? VessageUser{
            users.forIndexEach({ (i, element) in
                if element.userId == user.userId{
                    self.users[i] = user
                    self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)])
                    return
                }
            })
        }
    }
    
    //MARK: CollectionView Delegate
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(UserCollectionViewCell.reuseId, forIndexPath: indexPath) as! UserCollectionViewCell
        cell.user = users[indexPath.row]
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let user = users[indexPath.row]
        let conversation = ServiceContainer.getConversationService().openConversationByUserId(user.userId,noteName: user.nickName ?? user.accountId ?? "")
        ConversationViewController.showConversationViewController(self.navigationController!, conversation: conversation)
    }
    
    static func showUserCollectionViewController(nvc:UINavigationController,users:[VessageUser]) -> UserCollectionViewController{
        let controller = instanceFromStoryBoard("User", identifier: "UserCollectionViewController") as! UserCollectionViewController
        controller.users = users
        nvc.pushViewController(controller, animated: true)
        controller.collectionView?.reloadData()
        return controller
    }
}