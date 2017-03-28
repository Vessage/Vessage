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
    func presentVessage(_ controller:ConversationViewController,vessage:Vessage) {}
    func setContentView(_ controller:ConversationViewController,vessage:Vessage) {}
}

class ConversationMessageListTipsCell: ConversationMessageListCellBase {
    static let reusedId = "ConversationMessageListTipsCell"
    
    @IBOutlet weak var tipsLabel: UILabel!
    
    override func setContentView(_ controller: ConversationViewController, vessage: Vessage) {
        if let msg = vessage.getBodyDict()["msg"] as? String{
            tipsLabel.text = msg
            
        }else{
            tipsLabel.text = nil
        }
        ServiceContainer.getVessageService().readVessage(vessage)
    }
    
    override func presentVessage(_ controller: ConversationViewController, vessage: Vessage) {
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
    
    override func setContentView(_ controller:ConversationViewController,vessage:Vessage) {
        
        if bubbleView.superview == nil {
            bubbleView.bubbleDirection = .right(startYRatio: 0)
            contentContainerView?.addSubview(bubbleView)
        }
        let handler = BubbleVessageHandlerManager.getBubbleVessageHandler(vessage)
        let view = handler.getContentView(controller, vessage: vessage)
        bubbleView.setContentView(view)
        measureSize(handler, controller: controller, vessage: vessage)
    }
    
    override func presentVessage(_ controller:ConversationViewController,vessage:Vessage) {
        setAvatar(controller, vessage: vessage)
        refreshContent(controller, vessage: vessage)
    }
    
    @discardableResult
    func measureSize(_ handler:BubbleVessageHandler,controller:ConversationViewController,vessage:Vessage) -> (UIView,CGSize,CGSize) {
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
        let bubbleViewSize = bubbleView.sizeOfContentSize(contentSize, direction: .left(startYRatio: 0))
        let constraint = container.constraints.filter{$0.identifier == "height"}.first
        constraint?.constant = bubbleViewSize.height
        
        return (view,bubbleViewSize,contentSize)
    }
    
    fileprivate func refreshContent(_ controller:ConversationViewController,vessage:Vessage){
        if let container = contentContainerView{

            let handler = BubbleVessageHandlerManager.getBubbleVessageHandler(vessage)
            
            let (view,bubbleViewSize,contentSize) = measureSize(handler,controller: controller, vessage: vessage)
            
            let midPoint = avatarImageView!.frame.height / 2
            let ratio = Float(midPoint / bubbleViewSize.height)
            if isLeftCell {
                bubbleView.bubbleDirection = .right(startYRatio: ratio)
            }else{
                bubbleView.bubbleDirection = .left(startYRatio: ratio)
            }
            
            bubbleView.frame.size = bubbleViewSize
            view.frame = CGRect(origin: CGPoint.zero, size: contentSize)
            
            bubbleView.frame.origin.y = 0
            bubbleView.frame.origin.x = isLeftCell ? 0 : container.frame.size.width - bubbleViewSize.width
            
            handler.presentContent(controller,vessage: vessage, contentView: view)
            
            container.setNeedsUpdateConstraints()
            container.updateConstraintsIfNeeded()
            
            self.setNeedsLayout()
            self.layoutIfNeeded()
            
            contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        }
    }
    
    fileprivate func setAvatar(_ controller:ConversationViewController,vessage:Vessage){
        if let imgView = avatarImageView,let userId = vessage.getVessageRealSenderId(),let user = controller.userDict[userId]{
            ServiceContainer.getFileService().setImage(imgView, iconFileId: user.avatar,defaultImage: getDefaultAvatar(user.accountId, sex: user.sex))
        }else{
            avatarImageView?.image = getDefaultAvatar("1", sex: 0)
        }
    }
}

class ConversationMessageListLeftCell: ConversationMessageListCell {
    
    static let reusedId = "ConversationMessageListLeftCell"
    
    static let bubbleColor = UIColor.white.adjustedHueColor(0.8)
    
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var avatarImgView: UIImageView!
    
    override func initCell() {
        super.initCell()
        bubbleView.bubbleViewLayer.fillColor = ConversationMessageListLeftCell.bubbleColor.cgColor
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
    
    static let bubbleColor = UIColor.blue.withAlphaComponent(0.6)
    
    @IBOutlet weak var avatarImgView: UIImageView!
    @IBOutlet weak var contentContainer: UIView!
    
    override func initCell() {
        super.initCell()
        bubbleView.bubbleViewLayer.fillColor = ConversationMessageListRightCell.bubbleColor.cgColor
    }
    
    override var avatarImageView: UIImageView?{
        return avatarImgView
    }
    
    override var contentContainerView: UIView?{
        return contentContainer
    }
}


extension ConversationViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vessages.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let mc = cell as? ConversationMessageListCellBase{
            let vsg = vessages[indexPath.row]
            mc.presentVessage(self, vessage: vsg)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vsg = vessages[indexPath.row]
        var reuseId = ""
        if vsg.typeId == Vessage.typeTips {
            reuseId = ConversationMessageListTipsCell.reusedId
        }else if vsg.isMySendingVessage() || vsg.getVessageRealSenderId() == UserSetting.userId{
            reuseId = ConversationMessageListRightCell.reusedId
        }else{
            reuseId = ConversationMessageListLeftCell.reusedId
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! ConversationMessageListCellBase
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
            if conversation.type == Conversation.typeSubscription {
                self.vessages.append(generateTipsVessage("REPLY_ANY_SUBSCRIPT_ACCOUNT".localizedString()))
            }
            
            let twoDayAgo = DateHelper.UnixTimeSpanTotalMilliseconds - 24 * 3600 * 1000
            let bts = vsgs.first?.ts ?? DateHelper.UnixTimeSpanTotalMilliseconds
            let msgs = VessageTimeMachine.instance.getVessageBefore(self.conversation.chatterId, ts: bts,limit: vsgs.count > 0 ? 2 : 3).filter{$0.vessage.ts > twoDayAgo}.map({ (item) -> Vessage in
                let vsg = item.vessage!
                vsg.vessageId = Vessage.vgGenerateVessageId
                return vsg
            })
            if msgs.count > 0 {
                self.vessages.append(generateTipsVessage(msgs.first!.getSendTime().toLocalDateTimeSimpleString(),ts: msgs.first!.ts))
                self.vessages.append(contentsOf: msgs)
            }
 
            if vsgs.count > 0 {
                let startVsg = generateTipsVessage(vsgs.first!.getSendTime().toLocalDateTimeSimpleString(),ts: vsgs.first!.ts)
                self.vessages.append(startVsg)
                self.vessages.append(contentsOf: vsgs)
            }else if conversation.type == Conversation.typeSingleChat{
                
                if msgs.count == 0 {
                    let nick = ServiceContainer.getUserService().getUserNotedName(conversation.chatterId)
                    let dateString = Date().toLocalDateTimeSimpleString()
                    let msg = String(format: "CHAT_WITH_X_AT_D".localizedString(), nick,dateString)
                    let startVsg = generateTipsVessage(msg)
                    self.vessages.append(startVsg)
                }
                
            }else if conversation.type == Conversation.typeGroupChat{
                let nick = chatGroup.groupName
                let msg = String(format: "CHAT_WITH_GROUP_X_AT_D".localizedString(), nick!)
                let startVsg = generateTipsVessage(msg)
                self.vessages.append(startVsg)
            }
            
            if !String.isNullOrWhiteSpace(conversation.acId) {
                let acName = ServiceContainer.getActivityService().getActivityName(conversation.acId!)
                let msg = String(format: "FROM_X_AC_TMP_CHAT".localizedString(),acName)
                self.vessages.append(generateTipsVessage(msg))
            }
            
            messageList.reloadData()
        }
    }
    
    func generateTipsVessage(_ msg:String,ts:Int64 = DateHelper.UnixTimeSpanTotalMilliseconds) -> Vessage {
        let vsg = Vessage()
        var dict = [String:String]()
        dict["msg"] = msg
        vsg.vessageId = Vessage.vgGenerateVessageId
        vsg.typeId = Vessage.typeTips
        vsg.ts = ts
        let json = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions(rawValue: 0))
        vsg.body = String(data: json, encoding: String.Encoding.utf8)
        return vsg
    }
    
    func messagesListPushReceivedMessages(_ received:[Vessage]) {
        var row = vessages.count - 1
        vessages.append(contentsOf: received)
        let indexPaths = received.map { (v) -> IndexPath in
            row += 1
            return IndexPath(row: row, section: 0)
        }
        messageList.insertRows(at: indexPaths, with: .fade)
        messageList.scrollToRow(at: indexPaths.first!, at: .middle, animated: true)
    }
    
    func removeReadedVessages() {
        DispatchQueue.main.async {
            let vService = ServiceContainer.getVessageService()
            let fService = ServiceContainer.getFileService()
            var removedVessages = [Vessage]()
            for element in self.vessages{
                if !element.isVGGenerateVessage(){
                    removedVessages.append(element)
                }
            }
            
            for value in removedVessages{
                var removed = false
                if value.typeId == Vessage.typeFaceText || value.typeId == Vessage.typeTips{
                    continue
                }else if let fileId = value.fileId{
                    if value.typeId == Vessage.typeChatVideo{
                        removed = fService.removeFile(fileId, type: .video)
                    }else if value.typeId == Vessage.typeImage{
                        removed = fService.removeFile(fileId, type: .image)
                    }
                    removed ? debugLog("Vessage File Removed:%@", fileId) : debugLog("Remove Vessage File Fail:%@", fileId)
                }else if let vsgId = value.vessageId{
                    debugLog("Vessage No File Id:%@", vsgId)
                }
            }
            vService.removeVessages(removedVessages)
        }
    }
}
