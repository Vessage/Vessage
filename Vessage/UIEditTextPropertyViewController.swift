//
//  UIEditTextPropertyViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit


protocol UIEditTextPropertyViewControllerDelegate
{
    func editPropertySave(_ sender:UIEditTextPropertyViewController,propertyIdentifier:String!,newValue:String!,userInfo:[String:AnyObject?]?)
}

class UIEditTextPropertySet
{
    var isOneLineValue:Bool = true
    var valueTextViewHolder:String?
    
    var valueRegex:String!
    var valueNullable:Bool = false
    var illegalValueMessage:String!
    
    var propertyValue:String!
    var propertyLabel:String!
    var propertyIdentifier:String!
    
    var userInfo:[String:AnyObject?]?
    
}

class UIEditTextPropertyViewController: UIViewController
{

    @IBOutlet weak var propertyValueTextView: BahamutTextView!{
        didSet{
            propertyValueTextView.backgroundColor = UIColor.clear
            propertyValueTextView.layer.cornerRadius = 7
            propertyValueTextView.layer.borderWidth = 1
            propertyValueTextView.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    @IBOutlet weak var propertyValueTextField: UITextField!
    
    var model:UIEditTextPropertySet!
    var delegate:UIEditTextPropertyViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        updateTextValueView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    fileprivate func updateTextValueView()
    {
        if model.isOneLineValue {
            propertyValueTextField.text = model?.propertyValue
        }else{
            propertyValueTextView.text = model?.propertyValue
        }
        
        propertyValueTextView.isHidden = model.isOneLineValue
        propertyValueTextField.isHidden = !model.isOneLineValue
        propertyValueTextField.placeholder = model?.valueTextViewHolder
        propertyValueTextView.placeHolder = model?.valueTextViewHolder
    }
    
    fileprivate var newPropertyValue:String!{
        get{
            if model.isOneLineValue
            {
                return propertyValueTextField.text
            }else{
                return propertyValueTextView.text
            }
        }
        set{
            if model.isOneLineValue
            {
                propertyValueTextField.text = newValue
            }else{
                propertyValueTextView.text = newValue
            }
        }
    }
    
    @IBAction func save(_ sender: AnyObject)
    {
        
        if String.isNullOrEmpty(newPropertyValue) {
            if !model.valueNullable {
                self.playToast( "CANT_NULL".localizedString())
                return
            }
        }else if let valueRegex = model.valueRegex
        {
            if !(newPropertyValue.isRegexMatch(pattern:valueRegex))
            {
                self.playToast( model.illegalValueMessage ?? "ILLEGLE_VALUE".localizedString())
                return
            }
        }
        
        
        delegate?.editPropertySave(self,propertyIdentifier: model.propertyIdentifier,newValue: newPropertyValue,userInfo: model.userInfo)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @discardableResult
    static func showEditPropertyViewController(_ currentNavigationController:UINavigationController,propertySet:UIEditTextPropertySet,controllerTitle:String,delegate:UIEditTextPropertyViewControllerDelegate) -> UIEditTextPropertyViewController
    {
        let controller = instanceFromStoryBoard()
        controller.title = controllerTitle
        controller.model = propertySet
        currentNavigationController.pushViewController(controller, animated: true)
        controller.delegate = delegate
        return controller
    }
    
    static func instanceFromStoryBoard() -> UIEditTextPropertyViewController
    {
        return instanceFromStoryBoard("Component", identifier: "editTextPropertyViewController",bundle: Bundle.main) as! UIEditTextPropertyViewController
    }
    
}
