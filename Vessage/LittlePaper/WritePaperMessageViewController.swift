//
//  WritePaperMessageViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/8.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class WritePaperMessageViewController: UIViewController,SelectVessageUserViewControllerDelegate{

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var receiverInfoTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBarHidden = false
    }
    
    //MARK: SelectVessageUserViewControllerDelegate
    func onFinishSelect(sender:SelectVessageUserViewController,selectedUsers: [VessageUser]) {
        let message = messageTextView.text!
        let receiverInfo = receiverInfoTextField.text!
        let hud = self.showActivityHudWithMessage(nil, message: nil)
        LittlePaperManager.instance.newPaperMessage(message, receiverInfo: receiverInfo, nextReceiver: selectedUsers.first!.userId) { (suc) in
            hud.hideAsync(true)
            if suc{
                self.playCheckMark("SUCCESS".littlePaperString,async:false){
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }else{
                self.playCrossMark("FAIL".littlePaperString)
            }
        }
    }
    
    @IBAction func onClickPostButton(sender: AnyObject) {
        hideKeyBoard()
        if String.isNullOrWhiteSpace(receiverInfoTextField.text) {
            self.playToast("PAPER_RECEIVER_IS_NULL".littlePaperString){
                self.receiverInfoTextField.becomeFirstResponder()
            }
            return
        }
        if String.isNullOrWhiteSpace(messageTextView.text) {
            self.playToast("PAPER_MESSAGE_IS_NULL".littlePaperString){
                self.messageTextView.becomeFirstResponder()
            }
            return
        }
        if String.isNullOrWhiteSpace(receiverInfoTextField.text) {
            self.playToast("PAPER_RECEIVER_IS_NULL".littlePaperString)
            return
        }
        
        let controller = SelectVessageUserViewController.showSelectVessageUserViewController(self.navigationController!)
        controller.title = "SELECT_POST_MAN".littlePaperString
        controller.delegate = self
        controller.showActiveUsers = true
        controller.allowsMultipleSelection = false
    }
    
    @IBAction func onClickCancelButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    static func showWritePaperMessageViewController(vc:UIViewController){
        let controller = instanceFromStoryBoard("LittlePaperMessage", identifier: "WritePaperMessageViewController") as! WritePaperMessageViewController
        let nvc = UINavigationController(rootViewController: controller)
        vc.presentViewController(nvc, animated: true, completion: nil)
    }
}
