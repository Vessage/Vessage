//
//  ChatImageBoardController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class ChatImageBoardCell: UICollectionViewCell {
    static let reuseId = "ChatImageBoardCell"
    @IBOutlet weak var checkedImage: UIImageView!
    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var imageTypeLabel: UILabel!
    override var selected: Bool{
        didSet{
            checkedImage.hidden = !selected
        }
    }
}

@objc protocol ChatImageBoardControllerDelegate {
    optional func chatImageBoardController(sender:ChatImageBoardController,selectedIndexPath:NSIndexPath,selectedItem:ChatImage,deselectItem:ChatImage?)
    optional func chatImageBoardController(dissmissController sender:ChatImageBoardController)
    optional func chatImageBoardController(appearController sender:ChatImageBoardController)
}

class ChatImageBoardController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    weak var delegate : ChatImageBoardControllerDelegate?
    private var chatImages = [ChatImage]()
    var fileService = ServiceContainer.getFileService()
    private(set) var selectedChatImage:ChatImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = false
        
    }
    
    private func reloadChatImages(){
        chatImages.removeAll()
        var cimages = ServiceContainer.getUserService().myChatImages.messArrayUp()
        defaultImageTypes.forEach({ (dict) in
            if let t = dict["type"]{
                if let index = (cimages.indexOf{$0.imageType == t}){
                    self.chatImages.append(cimages.removeAtIndex(index))
                }
            }
        })
        chatImages.appendContentsOf(cimages)
        self.collectionView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadChatImages()
        if chatImages.count > 0 {
            self.selectedChatImage = chatImages.first
            self.collectionView.selectItemAtIndexPath(NSIndexPath(forRow: 0,inSection: 0), animated: true, scrollPosition: .Left)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.chatImageBoardController?(dissmissController: self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate?.chatImageBoardController?(appearController: self)
    }

    func myChatImagesUpdated(a:NSNotification) {
        self.reloadChatImages()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return chatImages.count > 0 ? 1 : 0
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return chatImages.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ChatImageBoardCell.reuseId, forIndexPath: indexPath) as! ChatImageBoardCell
    
        // Configure the cell
        let chatImage = self.chatImages[indexPath.row]
        cell.imageTypeLabel.text = chatImage.imageType
        cell.checkedImage.hidden = !cell.selected
        fileService.setAvatar(cell.chatImageView, iconFileId: chatImage.imageId,defaultImage: getDefaultFace())
        #if DEBUG
            print("ChatImage:\(chatImage.imageId)")
        #endif
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let deselectItem = self.selectedChatImage
        self.selectedChatImage = chatImages[indexPath.row]
        self.delegate?.chatImageBoardController?(self, selectedIndexPath: indexPath,selectedItem: chatImages[indexPath.row],deselectItem: deselectItem)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(72, 100)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 3
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}

extension ChatImageBoardController{
    static func instanceFromStoryBoard()->ChatImageBoardController{
        return instanceFromStoryBoard("ChatImageBoardController", identifier: "ChatImageBoardController") as! ChatImageBoardController
    }
}
