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
    var id:String?
    var editorTitle:String?
    var image:UIImage?
    var placeHolder:String?
    var initTextContent:String?
    var userInfo:NSDictionary?
}

class TIMImageTextContentEditorController: UIViewController {
    var delegate:TIMImageTextContentEditorControllerDelegate?
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: BahamutTextView!
    
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
    
    @IBAction func done(sender: AnyObject) {
        let newValue = self.textView?.text
        let model = self.propertyModel
        let controller = self
        self.navigationController?.popViewControllerAnimated(true)
        self.delegate?.imageTextContentEditor(controller, newTextContent: newValue, model: model)
    }
    
    private func setPropertiesWithModel(model:TIMImageTextContentEditorModel){
        self.title = model.editorTitle
        self.textView?.placeHolder = model.placeHolder
        self.textView?.text = model.initTextContent
        self.imageView?.image = model.image
    }
    
    static func showEditor(nvc:UINavigationController,model:TIMImageTextContentEditorModel,delegate:TIMImageTextContentEditorControllerDelegate)->TIMImageTextContentEditorController{
        let controller = instanceFromStoryBoard("TIMContentEditorController", identifier: "TIMImageTextContentEditorController") as! TIMImageTextContentEditorController
        controller.delegate = delegate
        nvc.pushViewController(controller, animated: true)
        controller.propertyModel = model
        return controller
    }
}
