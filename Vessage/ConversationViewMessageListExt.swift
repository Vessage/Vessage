//
//  ConversationViewMessageListEx.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/2.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation


class ConversationMessageListCellBase: UITableViewCell {
    func initCell() {}
    func presentVessage(controller:ConversationViewController,vessage:Vessage) {}
    func setContentView(controller:ConversationViewController,vessage:Vessage) {}
}

class ConversationMessageListTipsCell: ConversationMessageListCellBase {
    static let reusedId = "ConversationMessageListTipsCell"
    
    @IBOutlet weak var tipsLabel: UILabel!
    
    override func setContentView(controller: ConversationViewController, vessage: Vessage) {
        if let msg = vessage.getBodyDict()["msg"] as? String{
            tipsLabel.text = msg
            
        }else{
            tipsLabel.text = nil
        }
    }
    
    override func presentVessage(controller: ConversationViewController, vessage: Vessage) {
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }
    
}

class ConversationMessageListCell: ConversationMessageListCellBase {
    
    let bubbleView = BezierBubbleView()
    
    var avatarImageView:UIImageView?{
        return nil
    }
    
    override func initCell() {
        super.initCell()
        bubbleView.removeContentView()
    }
    
    var contentContainerView:UIView?{
        return nil
    }
    
    var isLeftCell:Bool{
        return false
    }
    
    override func setContentView(controller:ConversationViewController,vessage:Vessage) {
        
        if bubbleView.superview == nil {
            bubbleView.bubbleDirection = .Right(startYRatio: 0)
            contentContainerView?.addSubview(bubbleView)
        }
        let handler = BubbleVessageHandlerManager.getBubbleVessageHandler(vessage)
        let view = handler.getContentView(controller, vessage: vessage)
        bubbleView.setContentView(view)
        measureSize(handler, controller: controller, vessage: vessage)
    }
    
    override func presentVessage(controller:ConversationViewController,vessage:Vessage) {
        setAvatar(controller, vessage: vessage)
        refreshContent(controller, vessage: vessage)
    }
    
    func measureSize(handler:BubbleVessageHandler,controller:ConversationViewController,vessage:Vessage) -> (UIView,CGSize,CGSize) {
        let view = bubbleView.getContentView()!
        
        let container = contentContainerView!
        
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
        
        container.setNeedsUpdateConstraints()
        container.updateConstraintsIfNeeded()
        
        container.setNeedsLayout()
        container.layoutIfNeeded()
        
        var bubbleViewMaxSize = container.frame.size
        bubbleViewMaxSize.height = controller.vessageViewContainer.frame.height
        
        let maxSize = bubbleView.maxContentSizeOf(bubbleViewMaxSize)
        
        let contentSize = handler.getContentViewSize(controller, vessage: vessage, maxLimitedSize: maxSize,contentView: view)
        let bubbleViewSize = bubbleView.sizeOfContentSize(contentSize, direction: .Left(startYRatio: 0))
        let constraint = container.constraints.filter{$0.identifier == "height"}.first
        constraint?.constant = bubbleViewSize.height
        
        return (view,bubbleViewSize,contentSize)
    }
    
    private func refreshContent(controller:ConversationViewController,vessage:Vessage){
        if let container = contentContainerView{

            let handler = BubbleVessageHandlerManager.getBubbleVessageHandler(vessage)
            
            let (view,bubbleViewSize,contentSize) = measureSize(handler,controller: controller, vessage: vessage)
            
            let midPoint = avatarImageView!.frame.height / 2
            let ratio = Float(midPoint / bubbleViewSize.height)
            if isLeftCell {
                bubbleView.bubbleDirection = .Right(startYRatio: ratio)
            }else{
                bubbleView.bubbleDirection = .Left(startYRatio: ratio)
            }
            
            bubbleView.frame.size = bubbleViewSize
            view.frame = CGRect(origin: CGPointZero, size: contentSize)
            
            bubbleView.frame.origin.y = 0
            bubbleView.frame.origin.x = isLeftCell ? 0 : container.frame.size.width - bubbleViewSize.width
            
            handler.presentContent(controller,vessage: vessage, contentView: view)
            
            container.setNeedsUpdateConstraints()
            container.updateConstraintsIfNeeded()
            
            self.setNeedsLayout()
            self.layoutIfNeeded()
            
            contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        }
    }
    
    private func setAvatar(controller:ConversationViewController,vessage:Vessage){
        if let imgView = avatarImageView,let userId = vessage.getVessageRealSenderId(),let user = controller.userDict[userId]{
            ServiceContainer.getFileService().setImage(imgView, iconFileId: user.avatar,defaultImage: getDefaultAvatar(user.accountId, sex: user.sex))
        }else{
            avatarImageView?.image = getDefaultAvatar("1", sex: 0)
        }
    }
}

class ConversationMessageListLeftCell: ConversationMessageListCell {
    
    static let reusedId = "ConversationMessageListLeftCell"
    
    static let bubbleColor = UIColor.whiteColor().adjustedHueColor(0.8)
    
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var avatarImgView: UIImageView!
    
    override func initCell() {
        super.initCell()
        bubbleView.bubbleViewLayer.fillColor = ConversationMessageListLeftCell.bubbleColor.CGColor
    }
    
    override var isLeftCell: Bool{
        return true
    }
    
    override var avatarImageView: UIImageView?{
        return avatarImgView
    }
    override var contentContainerView: UIView?{
        return contentContainer
    }
}

class ConversationMessageListRightCell: ConversationMessageListCell {
    static let reusedId = "ConversationMessageListRightCell"
    
    static let bubbleColor = UIColor.blueColor().colorWithAlphaComponent(0.6)
    
    @IBOutlet weak var avatarImgView: UIImageView!
    @IBOutlet weak var contentContainer: UIView!
    
    override func initCell() {
        super.initCell()
        bubbleView.bubbleViewLayer.fillColor = ConversationMessageListRightCell.bubbleColor.CGColor
    }
    
    override var avatarImageView: UIImageView?{
        return avatarImgView
    }
    
    override var contentContainerView: UIView?{
        return contentContainer
    }
}


extension ConversationViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vessages.count
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let mc = cell as? ConversationMessageListCellBase{
            let vsg = vessages[indexPath.row]
            mc.presentVessage(self, vessage: vsg)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let vsg = vessages[indexPath.row]
        var reuseId = ""
        if vsg.typeId == Vessage.typeTips {
            reuseId = ConversationMessageListTipsCell.reusedId
        }else if vsg.isMySendingVessage(){
            reuseId = ConversationMessageListRightCell.reusedId
        }else{
            reuseId = ConversationMessageListLeftCell.reusedId
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath) as! ConversationMessageListCellBase
        cell.initCell()
        cell.setContentView(self, vessage: vsg)
        return cell
    }
}


extension ConversationViewController{
    func initMessageList() {
        vessages.removeAll()
        messageList.autoRowHeight()
        messageList.delegate = self
        messageList.dataSource = self
        
    }
    
    func messageListLoadMessages() {
        if vessages.count > 0 {
            return
        }
        if !String.isNullOrWhiteSpace(self.conversation.chatterId) {
            let vsgs = vessageService.getNotReadVessages(self.conversation.chatterId)
            if vsgs.count > 0 {
                let startVsg = generateTipsVessage(vsgs.first!.getSendTime().toLocalDateTimeSimpleString())
                self.vessages.append(startVsg)
                self.vessages.appendContentsOf(vsgs)
            }else if conversation.type == Conversation.typeSingleChat{
                let nick = ServiceContainer.getUserService().getUserNotedName(conversation.chatterId)
                let dateString = NSDate().toLocalDateTimeSimpleString()
                let msg = String(format: "CHAT_WITH_X_AT_D".localizedString(), nick,dateString)
                let startVsg = generateTipsVessage(msg)
                self.vessages.append(startVsg)
            }else if conversation.type == Conversation.typeGroupChat{
                let nick = chatGroup.groupName
                let msg = String(format: "CHAT_WITH_GROUP_X_AT_D".localizedString(), nick)
                let startVsg = generateTipsVessage(msg)
                self.vessages.append(startVsg)
            }
            messageList.reloadData()
        }
    }
    
    private func generateTipsVessage(msg:String) -> Vessage {
        let vsg = Vessage()
        var dict = [String:String]()
        dict["msg"] = msg
        vsg.typeId = Vessage.typeTips
        vsg.ts = DateHelper.UnixTimeSpanTotalMilliseconds
        let json = try! NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions(rawValue: 0))
        vsg.body = String(data: json, encoding: NSUTF8StringEncoding)
        return vsg
    }
    
    func messagesListPushReceivedMessages(received:[Vessage]) {
        var row = vessages.count - 1
        vessages.appendContentsOf(received)
        let indexPaths = received.map { (v) -> NSIndexPath in
            row += 1
            return NSIndexPath(forRow: row, inSection: 0)
        }
        messageList.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
        messageList.scrollToRowAtIndexPath(indexPaths.first!, atScrollPosition: .Middle, animated: true)
    }
    
    func removeReadedVessages() {
        dispatch_async(dispatch_get_main_queue()) {
            let vService = ServiceContainer.getVessageService()
            let fService = ServiceContainer.getFileService()
            var removedVessages = [Vessage]()
            self.vessages.forIndexEach({ (i, element) in
                if element.isRead{
                    removedVessages.append(element)
                }
            })
            for value in removedVessages{
                var removed = false
                if value.typeId == Vessage.typeFaceText{
                    continue
                }else if let fileId = value.fileId{
                    if value.typeId == Vessage.typeChatVideo{
                        removed = fService.removeFile(fileId, type: .Video)
                    }else if value.typeId == Vessage.typeImage{
                        removed = fService.removeFile(fileId, type: .Image)
                    }
                    removed ? debugLog("Vessage File Removed:%@", fileId) : debugLog("Remove Vessage File Fail:%@", fileId)
                }else{
                    debugLog("Vessage No File Id:%@", value.vessageId)
                }
            }
            vService.removeVessages(removedVessages)
        }
    }
}
