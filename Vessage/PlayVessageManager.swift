//
//  PlayVessageManager.swift
//  Vessage
//
//  Created by AlexChow on 16/5/31.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

private let randomTextVessageContents = [
    ["?_?","??????","有事想和我聊聊？","...什么事？","......","☺️"],
    ["。。。","！！！！"]
]

//MARK: PlayVessageManager
class PlayVessageManager: ConversationViewControllerProxy {
    
    let chatterVessageBubbleColor = UIColor.whiteColor().adjustedHueColor(0.6)
    let myVessageBubbleColor = UIColor.blueColor().colorWithAlphaComponent(0.6)
    
    
    //MAKR: chatters baord
    private var chattersBoardManager:GroupedChattersBoardManager!

    //MARK: bubble view
    private var vessageBubbleView:BezierBubbleView!
    private var vessageBubbleHandler:BubbleVessageHandler!
    
    //MAKR: chat image board
    
    //var chatImageBoardSourceView:UIView!
    private var chatImageBoardController:ChatImageBoardController!
    private var chatImageBoardSourceView:UIView!
    
    var selectedImageId:String?{
        if chatImageBoardController == nil {
            return self.rootController.userService.getMyChatImages(false).first?.imageId
        }else{
            return chatImageBoardController.selectedChatImage?.imageId
        }
    }


    //MARK: flash tips properties
    private var flashTipsView:UILabel!
    
    //MARK: Vessages Properties
    private var vessages = [Vessage](){
        didSet{
            self.refreshNotReadVessageNumber()
        }
    }
    
    var haveNextVessage:Bool{
        return vessages.count > currentVessageIndex
    }
    
    var havePreviousVessage:Bool{
        return vessages.count > 0 && currentVessageIndex > 0
    }
    
    var currentVessageIndex = 0{
        didSet{
            if let vsg = currentIndexVessage {
                self.showBubbleVessage(nil, vessage: vsg, nextVessage: nil)
            }
            refreshReadingProgress()
        }
    }
    
    var currentIndexVessage:Vessage?{
        return vessages.count > currentVessageIndex ? vessages[currentVessageIndex] : nil
    }
    
    private var removedVessages = [String:Vessage]()
    
    //MARK: vessages actions
    func onNewVessagePushed(a:NSNotification) {
        if let task = a.userInfo?[kBahamutQueueTaskValue] as? SendVessageQueueTask{
            if task.receiverId == self.conversation.chatterId {
                if let vsg = task.vessage {
                    let newVsg = vsg.copyToObject(Vessage.self)
                    if newVsg.isGroup {
                        newVsg.gSender = newVsg.sender
                    }
                    if vsg.isMySendingVessage() {
                        newVsg.fileId = task.filePath
                    }
                    if self.vessages.count > 0 {
                        self.vessages.insert(newVsg, atIndex: currentVessageIndex + 1)
                        self.loadNextVessage()
                    }else{
                        self.vessages.append(newVsg)
                        self.currentVessageIndex = 0
                    }
                }
            }
            
        }
    }
    
    override func onVessagesReceived(vessages: [Vessage]) {
        var showingMySendedVsg = false
        if let cvsg = currentIndexVessage {
            if cvsg.isGroup {
                showingMySendedVsg = cvsg.gSender == UserSetting.userId
            }else{
                showingMySendedVsg = cvsg.isMySendingVessage()
            }
        }
        self.vessages.appendContentsOf(vessages)
        if showingMySendedVsg {
            loadNextVessage()
        }
    }
    
    func loadVessages() {
        if vessages.count > 0 {
            return
        }
        if !String.isNullOrWhiteSpace(self.conversation.chatterId) {
            var vessages = vessageService.getNotReadVessages(self.conversation.chatterId)
            if vessages.count == 0 {
                if let v = vessageService.getCachedNewestVessage(self.conversation.chatterId){
                    vessages.append(v)
                }else{
                    vessages.append(getVGRandomVessage())
                }
            }
            vessages.sortInPlace({ (a, b) -> Bool in
                a.sendTime.dateTimeOfAccurateString.isBefore(b.sendTime.dateTimeOfAccurateString)
            })
            self.vessages = vessages
            self.currentVessageIndex = 0
        }
    }
    
    func getVGRandomVessage() -> Vessage {
        let v = Vessage()
        v.vessageId = Vessage.vgRandomVessageId
        v.typeId = Vessage.typeFaceText
        v.isGroup = self.conversation.isGroup
        v.sender = self.conversation.chatterId
        if self.conversation.isGroup {
            let chatters = self.chattersBoardManager.chatterItems.filter{$0.chatterId != UserSetting.userId}
            if chatters.count > 0 {
                v.gSender = chatters[random() % chatters.count].chatterId
            }
        }
        v.sendTime = NSDate().toAccurateDateTimeString()
        v.isRead = true
        let randomContents = self.conversation.isGroup ? randomTextVessageContents[1] : randomTextVessageContents[0]
        let textMessage = randomContents[random() % randomContents.count]
        v.body = self.rootController.getSendVessageBodyString(["textMessage":textMessage],withBaseDict: false)
        return v
    }
    
    //MARK: keyboard
    var cachedBottomChatterBoardHeight:CGFloat!
    var cachedBottomChatterBoardBottom:CGFloat!
    var cachedTopChatterBoardHeigt:CGFloat!
    
    var cachedTopChatters = [ChattersBoardItem]()
    var chatterMoved = false
    
    
    override func onKeyBoardShown() {
        self.rootController.navigationController?.setNavigationBarHidden(true, animated: true)
        let bottomChattersBoard = self.rootController.bottomChattersBoard
        let topChattersBoard = self.rootController.topChattersBoard
        if cachedBottomChatterBoardHeight == nil {
            cachedBottomChatterBoardHeight = self.rootController.bottomChattersBoardHeight.constant
            cachedBottomChatterBoardBottom = self.rootController.bottomChattersBoardBottom.constant
            cachedTopChatterBoardHeigt = self.rootController.topChattersBoardHeight.constant
        }
        
        if chatterMoved == false {
            cachedTopChatters.removeAll()
            cachedTopChatters.appendContentsOf(topChattersBoard.chattersItems)
            topChattersBoard.clearAllChatters()
            bottomChattersBoard.addChatters(cachedTopChatters)
            chatterMoved = true
            dispatch_after(500, queue: dispatch_get_main_queue()) {
                self.rootController.bottomChattersBoard.layoutIfNeeded()
                if let vsg = self.currentIndexVessage{
                    self.showBubbleVessage(nil, vessage: vsg, nextVessage: nil)
                }
            }
        }
        
        let rect = self.rootController.view.convertRect(self.rootController.imageChatInputView.sendButton.frame, fromView: self.rootController.imageChatInputView)
        let chatterNum = CGFloat(bottomChattersBoard.chattersItems.count)
        let newHeight = bottomChattersBoard.chatterImageHeightOfNum(chatterNum, boardSize: bottomChattersBoard.frame.size) + 10
        self.rootController.topChattersBoardHeight.constant = 0
        self.rootController.bottomChattersBoardHeight.constant = newHeight
        self.rootController.bottomChattersBoardBottom.constant = self.rootController.view.frame.height - rect.origin.y + 10
    }
    
    override func onKeyBoardHidden() {
        self.rootController.navigationController?.setNavigationBarHidden(false, animated: true)
        self.rootController.bottomChattersBoardHeight.constant = cachedBottomChatterBoardHeight
        self.rootController.bottomChattersBoardBottom.constant = cachedBottomChatterBoardBottom
        self.rootController.topChattersBoardHeight.constant = cachedTopChatterBoardHeigt
        self.rootController.bottomChattersBoard.removeChatters(cachedTopChatters)
        self.rootController.topChattersBoard.addChatters(cachedTopChatters)
        cachedTopChatters.removeAll()
        hideBubbleVessage()
        dispatch_after(500, queue: dispatch_get_main_queue()) { 
            self.rootController.bottomChattersBoard.layoutIfNeeded()
            if let vsg = self.currentIndexVessage{
                self.showBubbleVessage(nil, vessage: vsg, nextVessage: nil)
            }
        }
        chatterMoved = false
    }
    
    //MARK: Notifications
    func onVessageReaded(a:NSNotification) {
        if let vsg = a.userInfo?[VessageServiceNotificationValue] as? Vessage {
            if let cvsg = self.currentIndexVessage{
                if vsg.vessageId == cvsg.vessageId{
                    if let cmd = self.currentIndexVessage?.getBodyDict()["readedEventCmd"] as? String{
                        BahamutCmdManager.sharedInstance.handleBahamutEncodedCmdWithMainQueue(cmd)
                    }
                    self.refreshNotReadVessageNumber()
                }
            }
        }
    }
    
    //MARK: actions
    func onClickChatVideoButton(sender: UITapGestureRecognizer) {
        
        self.rootController.view.userInteractionEnabled = false
        self.rootController.sendVideoChatButton.animationMaxToMin(0.1, maxScale: 1.2) {
            if self.rootController.outChatGroup {
                self.rootController.playToast("NOT_IN_CHAT_GROUP".localizedString())
            }else if self.rootController.isReadingVessages {
                if self.rootController.needSetChatBackgroundAndShow() {
                    self.rootController.view.userInteractionEnabled = true
                    return
                }
                self.rootController.startRecording()
            }
            self.rootController.view.userInteractionEnabled = true
        }
    }
    
    func onClickFaceTextButton(sender: UITapGestureRecognizer) {
        self.rootController?.sendFaceTextButton.animationMaxToMin(0.1, maxScale: 1.2) {
            self.rootController.tryShowImageChatInputView()
        }
    }
    
    func onClickImageButton(sender: UITapGestureRecognizer) {
        self.rootController.view.userInteractionEnabled = false
        self.rootController.sendImageButton.animationMaxToMin(0.1, maxScale: 1.2) {
            if self.rootController.outChatGroup {
                self.rootController.playToast("NOT_IN_CHAT_GROUP".localizedString())
            }else if self.rootController.isReadingVessages {
                self.rootController.showSendImageAlert()
            }
            self.rootController.view.userInteractionEnabled = true
        }
    }
    
    func onClickMgrChatImageButton(sender: UITapGestureRecognizer) {
        self.rootController?.mgrChatImagesButton.animationMaxToMin(0.1, maxScale: 1.2, completion: { 
            self.rootController?.showChatImagesMrgController(0)
        })
    }
    
    func refreshNotReadVessageNumber(){
        let num = vessages.filter{!$0.isRead}.count
        if let l = self.rootController?.notReadNumLabel{
            setBadgeLabelValue(l, value: num,autoHide: false)
        }
        self.refreshReadingProgress()
    }
    
    func refreshReadingProgress() {
        let progress = Float(currentVessageIndex + 1) / Float(vessages.count)
        
        if vessages.count > 0 {
            let angle = 360 * Double(progress)
            rootController?.readingProgress.animateToAngle(angle, duration: 0.2, completion: nil)
        }else{
            rootController?.readingProgress.animateToAngle(360, duration: 0.2, completion: nil)
        }
        self.rootController.readingLineProgress.setProgress(progress, animated: true)
        self.rootController.readingLineProgress.hidden = progress >= 1
    }
    
    func showPreviousVessage() {
        if !havePreviousVessage {
            self.flashTips("NO_PREVIOUS_VESSAGE".localizedString())
            return
        }
        if currentVessageIndex > 0 {
            currentVessageIndex -= 1
        }
    }
    
    func showNextVessage() {
        if vessages.count == 0 {
            self.flashTips("NO_NOT_READ_VESSAGE".localizedString())
        }else if vessages.count - 1 <= currentVessageIndex{
            self.flashTips("THE_LAST_NOT_READ_VESSAGE".localizedString())
        }else if currentIndexVessage!.isRead{
            loadNextVessage()
        }else{
            let continueAction = UIAlertAction(title: "CONTINUE".localizedString(), style: .Default, handler: { (action) -> Void in
                MobClick.event("Vege_JumpVessage")
                self.vessageService.readVessage(self.currentIndexVessage!)
                self.loadNextVessage()
            })
            rootController.showAlert("CLICK_NEXT_MESSAGE_TIPS_TITLE".localizedString(), msg: "CLICK_NEXT_MESSAGE_TIPS".localizedString(), actions: [ALERT_ACTION_I_SEE,continueAction])
        }
    }
    
    private func loadNextVessage(){
        if let cv = currentIndexVessage {
            if cv.isReceivedVessage() {
                removedVessages.updateValue(cv, forKey: cv.vessageId)
            }
            currentVessageIndex += 1
        }else{
            self.flashTips("NO_NOT_READ_VESSAGE".localizedString())
        }
    }
    
    func removeReadedVessages() {
        dispatch_async(dispatch_get_main_queue()) {
            let vService = ServiceContainer.getVessageService()
            let fService = ServiceContainer.getFileService()
            
            self.removedVessages.forEach { (key,value) in
                vService.removeVessage(value)
                if value.typeId == Vessage.typeFaceText{
                    return
                }
                var removed = false
                if value.typeId == Vessage.typeChatVideo{
                    removed = fService.removeFile(value.fileId, type: .Video)
                }else if value.typeId == Vessage.typeImage{
                    removed = fService.removeFile(value.fileId, type: .Image)
                }
                if removed{
                    debugLog("Vessage File Removed:%@", value.fileId)
                }else{
                    debugLog("Remove Vessage File Fail:%@", value.fileId)
                }
            }
        }
    }
    
    func setChatterImage(chatterId:String,imageId:String) -> Bool {
        return chattersBoardManager.setChatterImageId(chatterId, imageId: imageId)
    }
    
    deinit{
        
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
}

//MAKR: Handle Gestures Delegate
extension PlayVessageManager:HandleSwipeGesture,HandlePanGesture{
    
    func onPan(v: CGPoint) ->Bool {
        return false
    }
    
    func onSwipe(direction: UISwipeGestureRecognizerDirection) -> Bool {
        if direction == .Left {
            showNextVessage()
            return true
        }else if direction == .Right{
            showPreviousVessage()
            return true
        }else{
            return false
        }
    }
}

//MARK: Bubble Vessage
protocol RequestPlayVessageManagerDelegate{
    func setGetPlayVessageManagerDelegate(delegate:GetPlayVessageManagerDelegate)
    func unsetGetPlayVessageManagerDelegate()
}

protocol GetPlayVessageManagerDelegate{
    func getPlayVessageManager() -> PlayVessageManager
}

extension PlayVessageManager:ChattersBoardDelegate{
    func chattersBoard(sender: ChattersBoard, onClick imageView: UIImageView, chatter: VessageUser) {
        let uid = chatter.userId!
        let myId = UserSetting.userId!
        if myId == uid {
            if self.rootController.userService.hasChatImages{
                self.initChatImageBoard()
                let rect = self.rootController.vessageViewContainer.convertRect(imageView.frame, fromView: sender)
                self.chatImageBoardSourceView.frame = rect
                self.chatImageBoardSourceView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
                self.chatImageBoardSourceView.layer.borderWidth = 2
                self.chatImageBoardSourceView.layer.cornerRadius = rect.height / 2
                self.rootController.vessageViewContainer.addSubview(self.chatImageBoardSourceView)
                self.presentChatImageBoard(self.chatImageBoardSourceView.bounds, sourceView: chatImageBoardSourceView)
            }else{
                self.rootController.showNoChatImagesAlert()
            }
        }else{
            debugPrint("Click Other Chatter")
        }
    }
}

extension PlayVessageManager:GetPlayVessageManagerDelegate{
    
    func getPlayVessageManager() -> PlayVessageManager {
        return self
    }
    
    func hideBubbleVessage() {
        vessageBubbleView?.hidden = true
    }
    
    func showBubbleVessage(oldVessage:Vessage?,vessage:Vessage,nextVessage:Vessage?) -> Bool {
        if let oldHandler = vessageBubbleHandler as? UnloadPresentContentHandler{
            if let vsg = oldVessage{
                oldHandler.unloadPresentContent(vsg)
            }
        }
        if let oldHandler = vessageBubbleHandler as? RequestPlayVessageManagerDelegate {
            oldHandler.unsetGetPlayVessageManagerDelegate()
        }
        
        let containerMinX = CGFloat(10)
        let containerMaxX = self.rootController.vessageViewContainer.bounds.width - 10
        
        let sender = vessage.getVessageRealSenderId()!
        if let (chatterBoard,chatterImageView) = chattersBoardManager.getChatterImageViewOfChatterId(sender){
            
            if vessageBubbleView == nil {
                vessageBubbleView = BezierBubbleView()
                self.rootController.vessageViewContainer.addSubview(vessageBubbleView)
            }
            if let faceId = vessage.getBodyDict()["faceId"] as? String{
                chatterBoard.setImageOfChatter(vessage.getVessageRealSenderId()!, imgId: faceId)
            }
            vessageBubbleView?.hidden = false
            vessageBubbleView.bubbleViewLayer.fillColor = (vessage.isMySendingVessage() ? myVessageBubbleColor : chatterVessageBubbleColor).CGColor
            let rect = self.rootController.vessageViewContainer.convertRect(chatterImageView.frame, fromView: chatterBoard)
            let rectCenterX = rect.origin.x + rect.width / 2
            
            let handler = BubbleVessageHandlerManager.getBubbleVessageHandler(vessage)
            
            let contentView = handler.getContentView(vessage)
            contentView.layoutIfNeeded()
            let contentSize = handler.getContentViewSize(vessage, maxLimitedSize: bubbleContentMaxSize,contentView: contentView)
            let containerSize = vessageBubbleView.sizeOfContentSize(contentSize, direction: .Up(startXRatio: 0))
            
            var containerX:CGFloat = rectCenterX - containerSize.width / 2
            
            if rectCenterX + containerSize.width / 2 > containerMaxX{
                containerX -= (rectCenterX + containerSize.width / 2 - containerMaxX)
            }else if rectCenterX - containerSize.width / 2 < containerMinX{
                containerX += containerMinX - (rectCenterX - containerSize.width / 2)
            }
            
            var containerY:CGFloat = rect.origin.y - 5 - containerSize.height
            var d:BezierBubbleDirection!
            let startRatio = (rect.origin.x + rect.width/2 - containerX) / containerSize.width
            
            if chatterBoard == self.rootController.bottomChattersBoard {
                d = .Up(startXRatio: Float(startRatio))
            }else{
                d = .Down(startXRatio:Float(startRatio))
                containerY = rect.origin.y + rect.size.height + 5
            }
            vessageBubbleView.frame.size = containerSize
            let containerOrigin = CGPoint(x: containerX, y: containerY)
            vessageBubbleView.frame.origin = containerOrigin
            vessageBubbleView.bubbleDirection = d
            if let delegate = handler as? BezierBubbleContentContainerDelegate {
                vessageBubbleView.containerDelegate = delegate
            }else{
                vessageBubbleView.containerDelegate = nil
            }
            if let setter = handler as? RequestPlayVessageManagerDelegate{
                setter.setGetPlayVessageManagerDelegate(self)
            }
            vessageBubbleView.layoutIfNeeded()
            contentView.frame = CGRect(origin: CGPointZero, size: contentSize)
            contentView.setNeedsDisplay()
            vessageBubbleView.setContentView(contentView)
            
            handler.presentContent(oldVessage, newVessage: vessage, contentView: contentView)
            vessageBubbleHandler = handler
            return true
        }
        return false
    }
    
    var bubbleContentMaxSize:CGSize{
        if let topChattersBoard = self.rootController?.topChattersBoard {
            if let bottomChattersBoard = self.rootController?.bottomChattersBoard{
                let h = bottomChattersBoard.frame.origin.y - (topChattersBoard.frame.origin.y + topChattersBoard.frame.size.height) - 20
                return CGSize(width: self.rootController.vessageViewContainer.frame.width - 40, height: h)
            }
        }
        return CGSizeZero
    }
    
}

//MARK: Life Circle
extension PlayVessageManager{
    override func onReleaseManager() {
        ServiceContainer.getVessageService().removeObserver(self)
        VessageQueue.sharedInstance.removeObserver(self)
        removeReadedVessages()
        super.onReleaseManager()
    }
    
    override func initManager(controller: ConversationViewController) {
        super.initManager(controller)
        vessageService.addObserver(self, selector: #selector(PlayVessageManager.onVessageReaded(_:)), name: VessageService.onVessageRead, object: nil)
        let tapChatVideo = UITapGestureRecognizer(target: self, action: #selector(PlayVessageManager.onClickChatVideoButton(_:)))
        self.rootController.sendVideoChatButton.addGestureRecognizer(tapChatVideo)
        
        let tapFaceText = UITapGestureRecognizer(target: self, action: #selector(PlayVessageManager.onClickFaceTextButton(_:)))
        self.rootController.sendFaceTextButton.addGestureRecognizer(tapFaceText)
        
        let tapSendImage = UITapGestureRecognizer(target: self, action: #selector(PlayVessageManager.onClickImageButton(_:)))
        self.rootController.sendImageButton.addGestureRecognizer(tapSendImage)
        
        let tapMgrChatImages = UITapGestureRecognizer(target: self, action: #selector(PlayVessageManager.onClickMgrChatImageButton(_:)))
        self.rootController.mgrChatImagesButton.addGestureRecognizer(tapMgrChatImages)
        
        VessageQueue.sharedInstance.addObserver(self, selector: #selector(PlayVessageManager.onNewVessagePushed(_:)), name: VessageQueue.onPushNewVessageTask, object: nil)
        
    }
}

//MARK: ChatImageBoardController
extension PlayVessageManager:ChatImageBoardControllerDelegate,UIPopoverPresentationControllerDelegate{
    
    private func initChatImageBoard(){
        if self.chatImageBoardSourceView == nil{
            chatImageBoardSourceView = UIView()
        }
        if self.chatImageBoardController == nil {
            self.chatImageBoardController = ChatImageBoardController.instanceFromStoryBoard()
            self.chatImageBoardController.modalPresentationStyle = .Popover
            self.chatImageBoardController.delegate = self
            self.chatImageBoardController.reloadChatImages()
        }
    }
    
    private func presentChatImageBoard(sourceRect:CGRect,sourceView:UIView){
        if let ppvc = self.chatImageBoardController.popoverPresentationController{
            
            if self.chatImageBoardController.chatImages.count > 0{
                let lineCount = CGFloat(self.chatImageBoardController.chatImages.count > 4 ? 4 : self.chatImageBoardController.chatImages.count)
                let preferredSize = CGSizeMake(lineCount * (72) + (lineCount - 1) * 3 + 12, 112)
                self.chatImageBoardController.preferredContentSize = preferredSize
                ppvc.sourceView = sourceView
                ppvc.sourceRect = sourceRect
                ppvc.permittedArrowDirections = .Any
                ppvc.delegate = self
                ppvc.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
                self.rootController.presentViewController(self.chatImageBoardController, animated: true, completion: nil)
            }else{
                self.rootController.playToast("U_MUST_SET_CHAT_IMAGES".localizedString())
            }
        }
    }
    
    //MARK: UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    //MARK: ChatImageBoardController Delegate
    func chatImageBoardController(appearController sender: ChatImageBoardController) {
    }
    
    func chatImageBoardController(dissmissController sender: ChatImageBoardController) {
        self.chatImageBoardSourceView?.removeFromSuperview()
    }
    
    func chatImageBoardController(sender: ChatImageBoardController, selectedIndexPath: NSIndexPath, selectedItem: ChatImage, deselectItem: ChatImage?) {
        sender.dismissViewControllerAnimated(true) {
            if let imgid = selectedItem.imageId{
                if let userId = UserSetting.userId{
                    if let (board,_) = self.chattersBoardManager.getChatterImageViewOfChatterId(userId){
                        board.setImageOfChatter(userId, imgId: imgid)
                    }
                }
            }
        }
    }
}

//MARK: init chatters
extension PlayVessageManager{
    
    override func onInitChatter(chatter: VessageUser){
        chattersBoardManager = GroupedChattersBoardManager()
        chattersBoardManager.registChattersBoards([self.rootController.topChattersBoard,self.rootController.bottomChattersBoard])
        for b in chattersBoardManager.chattersBoards{
            b.delegate = self
        }
        self.rootController.bottomChattersBoard.addChatters([chatter,self.rootController.userService.myProfile])
        onChatterUpdated(chatter)
    }
    
    override func onInitGroup(chatGroup:ChatGroup){
        chattersBoardManager = GroupedChattersBoardManager()
        chattersBoardManager.registChattersBoards([self.rootController.topChattersBoard,self.rootController.bottomChattersBoard])
        for b in chattersBoardManager.chattersBoards{
            b.delegate = self
        }
        onChatGroupUpdated(chatGroup)
    }
    
    override func onChatGroupUpdated(chatGroup: ChatGroup) {
        var noReadyUsers = [String]()
        
        let chatters = self.chatGroup.chatters.map { (userId) -> VessageUser in
            if let u = self.rootController.userService.getCachedUserProfile(userId){
                return u
            }else{
                noReadyUsers.append(userId)
                let u = VessageUser()
                u.userId = userId
                return u
            }
        }
        chattersBoardManager.clearChatters(false)
        if chatters.count <= 3 {
            rootController.bottomChattersBoard.addChatters(chatters)
        }else{
            let cnt = chatters.count / 2
            chatters.forIndexEach({ (i, element) in
                if i < cnt{
                    self.rootController.topChattersBoard.addChatter(element, isDrawNow: false)
                }else{
                    self.rootController.bottomChattersBoard.addChatter(element, isDrawNow: false)
                }
            })
            self.rootController.topChattersBoard.drawBoard()
            self.rootController.bottomChattersBoard.drawBoard()
        }
        self.rootController.controllerTitle = chatGroup.groupName
        rootController.userService.fetchUserProfilesByUserIds(noReadyUsers, callback: nil)
    }
    
    override func onGroupChatterUpdated(chatter: VessageUser) {
        chattersBoardManager.updateChatter(chatter)
    }
    
    override func onChatterUpdated(chatter: VessageUser) {
        self.rootController.controllerTitle = ServiceContainer.getUserService().getUserNotedName(conversation.chatterId)
    }

}

//MARK: Flash Tips
extension PlayVessageManager{

    func flashTips(msg:String) {
        if flashTipsView == nil {
            flashTipsView = UILabel()
            flashTipsView.clipsToBounds = true
            flashTipsView.layer.cornerRadius = 6
            flashTipsView.textColor = UIColor.orangeColor()
            flashTipsView.textAlignment = .Center
            flashTipsView.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.1)
        }
        self.flashTipsView.text = msg
        self.flashTipsView.sizeToFit()
        let bottomChattersBoard = self.rootController.bottomChattersBoard
        let topChattersBoard = self.rootController.topChattersBoard
        let topChattersBoardBottomY = topChattersBoard.frame.origin.y + topChattersBoard.frame.height
        
        let centerY = topChattersBoardBottomY + (bottomChattersBoard.frame.origin.y - topChattersBoardBottomY) / 2
        let center = CGPointMake(self.rootController.vessageViewContainer.frame.width / 2,centerY)
        self.flashTipsView.center = center
        self.rootController.view.addSubview(self.flashTipsView)
        UIAnimationHelper.flashView(self.flashTipsView, duration: 0.4, autoStop: true, stopAfterMs: 1600){
            self.flashTipsView.removeFromSuperview()
        }
    }

}
