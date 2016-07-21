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
            if String.isNullOrEmpty(user.avatar) {
                avatarImage.image = getDefaultAvatar(user.accountId ?? "0")
            }else{
                ServiceContainer.getService(FileService).setAvatar(avatarImage, iconFileId: user.avatar)
            }
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

class UserCollectionViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout {
    
    var users = [VessageUser]()
    private var myProfile:VessageUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myProfile = ServiceContainer.getService(UserService).myProfile
        collectionView?.delegate = self
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
        if myProfile.userId == user.userId {
            self.playToast("ME".localizedString())
            return
        }
        ConversationViewController.showConversationViewController(self.navigationController!, userId: user.userId)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(82, 92)
    }
    
    static func showUserCollectionViewController(nvc:UINavigationController,users:[VessageUser]) -> UserCollectionViewController{
        let controller = instanceFromStoryBoard("User", identifier: "UserCollectionViewController") as! UserCollectionViewController
        controller.users = users
        nvc.pushViewController(controller, animated: true)
        controller.collectionView?.reloadData()
        return controller
    }
}
