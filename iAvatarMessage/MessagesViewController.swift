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
        return NSLocalizedString(self, tableName: "Locolized", bundle: Bundle.main, value: "", comment: "")
    }
}

private let contentMinHeight:CGFloat = 32
private let contentMinWidth:CGFloat = 48

private let contentTextSizeMin:Float = Float(UIFont.systemFontSize)
private let contentTextSizeMax:Float = Float(UIFont.systemFontSize) + 30

private let avatarSizeMin:Float = 64
private let avatarSizeMax:Float = 128

private let whiteColor = UIColor.white

private let contentColorSet = [
    (bubble:UIColor.lightGray,text:whiteColor),
    (bubble:UIColor.blue,text:whiteColor),
    (bubble:UIColor.green,text:whiteColor),
    (bubble:UIColor.darkGray,text:whiteColor),
    (bubble:UIColor.black,text:whiteColor),
    
    (bubble:UIColor(hexString: "#f1fafa"),text:UIColor.darkGray),
    (bubble:UIColor(hexString: "#e8ffe8"),text:UIColor.darkGray),
    (bubble:UIColor(hexString: "#e8e8ff"),text:UIColor.black),
    (bubble:UIColor(hexString: "#8080c0"),text:UIColor.yellow),
    (bubble:UIColor(hexString: "#e8d098"),text:UIColor.blue),
    
    (bubble:UIColor(hexString: "#efefda"),text:UIColor.red),
    (bubble:UIColor(hexString: "#f2fld7"),text:UIColor.red),
    
    (bubble:UIColor(hexString: "#336699"),text:whiteColor),
    (bubble:UIColor(hexString: "#6699cc"),text:whiteColor),
    (bubble:UIColor(hexString: "#66cccc"),text:whiteColor),
    (bubble:UIColor(hexString: "#b45b3e"),text:whiteColor),
    (bubble:UIColor(hexString: "#479ac7"),text:whiteColor),
    (bubble:UIColor(hexString: "#00b271"),text:whiteColor),
    
    (bubble:UIColor(hexString: "#fbfbea"),text:UIColor.black),
    (bubble:UIColor(hexString: "#d5f3f4"),text:UIColor.black),
    (bubble:UIColor(hexString: "#d7fff0"),text:UIColor.black),
    (bubble:UIColor(hexString: "#f0dad2"),text:UIColor.black),
    (bubble:UIColor(hexString: "#ddf3ff"),text:UIColor.black),
]

//MARK:MessagesViewController
class MessagesViewController: MSMessagesAppViewController {
    
    fileprivate let cachedAvatarUrl:URL = {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: cacheDir).appendingPathComponent("iavartar.png")
    }()
    
    fileprivate let tmpStickerUrl:URL = {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: cacheDir).appendingPathComponent("iavartar_tmp_sticker.png")
    }()
    
    fileprivate enum SliderMode:Int {
        case
        avatarSize = 0,
        textSize = 1,
        bubbleColor = 2
    }
    fileprivate let sliderModeCount = 3
    
    fileprivate var sliderMode = SliderMode.avatarSize{
        didSet{
            if bottomSlider != nil && oldValue != sliderMode {
                updateSlider()
                updateSliderValue()
            }
        }
    }
    
    @IBOutlet weak var inputTextView: BahamutTextView!{
        didSet{
            inputTextView.clipsToBounds = true
            inputTextView.layer.borderWidth = 0.6
            inputTextView.layer.borderColor = UIColor.lightGray.cgColor
            inputTextView.layer.cornerRadius = 6
            inputTextView.placeHolder = "INPUT_VIEW_PLACE_HOLDER".localizedString()
        }
    }
    @IBOutlet weak var sliderButton: UIButton!
    @IBOutlet weak var bottomSlider: UISlider!
    @IBOutlet weak var compactTipsView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var messageContent: UIView!
    @IBOutlet weak var flashMessageLabel: UILabel!
    
    fileprivate var contentContainer:AvatarMessageContentContainer!
    fileprivate var textMessageLabel:UILabel!
    
    var inputText:String?{
        get{
            return inputTextView?.text
        }
        set{
            inputTextView?.text = newValue
        }
    }
    
    fileprivate var messageContentColorIndex:Int{
        get{
            return UserDefaults.standard.integer(forKey: "messageContentColorIndex")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "messageContentColorIndex")
        }
    }
    
    fileprivate var avatarSize:Float{
        get{
            
            let size = UserDefaults.standard.float(forKey: "avatarSize")
            if size < avatarSizeMin {
                return avatarSizeMin
            }
            if size > avatarSizeMax {
                return avatarSizeMax
            }
            return size
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "avatarSize")
        }
    }
    
    fileprivate var textSize:Float{
        get{
            let size = UserDefaults.standard.float(forKey: "textSize")
            if size < contentTextSizeMin {
                return contentTextSizeMin
            }
            if size > contentTextSizeMax {
                return contentTextSizeMax
            }
            return size
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "textSize")
        }
    }
    
    fileprivate var messageContentColor:(bubble:UIColor,text:UIColor){
        let index = messageContentColorIndex
        if index >= 0 && index < contentColorSet.count{
            return contentColorSet[index]
        }
        return contentColorSet[0]
    }
    
    @IBOutlet weak var avatarButton: UIButton!
    
    @IBOutlet weak var bottom: NSLayoutConstraint!
    
    @IBAction func onSliderValueChanged(_ sender: AnyObject) {
        updateSliderValue()
        refreshViews()
    }
    
    @IBAction func onClickAvatarButton(_ sender: AnyObject) {
        showImagePickerForAvatar()
    }
    
    @IBAction func onClickSliderChangeButton(_ sender: AnyObject) {
        sliderMode = SliderMode(rawValue: (sliderMode.rawValue + 1) % sliderModeCount)!
    }
    
    @IBAction func onClickSend(_ sender: AnyObject) {
        if let contentImage = contentContainer.viewToImage(),let data = UIImagePNGRepresentation(contentImage),let conversation = activeConversation{
                let filePath = tmpStickerUrl.absoluteString
                debugPrint("FilePath:\(filePath)")
                do{
                    try data.write(to: tmpStickerUrl, options: .atomic)
                    let sticker = try MSSticker(contentsOfFileURL: tmpStickerUrl,localizedDescription: "")
                    
                    conversation.insert(sticker, completionHandler: { (err) in
                        if let e = err{
                            print(e)
                        }else{
                            self.requestPresentationStyle(.compact)
                        }
                    })
                }catch let err as NSError{
                    print("Store Sticker Image Error:\(err)")
                }
            
        }
    }
    
    fileprivate func refreshViews(){
        messageContent.layoutIfNeeded()
        contentContainer.frame = self.messageContent.bounds
        compactTipsView.isHidden = presentationStyle == .expanded
        messageContent.isHidden = presentationStyle == .compact
        contentContainer.layoutIfNeeded()
        for bottomView in sendButton.superview!.subviews{
            bottomView.isUserInteractionEnabled = presentationStyle == .expanded
        }
        sendButton.isUserInteractionEnabled = true
        if String.isNullOrEmpty(inputText){
            messageContent.isHidden = true
            sendButton.isEnabled = false
            bottomSlider.isHidden = true
            sliderButton.isHidden = true
            #if VERSION_LITE
                if presentationStyle == .Expanded {
                    showGDTBanner()
                }
            #endif
        }else{
            compactTipsView.isHidden = true
            bottomSlider.isHidden = false
            sliderButton.isHidden = false
            textMessageLabel?.text = inputText
            sendButton.isEnabled = true
            contentContainer.draw(self.messageContent.bounds)
            #if VERSION_LITE
                hideGDTBanner()
            #endif
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideFlashTips()
        self.view.backgroundColor = UIColor.clear
        inputTextView.delegate = self
        inputTextView.returnKeyType = .send
        textMessageLabel = UILabel()
        textMessageLabel.textAlignment = .left
        textMessageLabel.numberOfLines = 0
        textMessageLabel.font = UIFont.systemFont(ofSize: 20)
        
        self.contentContainer = AvatarMessageContentContainer(frame: CGRect.zero)
        self.contentContainer.delegate = self
        
        self.bottomSlider.setValue(Float(contentContainer.avatarSize), animated: true)
        
        self.messageContent.addSubview(contentContainer)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MessagesViewController.onTapView(_:))))
        
        let bottomView = self.sendButton?.superview
        bottomView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MessagesViewController.onTapView(_:))))
        bottomView?.isUserInteractionEnabled = true
        
        self.view.backgroundColor = UIColor.white
        bottomView?.backgroundColor = UIColor.white
        
        if let data = try? Data(contentsOf: cachedAvatarUrl),let avatar = UIImage(data: data){
            updateAvatar(avatar)
        }else{
            updateAvatar(UIImage(named: "face")!)
        }
        updateSlider()
        updateSliderValue()
        
        contentContainer.avatarSize = CGFloat(avatarSize)
        textMessageLabel.font = textMessageLabel.font.withSize(CGFloat(textSize))
        updateBubbleColors()
        
        #if VERSION_LITE
            initGDTMobAd()
        #endif
        
        refreshViews()
    }
    
    func onTapView(_ a:UITapGestureRecognizer) {
        if presentationStyle == .compact {
            requestPresentationStyle(.expanded)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.onKeyboardHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(MessagesViewController.onKeyBoardShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        requestPresentationStyle(.expanded)
        refreshViews()
        #if VERSION_LITE
            onGDTViewWillAppear()
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        #if VERSION_LITE
            onGDTViewWillDisappear()
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK: Slider Mode
extension MessagesViewController{
    
    @discardableResult
    fileprivate func updateBubbleColors() -> (bubble:UIColor,text:UIColor){
        let colorTuple = messageContentColor
        textMessageLabel.textColor = colorTuple.text
        contentContainer.bubbleView.bubbleViewLayer.fillColor = colorTuple.bubble.cgColor
        return colorTuple
    }
    
    fileprivate func updateSliderValue(){
        switch sliderMode {
        case .avatarSize:
            let ats = bottomSlider.value
            avatarSize = ats
            contentContainer.avatarSize = CGFloat(ats)
            bottomSlider.minimumTrackTintColor = nil
            bottomSlider.maximumTrackTintColor = nil
            bottomSlider.thumbTintColor = nil
        case .textSize:
            let ts = bottomSlider.value
            textSize = ts
            textMessageLabel.font = textMessageLabel.font.withSize(CGFloat(ts))
            bottomSlider.minimumTrackTintColor = nil
            bottomSlider.maximumTrackTintColor = nil
            bottomSlider.thumbTintColor = nil
        case .bubbleColor:
            let index =  Int(bottomSlider.value)
            messageContentColorIndex = index
            let colorTuple = updateBubbleColors()
            bottomSlider.thumbTintColor = colorTuple.bubble
            if index > 0 && index < contentColorSet.count{
                let leftColor = contentColorSet[index - 1]
                bottomSlider.minimumTrackTintColor = leftColor.bubble
            }
            if index < contentColorSet.count - 1 && index > 0{
                let rightColor = contentColorSet[index + 1]
                bottomSlider.maximumTrackTintColor = rightColor.bubble
            }
        }
    }
    
    fileprivate func updateSlider(){
        switch sliderMode {
        case .avatarSize:
            bottomSlider.minimumValue = avatarSizeMin
            bottomSlider.maximumValue = avatarSizeMax
            bottomSlider.setValue(avatarSize, animated: true)
            sliderButton.setImage(UIImage(named: "avatar_size_btn")!, for: UIControlState())
        case .textSize:
            bottomSlider.minimumValue = contentTextSizeMin
            bottomSlider.maximumValue = contentTextSizeMax
            bottomSlider.setValue(textSize, animated: true)
            sliderButton.setImage(UIImage(named: "text_size_btn")!, for: UIControlState())
        case .bubbleColor:
            bottomSlider.minimumValue = 0
            bottomSlider.maximumValue = Float(contentColorSet.count - 1)
            bottomSlider.setValue(Float(messageContentColorIndex), animated: true)
            sliderButton.setImage(UIImage(named: "bubble_color_btn")!, for: UIControlState())
        }
    }
}

//MARK: Update Avatar Message Content
extension MessagesViewController:AvatarMessageContentContainerDelegate{
    
    func avatarMessageContentView(_ container: AvatarMessageContentContainer) -> UIView {
        return self.textMessageLabel
    }
    
    var containerWidth:CGFloat{
        let width = self.view.frame.width * 0.9
        return width > 600 ? 600 : width
    }
    
    func avatarMessageContentContainerWidth(_ container: AvatarMessageContentContainer) -> CGFloat {
        return containerWidth
    }
    
    func avatarMessageContentViewContentSize(_ container: AvatarMessageContentContainer, containerWidth: CGFloat,contentView:UIView) -> CGSize {
        if let label = contentView as? UILabel{
            var contentSize = textMessageLabel.sizeThatFits(CGSize(width: containerWidth - 2 * 6 - 10, height: UIScreen.main.bounds.height))

            if contentSize.height < contentMinHeight || contentSize.width < contentMinWidth {
                if contentSize.height < contentMinHeight{
                    contentSize.height = contentMinHeight
                }
                if contentSize.width < contentMinWidth {
                    contentSize.width = contentMinWidth
                }
                label.textAlignment = .center
            }else{
                label.textAlignment = .left
            }
            debugPrint("contentSize:\(contentSize)")
            return contentSize
        }
        return CGSize.zero
    }
    
}

//MARK: Flash Tips
extension MessagesViewController{
    func flashTips(_ msg:String,timeMS:UInt64 = 3600) {
        if let view = flashMessageLabel?.superview{
            flashMessageLabel?.text = msg
            showFlashTips()
            UIAnimationHelper.flashView(view, duration: 0.6, autoStop: true, stopAfterMs: timeMS, completion: {
                self.hideFlashTips()
            })
        }
        
    }
    
    func showFlashTips() {
        flashMessageLabel?.superview?.isHidden = false
    }
    
    func hideFlashTips() {
        flashMessageLabel?.superview?.isHidden = true
    }
}


//MARK: Update Avatar
import ImagePickerSheetController
extension MessagesViewController{
    func showImagePickerForAvatar() {
        
        let controller = ImagePickerSheetController(mediaType: .image)
        controller.maximumSelection = 1
        
        func selectImage(_ action:ImagePickerAction, numberOfPhotos:Int){
            if numberOfPhotos > 0{
                if let asset = controller.selectedImageAssets.first{
                    PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 120, height: 128), contentMode: .aspectFill, options: nil, resultHandler: { (image, userInfo) in
                        if let img = image{
                            self.setAvatar(img)
                        }else{
                            self.flashTips("READ_AVATAR_IMAGE_ERROR".localizedString())
                        }
                    })
                }
            }
        }
        
        controller.addAction(ImagePickerAction(title: "SELECT_IMAGE_SOURCE_TITLE".localizedString(), secondaryTitle: "CONFIRM".localizedString(), handler: { _ in}, secondaryHandler: selectImage))
        controller.addAction(ImagePickerAction(title: "CANCEL".localizedString(), style: .cancel, handler: { _ in
        }))
        
        self.present(controller, animated: true, completion: nil)
 
    }
    
    func setAvatar(_ image:UIImage) {
        if let pngData = UIImagePNGRepresentation(image){
            do{
                try pngData.write(to: cachedAvatarUrl, options: .atomic)
            }catch let err as NSError{
                flashTips("PREPARE_DATA_ERROR".localizedString())
                print(err)
            }
        }
        updateAvatar(image)
        flashTips("AVATAR_UPDATED".localizedString())
    }
    
    func updateAvatar(_ image:UIImage) {
        self.contentContainer?.avatarImageView?.image = image
        self.avatarButton?.setImage(image, for: UIControlState())
        self.avatarButton?.imageView?.contentMode = .scaleAspectFill
    }
}

//MARK: Input Text View Delegate
extension MessagesViewController:UITextViewDelegate{
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            onClickSend(textView)
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        refreshViews()
    }
}

//MARK: Keyboard
extension MessagesViewController{
    func onKeyBoardShown(_ a:Notification) {
        if let value = a.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue{
            bottom?.constant = value.cgRectValue.height
            self.view.updateConstraints()
            self.view.layoutIfNeeded()
        }
    }
    
    func onKeyboardHidden(_ a:Notification) {
        bottom?.constant = 0
        self.view.updateConstraints()
        self.view.layoutIfNeeded()
    }
}

// MARK: - Conversation Handling
extension MessagesViewController{
    override func willBecomeActive(with conversation: MSConversation) {
        requestPresentationStyle(.expanded)
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        self.inputText = nil
        self.refreshViews()
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
        
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
       
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        refreshViews()
        if presentationStyle == .compact {
            bottom?.constant = 0
        }else if presentationStyle == .expanded{
            if String.isNullOrEmpty(self.inputText) {
                self.inputTextView?.becomeFirstResponder()
            }
        }
        self.inputTextView?.superview?.layoutIfNeeded()
        self.view.layoutIfNeeded()
        self.view.layoutSubviews()
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
}
