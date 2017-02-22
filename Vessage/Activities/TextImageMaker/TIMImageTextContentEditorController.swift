//
//  TIMImageTextContentEditorController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

protocol TIMImageTextContentEditorControllerDelegate {
    func imageTextContentEditor(sender:TIMImageTextContentEditorController,newTextContent:String?,model:TIMImageTextContentEditorModel?)
}

class TIMImageTextContentEditorModel {
    static let extraSwitchOnTipsKey = "EX_SWITCH_ON_TIPS"
    static let extraSwitchOffTipsKey = "EX_SWITCH_OFF_TIPS"
    static let extraSwitchInitValueKey = "EX_SWITCH_INT_VAR"
    static let extraSwitchLabelTextKey = "EX_SWITCH_LABEL_TXT"
    
    static let extraSwitchValueKey = "EX_SWITCH_VAR"
    
    static let imageIdKey = "IMAGE_ID"
    
    var id:String?
    var editorTitle:String?
    var image:UIImage?
    var placeHolder:String?
    var initTextContent:String?
    var userInfo:NSMutableDictionary?
    var extraSetup = false
    
}

class TIMImageTextContentEditorController: UIViewController {
    
    static var cachedTextContent:String? = nil
    
    var delegate:TIMImageTextContentEditorControllerDelegate?
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: BahamutTextView!
    
    @IBOutlet weak var extraViewsContainer: UIView!{
        didSet{
            extraViewsContainer?.hidden = true
        }
    }
    
    @IBOutlet weak var extraTipsLabel: UILabel!
    @IBOutlet weak var extraSwitch: UISwitch!
    @IBOutlet weak var extraSwitchLabel: UILabel!
    
    var propertyModel:TIMImageTextContentEditorModel!
    private var modelSetted = false
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let model = self.propertyModel{
            if modelSetted == false{
                modelSetted = true
                self.setPropertiesWithModel(model)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if String.isNullOrWhiteSpace(self.textView?.text) {
            self.textView?.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        TIMImageTextContentEditorController.cachedTextContent = self.textView?.text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.userInteractionEnabled = true
        imageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TIMImageTextContentEditorController.onTapImageView(_:))))
    }
    
    func onTapImageView(ges:UITapGestureRecognizer) {
        self.imageView?.slideShowFullScreen(self)
    }
    
    @IBAction func done(sender: AnyObject) {
        let newValue = self.textView?.text
        if self.propertyModel.userInfo == nil{
            self.propertyModel.userInfo = [TIMImageTextContentEditorModel.extraSwitchValueKey:extraSwitch.on]
        }else{
            self.propertyModel.userInfo?[TIMImageTextContentEditorModel.extraSwitchValueKey] = extraSwitch.on
        }
        let model = self.propertyModel
        let controller = self
        self.navigationController?.popViewControllerAnimated(true)
        TIMImageTextContentEditorController.cachedTextContent = nil
        self.textView.text = nil
        self.delegate?.imageTextContentEditor(controller, newTextContent: newValue, model: model)
    }
    
    private func setPropertiesWithModel(model:TIMImageTextContentEditorModel){
        self.title = model.editorTitle
        self.textView?.placeHolder = model.placeHolder
        self.textView?.text = model.initTextContent
        if String.isNullOrEmpty(model.initTextContent) && TIMImageTextContentEditorController.cachedTextContent != nil{
            self.textView?.text = TIMImageTextContentEditorController.cachedTextContent
        }
        if let img = model.image{
            self.imageView.image = img
        }else if let imageId = model.userInfo?[TIMImageTextContentEditorModel.imageIdKey] as? String{
            ServiceContainer.getFileService().setImage(imageView, iconFileId: imageId)
        }else{
            self.imageView?.constraints.filter{$0.identifier == "width"}.first?.constant = 0
        }
        self.initExtraSetup()
    }
    
    static func showEditor(nvc:UINavigationController,model:TIMImageTextContentEditorModel,delegate:TIMImageTextContentEditorControllerDelegate)->TIMImageTextContentEditorController{
        let controller = instanceFromStoryBoard("TIMContentEditorController", identifier: "TIMImageTextContentEditorController") as! TIMImageTextContentEditorController
        controller.delegate = delegate
        nvc.pushViewController(controller, animated: true)
        controller.propertyModel = model
        return controller
    }
}

//MARK: Extra Setup
extension TIMImageTextContentEditorController{
    private func initExtraSetup() {
        self.extraViewsContainer?.hidden = !self.propertyModel.extraSetup
        if self.propertyModel.extraSetup {
            if let on = self.propertyModel.userInfo?[TIMImageTextContentEditorModel.extraSwitchInitValueKey] as? Bool {
                self.extraSwitch.setOn(on, animated: false)
            }
            
            if let switchLabelText = self.propertyModel.userInfo?[TIMImageTextContentEditorModel.extraSwitchInitValueKey] as? String {
                extraSwitchLabel.text = switchLabelText
            }
            
            onExtraSwitchValueChanged(self.extraSwitch)
        }
    }
    
    @IBAction func onExtraSwitchValueChanged(sender: AnyObject) {
        if let switcher = sender as? UISwitch {
            let key = switcher.on ? TIMImageTextContentEditorModel.extraSwitchOnTipsKey : TIMImageTextContentEditorModel.extraSwitchOffTipsKey
            if let tips = propertyModel?.userInfo?[key] as? String{
                extraTipsLabel.text = tips
            }else{
                extraTipsLabel.text = nil
            }
        }
    }
}
