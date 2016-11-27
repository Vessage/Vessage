//
//  MessagesViewController.swift
//  iAvatarMessage
//
//  Created by Alex Chow on 2016/11/25.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import Messages
import Photos

extension String
{
    func localizedString() -> String{
        return NSLocalizedString(self, tableName: "Locolized", bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}

//MARK:MessagesViewController
class MessagesViewController: MSMessagesAppViewController {
    
    private let cachedAvatarUrl:NSURL = {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
        return NSURL(fileURLWithPath: cacheDir).URLByAppendingPathComponent("iavartar.png")!
    }()
    
    private let tmpStickerUrl:NSURL = {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
        return NSURL(fileURLWithPath: cacheDir).URLByAppendingPathComponent("iavartar_tmp_sticker.png")!
    }()
    
    @IBOutlet weak var avatarSizeSlider: UISlider!
    @IBOutlet weak var compactTipsView: UIView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var messageContent: UIView!
    @IBOutlet weak var flashMessageLabel: UILabel!
    var contentContainer:AvatarMessageContentContainer!
    var textMessageLabel:UILabel!
    
    @IBOutlet weak var avatarButton: UIButton!
    private var bubbleView:BezierBubbleView!{
        didSet{
            bubbleView.bubbleViewLayer.fillColor = UIColor.lightGrayColor().CGColor
        }
    }
    
    @IBOutlet weak var bottom: NSLayoutConstraint!
    
    @IBAction func onAvatarSizeValueChanged(sender: AnyObject) {
        contentContainer.avatarSize = CGFloat(avatarSizeSlider.value)
        refreshViews()
    }
    
    @IBAction func onClickAvatarButton(sender: AnyObject) {
        showImagePickerForAvatar()
    }
    
    @IBAction func onClickSend(sender: AnyObject) {
        if let contentImage = contentContainer.viewToImage(),let data = UIImagePNGRepresentation(contentImage),let conversation = activeConversation,let filePath = tmpStickerUrl.absoluteString{
                debugPrint("FilePath:\(filePath)")
                do{
                    try data.writeToURL(tmpStickerUrl, options: .DataWritingAtomic)
                    let sticker = try MSSticker(contentsOfFileURL: tmpStickerUrl,localizedDescription: "")
                    
                    conversation.insertSticker(sticker, completionHandler: { (err) in
                        if let e = err{
                            print(e)
                        }else{
                            self.requestPresentationStyle(.Compact)
                        }
                    })
                }catch let err as NSError{
                    print("Store Sticker Image Error:\(err)")
                }
            
        }
        
        
    }
    
    @IBAction func onTextMessageChanged(sender: AnyObject) {
        refreshViews()
    }
    
    private func refreshViews(){
        messageContent.layoutIfNeeded()
        contentContainer.frame = self.messageContent.bounds
        compactTipsView.hidden = presentationStyle == .Expanded
        messageContent.hidden = presentationStyle == .Compact
        contentContainer.layoutIfNeeded()
        for bottomView in sendButton.superview!.subviews{
            bottomView.userInteractionEnabled = presentationStyle == .Expanded
        }
        sendButton.userInteractionEnabled = true
        if String.isNullOrEmpty(inputTextField.text){
            messageContent.hidden = true
            sendButton.enabled = false
            avatarSizeSlider.hidden = true
        }else{
            compactTipsView.hidden = true
            avatarSizeSlider.hidden = false
            textMessageLabel?.text = inputTextField.text
            sendButton.enabled = true
            contentContainer.drawRect(self.messageContent.bounds)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideFlashTips()
        self.view.backgroundColor = UIColor.clearColor()
        textMessageLabel = UILabel()
        textMessageLabel.textAlignment = .Left
        textMessageLabel.numberOfLines = 0
        textMessageLabel.font = UIFont.systemFontOfSize(20)
        textMessageLabel.textColor = UIColor.whiteColor()
        
        self.contentContainer = AvatarMessageContentContainer(frame: CGRectZero)
        self.contentContainer.delegate = self
        
        self.avatarSizeSlider.setValue(Float(contentContainer.avatarSize), animated: true)
        
        self.messageContent.addSubview(contentContainer)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MessagesViewController.onTapView(_:))))
        
        let bottomView = self.sendButton?.superview
        bottomView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MessagesViewController.onTapView(_:))))
        bottomView?.userInteractionEnabled = true
        
        self.view.backgroundColor = UIColor.whiteColor()
        bottomView?.backgroundColor = UIColor.whiteColor()
        
        if let data = NSData(contentsOfURL: cachedAvatarUrl),let avatar = UIImage(data: data){
            updateAvatar(avatar)
        }else{
            updateAvatar(UIImage(named: "face")!)
        }
        refreshViews()
    }
    
    func onTapView(a:UITapGestureRecognizer) {
        if presentationStyle == .Compact {
            requestPresentationStyle(.Expanded)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessagesViewController.onKeyboardHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessagesViewController.onKeyboardHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(MessagesViewController.onKeyBoardShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
        requestPresentationStyle(.Expanded)
        refreshViews()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        refreshViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK: Update Avatar Message Content
extension MessagesViewController:AvatarMessageContentContainerDelegate{
    
    func avatarMessageContentView(container: AvatarMessageContentContainer) -> UIView {
        return self.textMessageLabel
    }
    
    var containerWidth:CGFloat{
        let width = self.view.frame.width * 0.9
        return width > 600 ? 600 : width
    }
    
    func avatarMessageContentContainerWidth(container: AvatarMessageContentContainer) -> CGFloat {
        return containerWidth
    }
    
    func avatarMessageContentViewContentSize(container: AvatarMessageContentContainer, containerWidth: CGFloat,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel{
            var contentSize = textMessageLabel.sizeThatFits(CGSizeMake(containerWidth - 2 * 6 - 10, UIScreen.mainScreen().bounds.height))
            
            /*
            if contentSize.width < contentContainer.avatarSize {
                contentSize.width = contentContainer.avatarSize
                label.textAlignment = .Center
            }else{
                label.textAlignment = .Left
            }
 */
            if contentSize.height < contentContainer.avatarSize {
                contentSize.height = contentContainer.avatarSize
                label.textAlignment = .Center
            }else{
                label.textAlignment = .Left
            }
            debugPrint("contentSize:\(contentSize)")
            return contentSize
        }
        return CGSizeZero
    }
    
}

//MARK: Flash Tips
extension MessagesViewController{
    func flashTips(msg:String,timeMS:UInt64 = 3600) {
        if let view = flashMessageLabel?.superview{
            flashMessageLabel?.text = msg
            showFlashTips()
            UIAnimationHelper.flashView(view, duration: 0.6, autoStop: true, stopAfterMs: timeMS, completion: {
                self.hideFlashTips()
            })
        }
        
    }
    
    func showFlashTips() {
        flashMessageLabel?.superview?.hidden = false
    }
    
    func hideFlashTips() {
        flashMessageLabel?.superview?.hidden = true
    }
}


//MARK: Update Avatar
import ImagePickerSheetController
extension MessagesViewController{
    func showImagePickerForAvatar() {
        let controller = ImagePickerSheetController.init(mediaType: .Image)
        controller.maximumSelection = 1
        
        controller.addAction(ImagePickerAction(title: "SELECT_IMAGE_SOURCE_TITLE".localizedString(), secondaryTitle: "CONFIRM".localizedString(), handler: { _ in
            
            }, secondaryHandler: { _, numberOfPhotos in
                if numberOfPhotos > 0{
                    if let asset = controller.selectedImageAssets.first{
                        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSizeMake(120, 128), contentMode: .AspectFill, options: nil, resultHandler: { (image, userInfo) in
                            if let img = image{
                                self.setAvatar(img)
                            }else{
                                self.flashTips("READ_AVATAR_IMAGE_ERROR".localizedString())
                            }
                        })
                    }
                }
        }))
        
        controller.addAction(ImagePickerAction(title: "CANCEL".localizedString(), style: .Cancel, handler: { _ in
            
        }))
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func setAvatar(image:UIImage) {
        if let pngData = UIImagePNGRepresentation(image){
            do{
                try pngData.writeToURL(cachedAvatarUrl, options: .DataWritingAtomic)
            }catch let err as NSError{
                flashTips("PREPARE_DATA_ERROR".localizedString())
                print(err)
            }
        }
        updateAvatar(image)
        flashTips("AVATAR_UPDATED".localizedString())
    }
    
    func updateAvatar(image:UIImage) {
        self.contentContainer?.avatarImageView?.image = image
        self.avatarButton?.setImage(image, forState: .Normal)
        self.avatarButton?.imageView?.contentMode = .ScaleAspectFill
    }
}

extension MessagesViewController{
    func onKeyBoardShown(a:NSNotification) {
        if let value = a.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue{
            bottom?.constant = value.CGRectValue().height
        }
    }
    
    func onKeyboardHidden(a:NSNotification) {
        bottom?.constant = 0
    }
}

// MARK: - Conversation Handling
extension MessagesViewController{
    override func willBecomeActiveWithConversation(conversation: MSConversation) {
        requestPresentationStyle(.Expanded)
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
    }
    
    override func didResignActiveWithConversation(conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
    
    override func didReceiveMessage(message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSendingMessage(message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        self.inputTextField.text = nil
        self.refreshViews()
    }
    
    override func didCancelSendingMessage(message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
        
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransitionToPresentationStyle(presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
       
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransitionToPresentationStyle(presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        refreshViews()
        if presentationStyle == .Compact {
            bottom?.constant = 0
            self.inputTextField?.superview?.layoutIfNeeded()
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        }
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
}
