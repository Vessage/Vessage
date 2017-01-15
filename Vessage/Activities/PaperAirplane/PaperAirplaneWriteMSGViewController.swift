//
//  PaperAirplaneWriteMSGViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/13.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import UIKit

protocol PaperAirplaneWriteMSGViewControllerDelegate {
    func paperAirplaneWriteMSGViewController(sender:PaperAirplaneWriteMSGViewController, onFlyedPlane plane:PaperAirplane)
}

class PaperAirplaneWriteMSGViewController: UIViewController {
    
    var airplane:PaperAirplane?
    var delegate:PaperAirplaneWriteMSGViewControllerDelegate?
    
    @IBOutlet weak var textView: BahamutTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.placeHolder = "WRITE_YOUR_MSG_HINT".PaperAirplaneString
        // Do any additional setup after loading the view.
    }
    
    @IBAction func flyAirplane(sender: AnyObject) {
        if airplane == nil {
            postNewAirplane()
        }else{
            writeNoteToPlane()
        }
    }
    
    private func writeNoteToPlane(){
        let req = NewPaperAirplaneMessageRequest()
        req.paId = airplane?.id
        if String.isNullOrWhiteSpace(textView?.text) == false {
            req.msg = textView?.text
        }
        postPARequest(req)
    }
    
    private func postNewAirplane() {
        let req = NewPaperAirplaneRequest()
        req.msg = textView.text
        postPARequest(req)
    }
    
    func postPARequest(req:NewPaperAirplaneRequest) {
        let user = ServiceContainer.getUserService().myProfile
        req.avatar = user.avatar
        req.nick = user.nickName
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            self.playFlyAnimation()
        }
    }
    
    private func playFlyAnimation() {
        
    }

}

extension PaperAirplaneWriteMSGViewController{
    static func showFlyoutPlaneWriteNoteController(nvc:UINavigationController,plane:PaperAirplane,delegate:PaperAirplaneWriteMSGViewControllerDelegate?) {
        let controller = instanceFromStoryBoard("PaperAirplane", identifier: "PaperAirplaneWriteMSGViewController") as! PaperAirplaneWriteMSGViewController
        controller.airplane = plane
        controller.delegate = delegate
        controller.title = "WRITE_NOTE_AND_FLY".PaperAirplaneString
        nvc.pushViewController(controller, animated: true)
    }
}
