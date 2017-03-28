//
//  AboutViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController,MFMailComposeViewControllerDelegate{

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "\(VessageConfig.appName) \(VessageConfig.appVersion)"
    }
    
    @IBAction func onClickPrivacy(_ sender: AnyObject) {
        showPrivacy()
    }
    
    fileprivate func showPrivacy() {
        SimpleBrowser.openUrl(self.navigationController!, url: VessageConfig.bahamutConfig.appPrivacyPage,title: "PRIVACY".localizedString())
    }
    
    @IBAction func showInAppStore(_ sender: AnyObject)
    {
        let url = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=\(VessageConfig.bahamutConfig.appStoreId!)"
        UIApplication.shared.openURL(URL(string: url)!)
    }

    @IBAction func mailToBahamutSupport(_ sender: AnyObject) {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setSubject("Vege Feedback")
        mail.setToRecipients([VessageConfig.bahamutConfig.bahamutAppEmail])
        self.present(mail, animated: true, completion: nil)

    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    static func showAbout(_ currentViewController:UIViewController)
    {
        let controller = instanceFromStoryBoard()
        if let nvController = currentViewController.navigationController
        {
            nvController.pushViewController(controller, animated: true)
        }
    }
    
    static func instanceFromStoryBoard() -> AboutViewController
    {
        return instanceFromStoryBoard("Component", identifier: "aboutViewController") as! AboutViewController
    }
}
