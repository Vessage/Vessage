//
//  ConversationViewTimeMachineExtension.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/2.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
extension ConversationViewController{
    func initTimeMachine() {
        let tapTimemachineButton = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.onClickVessageTimeMachineButton(_:)))
        self.timemachineButton.addGestureRecognizer(tapTimemachineButton)
    }
    
    func onClickVessageTimeMachineButton(sender: UITapGestureRecognizer) {
        self.timemachineButton.animationMaxToMin(0.1, maxScale: 1.2, completion: {
            self.showVessageTimeMachineList()
        })
    }
    
    func showVessageTimeMachineList() {
        let timeButton = self.timemachineButton
        let ts = vessages.first?.ts ?? DateHelper.UnixTimeSpanTotalMilliseconds
        if timeMachineListController == nil {
            timeMachineListController = TimeMachineVessageListController.instanceOfController(self.conversation.chatterId, ts: ts)
        }
        let controller = timeMachineListController!
        controller.modalPresentationStyle = .Popover
        let viewFrame = self.view.bounds
        controller.preferredContentSize = CGSizeMake(viewFrame.width * 0.6, viewFrame.height * 0.5)
        if let ppvc = controller.popoverPresentationController{
            
            ppvc.sourceView = timeButton
            ppvc.sourceRect = timeButton.bounds
            ppvc.permittedArrowDirections = .Any
            ppvc.delegate = self
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
}
