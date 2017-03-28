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
        return LocalizedString(self, tableName: "TIMString", bundle: Bundle.main)
    }
}

class TIMStartViewController: UIViewController,UITextViewDelegate {

    @IBOutlet weak var shareTextContent: BahamutTextView!{
        didSet{
            shareTextContent.delegate = self
            shareTextContent.placeHolder = "SHARE_TEXT_PLACE_HOLDER".TIMString
        }
    }
    @IBAction func onClickClose(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if String.isNullOrWhiteSpace(shareTextContent.text) {
            shareTextContent.becomeFirstResponder()
        }
    }
    
    //MARK:UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.lengthOfBytes(using: String.Encoding.utf8) > TIMTextLengthLimit{
             textView.text = textView.text.substringToIndex(TIMTextLengthLimit)
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.lengthOfBytes(using: String.Encoding.utf8) > TIMTextLengthLimit{
            textView.text = textView.text.substringToIndex(TIMTextLengthLimit)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? TIMSharePreviewViewController{
            if String.isNullOrWhiteSpace(shareTextContent.text) {
                controller.shareTextContent = "DEFAULT_SHARE_TEXT".TIMString
            }else{
                controller.shareTextContent = shareTextContent.text
            }
        }
    }

}
