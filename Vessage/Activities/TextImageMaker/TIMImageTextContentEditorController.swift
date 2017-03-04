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
    static let extraAutoPrivateSecKey = "EX_AUTO_PRIVATE_SEC"
    
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
    
    @IBOutlet weak var extraAutoPrivateLabel: UILabel!
    @IBOutlet weak var extraAutoPrivateNextMark: UIImageView!
    
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
extension TIMImageTextContentEditorController:SelectAutoPrivateExpireTimeControllerDelegate{
    private func initExtraSetup() {
        self.extraViewsContainer?.hidden = !self.propertyModel.extraSetup
        if self.propertyModel.extraSetup {
            if let on = self.propertyModel.userInfo?[TIMImageTextContentEditorModel.extraSwitchInitValueKey] as? Bool {
                self.extraSwitch.setOn(on, animated: false)
            }
            
            if let switchLabelText = self.propertyModel.userInfo?[TIMImageTextContentEditorModel.extraSwitchInitValueKey] as? String {
                extraSwitchLabel.text = switchLabelText
            }
            extraAutoPrivateLabel.text = getDescStringFromDays(0)
            initAutoPrivateAction()
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

            updateAutoPrivateAction()
        }
    }
    
    private func updateAutoPrivateAction() {
        extraAutoPrivateLabel.hidden = !self.extraSwitch.on
        extraAutoPrivateNextMark.hidden = !self.extraSwitch.on
        if !self.extraSwitch.on {
            self.propertyModel?.userInfo?.removeObjectForKey(TIMImageTextContentEditorModel.extraAutoPrivateSecKey)
        }
    }
    
    func initAutoPrivateAction() {
        extraAutoPrivateNextMark?.userInteractionEnabled = true
        extraAutoPrivateNextMark?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TIMImageTextContentEditorController.onTapExtraAutoPrivateView(_:))))
        
        extraAutoPrivateLabel?.userInteractionEnabled = true
        extraAutoPrivateLabel?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TIMImageTextContentEditorController.onTapExtraAutoPrivateView(_:))))
    }
    
    func onTapExtraAutoPrivateView(a:UITapGestureRecognizer) {
        let selController = SelectAutoPrivateExpireTimeController(style: .Plain)
        selController.delegate = self
        self.navigationController?.pushViewController(selController, animated: true)
    }
    
    func selectAutoPrivateExpireTimeController(sender: SelectAutoPrivateExpireTimeController, autoSetPrivateExpireDays: Int, desc: String) {
        extraAutoPrivateLabel.text = desc
        let key = TIMImageTextContentEditorModel.extraAutoPrivateSecKey
        let ts = autoSetPrivateExpireDays * 24 * 3600
        if let _ = self.propertyModel?.userInfo{
            self.propertyModel?.userInfo?[key] = ts
        }else if self.propertyModel != nil{
            self.propertyModel.userInfo = [key:ts]
        }
    }
}

//MARK:SelectAutoPrivateExpireTimeController

private func getDescStringFromDays(days:Int) -> String {
    if days == 0 {
        return "NEVER_SET_PRIVATE".TIMString
    }else if days < 7{
        return String(format: "SET_PRIV_X_DAYS_LTER".TIMString,days)
    }else{
        return String(format: "SET_PRIV_X_WEEKS_LTER".TIMString,days / 7)
    }
}

protocol SelectAutoPrivateExpireTimeControllerDelegate {
    func selectAutoPrivateExpireTimeController(sender:SelectAutoPrivateExpireTimeController, autoSetPrivateExpireDays:Int, desc:String)
}

class SelectAutoPrivateExpireTimeController: UITableViewController {
    let reuseId = "SelTimeCell"
    
    let expiredTimeDays = [0,1,2,3,7,14]
    
    var delegate:SelectAutoPrivateExpireTimeControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "SEL_AUTO_PRIV_TIME".TIMString
        tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: reuseId)
        tableView.tableFooterView = UIView()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expiredTimeDays.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath)
        cell.contentView.removeAllSubviews()
        let label = UILabel(frame:cell.bounds)
        label.frame.origin.x += 13
        label.frame.size.width -= 20
        let days = expiredTimeDays[indexPath.row]
        label.text = getDescStringFromDays(days)
        cell.contentView.addSubview(label)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let days = expiredTimeDays[indexPath.row]
        delegate?.selectAutoPrivateExpireTimeController(self,autoSetPrivateExpireDays: days,desc: getDescStringFromDays(days))
        self.navigationController?.popViewControllerAnimated(true)
    }
}
