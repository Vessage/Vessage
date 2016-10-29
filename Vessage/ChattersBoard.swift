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

class ChattersBoard: UIView {
    let minItemSpace:CGFloat = 10
    let minTopBottomPadding:CGFloat = 10
    
    var delegate:ChattersBoardDelegate?
    
    private var chatterImageViews = [UIImageView]()
    private(set) var chatters = [VessageUser]()
    
    private var chatterImageId = [String:String]()
    
    enum ItemHorizontalLayout {
        case Average,Center,MiddleAverage,Left,Right
    }
    
    var itemHorizontalLayout:ItemHorizontalLayout = .Average
    
    func getChatterImageView(chatterId:String) -> UIImageView? {
        if let index = (chatters.indexOf { $0.userId == chatterId}){
            if self.chatterImageViews.count > index {
                return chatterImageViews[index]
            }
        }
        return nil
    }
    
    func removeChatter(user:VessageUser,isDrawNow:Bool = true) -> Bool {
        let c = chatters.removeElement{$0.userId == user.userId}
        if c.count > 0 && isDrawNow {
            self.prepareImageViews()
            self.setNeedsDisplay()
        }
        return c.count > 0
    }
    
    func clearAllChatters() {
        self.chatters.removeAll()
        self.prepareImageViews()
        self.setNeedsDisplay()
    }
    
    func removeChatters(users:[VessageUser]) {
        var needDraw = false
        users.forEach{ item in
            if removeChatter(item,isDrawNow: false){
                needDraw = true
            }}
        if needDraw {
            self.prepareImageViews()
            self.setNeedsDisplay()
        }
    }
    
    func addChatters(users:[VessageUser]) {
        users.forEach{self.addChatter($0,isDrawNow: false)}
        self.prepareImageViews()
        self.setNeedsDisplay()
    }
    
    func addChatter(user:VessageUser,isDrawNow:Bool = true) {
        if !(chatters.contains{$0.userId == user.userId}) {
            chatters.append(user)
            if isDrawNow {
                self.prepareImageViews()
                self.setNeedsDisplay()
            }
        }
    }
    
    func setImageOfChatter(chatterId:String,imgId:String) {
        chatterImageId.updateValue(imgId, forKey: chatterId)
        if let index = (chatters.indexOf { $0.userId == chatterId}){
            if self.chatterImageViews.count > index {
                self.updateImage(chatterImageViews[index], imgId: imgId)
            }
        }
        
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        self.measureImageViewsSize(rect)
    }
    
    private func measureImageViewsSize(rect: CGRect){
        if chatters.count > chatterImageViews.count {
            return
        }
        let chattersCount = CGFloat(chatters.count)
        let itemWidth = (rect.width - (chattersCount + 1) * minItemSpace) / chattersCount
        let itemHeight = rect.height - minTopBottomPadding
        let itemWidthHeight = min(itemWidth, itemHeight)
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
        chatters.forIndexEach { (i, element) in
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
            if let userid = element.userId{
                if let imgid = self.chatterImageId[userid]{
                    self.updateImage(imgv, imgId: imgid)
                }else if let chatbcg = element.mainChatImage{
                    self.chatterImageId.updateValue(chatbcg, forKey: userid)
                    self.updateImage(imgv, imgId: chatbcg)
                }else if let avatar = element.avatar{
                    self.chatterImageId.updateValue(avatar, forKey: userid)
                    self.updateImage(imgv, imgId: avatar)
                }else{
                    self.updateImage(imgv, img: getDefaultAvatar(element.accountId ?? "0"))
                }
            }
            
            let indicator = (imgv.subviews.filter{$0 is UIActivityIndicatorView}).first as? UIActivityIndicatorView
            indicator?.center = CGPointMake(itemWidthHeight / 2, itemWidthHeight / 2)
        }
    }
    
    private func prepareImageViews() {
        chatterImageViews.forEach { (img) in
            img.removeFromSuperview()
        }
        chatters.forIndexEach { (i, element) in
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
                if index < self.chatters.count{
                    delegate?.chattersBoard(self, onClick: a.view as! UIImageView, chatter: self.chatters[index])
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

    func getChatterImageViewOfChatterId(chatterId:String) -> (board:ChattersBoard,chatterImageView:UIImageView)?{
        for b in chattersBoards{
            if let imgv = b.getChatterImageView(chatterId){
                return (board:b,chatterImageView:imgv)
            }
        }
        return nil
    }
}
