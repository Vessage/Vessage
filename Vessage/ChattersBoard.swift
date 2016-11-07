//
//  ChattersBoard.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/25.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

protocol ChattersBoardDelegate {
    func chattersBoard(sender:ChattersBoard,onClick imageView:UIImageView,chatter:VessageUser)
}

class ChattersBoardItem {
    var chatterId:String!{
        return chatter.userId
    }
    
    var chatter:VessageUser!{
        didSet{
            if String.isNullOrWhiteSpace(self.itemImage) {
                if let user = chatter{
                    if let chatbcg = user.mainChatImage{
                        self.itemImage = chatbcg
                    }else if let avatar = user.avatar{
                        self.itemImage = avatar
                    }
                }
            }
        }
    }
    var itemImage:String!
}

class ChattersBoard: UIView {
    let minItemSpace:CGFloat = 10
    let minTopBottomPadding:CGFloat = 10
    
    var delegate:ChattersBoardDelegate?
    
    private var chatterImageViews = [UIImageView]()
    private(set) var chattersItems = [ChattersBoardItem]()
    
    enum ItemHorizontalLayout {
        case Average,Center,MiddleAverage,Left,Right
    }
    
    var itemHorizontalLayout:ItemHorizontalLayout = .Average
    
    func getChatterImageView(chatterId:String) -> UIImageView? {
        if let index = (chattersItems.indexOf { $0.chatterId == chatterId}){
            if self.chatterImageViews.count > index {
                return chatterImageViews[index]
            }
        }
        return nil
    }
    
    func removeChatter(user:VessageUser,isDrawNow:Bool = true) -> Bool {
        let c = chattersItems.removeElement{$0.chatterId == user.userId}
        if c.count > 0 && isDrawNow {
            drawBoard()
        }
        return c.count > 0
    }
    
    func clearAllChatters(isDrawNow:Bool = true) {
        self.chattersItems.removeAll()
        if isDrawNow{
            drawBoard()
        }
    }
    
    func removeChatters(users:[VessageUser]) {
        var needDraw = false
        users.forEach{ item in
            if removeChatter(item,isDrawNow: false){
                needDraw = true
            }}
        if needDraw {
            drawBoard()
        }
    }
    
    func addChatters(items:[ChattersBoardItem]) {
        var updated = false
        
        for item in items {
            if (chattersItems.contains{$0.chatterId == item.chatterId}) == false {
                updated = true
                chattersItems.append(item)
            }
        }
        
        if updated {
            drawBoard()
        }
    }
    
    func removeChatters(items:[ChattersBoardItem]) {
        var updated = false
        for item in items {
            let r = (chattersItems.removeElement{$0.chatterId == item.chatterId})
            if r.count > 0 {
                updated = true
            }
        }
        
        if updated {
            drawBoard()
        }
    }
    
    func addChatters(users:[VessageUser]) {
        users.forEach{self.addChatter($0,isDrawNow: false)}
        drawBoard()
    }
    
    func addChatter(user:VessageUser,isDrawNow:Bool = true) {
        if !(chattersItems.contains{$0.chatterId == user.userId}) {
            let newItem = ChattersBoardItem()
            newItem.chatter = user
            if user.userId == UserSetting.userId {
                if let imgid = ServiceContainer.getUserService().getMyChatImages(false).first?.imageId {
                    newItem.itemImage = imgid
                }
            }
            chattersItems.append(newItem)
            if isDrawNow {
                drawBoard()
            }
        }
    }
    
    func getChatter(chatterId:String) -> ChattersBoardItem? {
        for item in chattersItems {
            if item.chatterId == chatterId {
                return item
            }
        }
        return nil
    }
    
    func drawBoard() {
        self.prepareImageViews()
        self.setNeedsDisplay()
    }
    
    func updateChatter(chatter:VessageUser) -> Bool {
        if let index = (chattersItems.indexOf{$0.chatterId == chatter.userId}){
            chattersItems[index].chatter = chatter
            drawBoard()
            return true
        }
        return false
    }
    
    func setImageOfChatter(chatterId:String,imgId:String) -> Bool {
        if let index = (chattersItems.indexOf { $0.chatterId == chatterId}){
            if self.chatterImageViews.count > index {
                chattersItems[index].itemImage = imgId
                self.updateImage(chatterImageViews[index], imgId: imgId)
                return true
            }
        }
        return false
        
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        self.measureImageViewsSize(rect)
    }
    
    func chatterImageHeightOfNum(chattersNum:CGFloat,boardSize:CGSize) -> CGFloat {
        let itemWidth = (boardSize.width - (chattersNum + 1) * minItemSpace) / chattersNum
        let itemHeight = boardSize.height - minTopBottomPadding
        return min(itemWidth, itemHeight)
    }
    
    private func measureImageViewsSize(rect: CGRect){
        if chattersItems.count > chatterImageViews.count {
            return
        }
        let chattersCount = CGFloat(chattersItems.count)
        let itemWidthHeight = chatterImageHeightOfNum(chattersCount, boardSize: rect.size)
        var firstItemX:CGFloat = 0
        var itemSpace:CGFloat = 0
        switch itemHorizontalLayout {
            case .Average:
                itemSpace = (rect.width - itemWidthHeight * chattersCount) / (chattersCount + 1)
                firstItemX = itemSpace
            case .Center:
                itemSpace = minItemSpace
                firstItemX = (rect.width - itemWidthHeight * chattersCount - itemSpace * (chattersCount - 1)) / 2
            case .MiddleAverage:
                firstItemX = minItemSpace
                itemSpace = (rect.width - 2 * firstItemX - itemWidthHeight * chattersCount) / (chattersCount - 1)
            case .Left:
                firstItemX = minItemSpace
                itemSpace = minItemSpace
            case .Right:
                firstItemX = rect.width - chattersCount * (minItemSpace + itemWidthHeight)
                itemSpace = minItemSpace
        }
        let y = (rect.height - itemWidthHeight) / 2
        chattersItems.forIndexEach { (i, element) in
            let imgv = self.chatterImageViews[i]
            
            let cgi = CGFloat(i)
            imgv.contentMode = .ScaleAspectFill
            imgv.clipsToBounds = true
            imgv.frame.size.height = itemWidthHeight
            imgv.frame.size.width = itemWidthHeight
            imgv.frame.origin.y = y
            imgv.frame.origin.x = firstItemX + cgi * (itemWidthHeight + itemSpace)
            imgv.layer.cornerRadius = itemWidthHeight / 2
            imgv.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
            imgv.layer.borderWidth = 1
            if let imgid = element.itemImage{
                self.updateImage(imgv, imgId: imgid)
            }else{
                self.updateImage(imgv, img: getDefaultAvatar(element.chatter.accountId ?? "0"))
            }
            let indicator = (imgv.subviews.filter{$0 is UIActivityIndicatorView}).first as? UIActivityIndicatorView
            indicator?.center = CGPointMake(itemWidthHeight / 2, itemWidthHeight / 2)
        }
    }
    
    private func prepareImageViews() {
        chatterImageViews.forEach { (img) in
            img.removeFromSuperview()
        }
        chattersItems.forIndexEach { (i, element) in
            var imgv:UIImageView! = nil
            if self.chatterImageViews.count > i{
                imgv = self.chatterImageViews[i]
            }else{
                imgv = UIImageView()
                imgv.userInteractionEnabled = true
                imgv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChattersBoard.onTapChatterImage(_:))))
                let indicator = UIActivityIndicatorView()
                indicator.hidesWhenStopped = true
                imgv.addSubview(indicator)
                self.chatterImageViews.append(imgv)
            }
            self.addSubview(imgv)
        }
    }
    
    func onTapChatterImage(a:UITapGestureRecognizer) {
        if let img = a.view as? UIImageView{
            if let index = self.chatterImageViews.indexOf(img){
                if index < self.chattersItems.count{
                    delegate?.chattersBoard(self, onClick: a.view as! UIImageView, chatter: self.chattersItems[index].chatter)
                }
            }
        }
        
    }
    
    private func updateImage(imgv:UIImageView,imgId:String){
        let indicator = (imgv.subviews.filter{$0 is UIActivityIndicatorView}).first as? UIActivityIndicatorView
        indicator?.startAnimating()
        ServiceContainer.getFileService().getImage(iconFileId: imgId) { (image) in
            indicator?.stopAnimating()
            if let img = image{
                self.updateImage(imgv, img: img)
            }
        }
    }
    
    private func updateImage(imgv:UIImageView,img:UIImage){
        
        UIView.transitionWithView(imgv, duration: 1.2, options: .TransitionCrossDissolve, animations: {
            imgv.image = img
            }, completion: nil)
    }
}

class GroupedChattersBoardManager{
    
    var chatterItems:[ChattersBoardItem]{
        var items = [ChattersBoardItem]()
        chattersBoards.forEach { (cb) in
            items.appendContentsOf(cb.chattersItems)
        }
        return items
    }
    
    private(set) var chattersBoards = [ChattersBoard]()

    func registChattersBoards(boards:[ChattersBoard]){
        chattersBoards.appendContentsOf(boards)
    }

    func addChatter(chattersBoard:ChattersBoard,chatter:VessageUser){
        chattersBoard.addChatter(chatter)
    }

    func addChatters(chattersBoard:ChattersBoard,chatters:[VessageUser]){
        chattersBoard.addChatters(chatters)
    }
    
    func getChatterItem(userId:String) -> ChattersBoardItem? {
        for board in chattersBoards {
            if let item = board.getChatter(userId) {
                return item
            }
        }
        return nil
    }

    func getChatterImageViewOfChatterId(chatterId:String) -> (board:ChattersBoard,chatterImageView:UIImageView)?{
        for b in chattersBoards{
            if let imgv = b.getChatterImageView(chatterId){
                return (board:b,chatterImageView:imgv)
            }
        }
        return nil
    }
    
    func setChatterImageId(chatterId:String,imageId:String) -> Bool {
        if let (b,_) = getChatterImageViewOfChatterId(chatterId) {
            return b.setImageOfChatter(chatterId, imgId: imageId)
        }
        return false
    }
    
    func updateChatter(chatter:VessageUser) -> Bool {
        var updated = false
        
        for item in chattersBoards {
            if item.updateChatter(chatter){
                updated = true
            }
        }
        return updated
    }
    
    func clearChatters(isDrawNow:Bool = true) {
        for b in chattersBoards {
            b.clearAllChatters(isDrawNow)
        }
    }
}
