//
//  TIMStartViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/18.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

private let TIMTextLengthLimit = 300

extension String{
    var TIMString:String{
        return LocalizedString(self, tableName: "TIMString", bundle: NSBundle.mainBundle())
    }
}

class TIMStartViewController: UIViewController,UITextViewDelegate {

    @IBOutlet weak var shareTextContent: BahamutTextView!{
        didSet{
            shareTextContent.delegate = self
            shareTextContent.placeHolder = "SHARE_TEXT_PLACE_HOLDER".TIMString
        }
    }
    @IBAction func onClickClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if String.isNullOrWhiteSpace(shareTextContent.text) {
            shareTextContent.becomeFirstResponder()
        }
    }
    
    //MARK:UITextViewDelegate
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView.text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > TIMTextLengthLimit{
            textView.text.substringToIndex(TIMTextLengthLimit)
            return false
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        if textView.text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > TIMTextLengthLimit{
            textView.text.substringToIndex(TIMTextLengthLimit)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? TIMSharePreviewViewController{
            if String.isNullOrWhiteSpace(shareTextContent.text) {
                controller.shareTextContent = "DEFAULT_SHARE_TEXT".TIMString
            }else{
                controller.shareTextContent = shareTextContent.text
            }
        }
    }

}
