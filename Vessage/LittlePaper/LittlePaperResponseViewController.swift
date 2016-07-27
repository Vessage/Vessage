//
//  LittlePaperResponseViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/6/13.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class LittlePaperResponseCell: UITableViewCell {
    static let reuseId = "LittlePaperResponseCell"
    @IBOutlet weak var headLine: UILabel!
    @IBOutlet weak var subLine: UILabel!
}

class LittlePaperResponseViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor.clearColor()
        let footer = UILabel()
        footer.textColor = UIColor.lightGrayColor()
        footer.textAlignment = .Center
        footer.contentMode = .Center
        self.tableView.tableFooterView = footer
        self.tableView.tableFooterView?.backgroundColor = UIColor.clearColor()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    @IBAction func onClickClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let cnt = LittlePaperManager.instance.readPaperResponses.count
        if let label = tableView.tableFooterView as? UILabel{
            label.frame = self.tableView.bounds
            if cnt > 0{
                label.text = nil
            }else{
                label.text = "NO_PAPER_MESSAGE".littlePaperString
            }
        }
        return cnt
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 67
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LittlePaperResponseCell.reuseId, forIndexPath: indexPath) as! LittlePaperResponseCell

        let info = LittlePaperManager.instance.readPaperResponses[indexPath.row]
        cell.headLine.text = String(format: "PAPER_SEND_TO_X".littlePaperString, info.paperReceiver)
        if info.type == LittlePaperReadResponse.TYPE_ASK_SENDER{
            cell.subLine.text = String(format: "X_ASK_OPEN_PAPER".littlePaperString, info.askerNick ?? "")
        }else if info.code == LittlePaperReadResponse.CODE_REJECT_READ{
            cell.subLine.text = "SENDER_REJECT_U_OPEN_PAPER".littlePaperString
        }else if info.code == LittlePaperReadResponse.CODE_ACCEPT_READ{
            cell.subLine.text = "SENDER_ACCEPT_U_OPEN_PAPER".littlePaperString
        }

        return cell
    }
 
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        let info = LittlePaperManager.instance.readPaperResponses[indexPath.row]
        if info.type == LittlePaperReadResponse.TYPE_ASK_SENDER{
            self.showAskSenderAlert(info,indexPath: indexPath)
        }else{
            self.showReturnAskerAlert(info,indexPath:indexPath)
        }
    }
    
    private func showReturnAskerAlert(info:LittlePaperReadResponse,indexPath:NSIndexPath) {
        info.isRead = true
        info.saveModel()
        let paperId = LittlePaperManager.instance.readPaperResponses[indexPath.row].paperId
        if let paper = LittlePaperManager.instance.openPaperMessage(paperId){
            if paper.isOpened {
                self.showPaperMessageDetailViewController(paper)
            }else if info.code == LittlePaperReadResponse.CODE_ACCEPT_READ{
                let hud = self.showAnimationHud()
                LittlePaperManager.instance.refreshOpenedPaper(paper, callback: { (updated) in
                    hud.hide(true)
                    if updated != nil{
                        self.showPaperMessageDetailViewController(updated!)
                    }else{
                        self.playToast("REFRESH_PAPER_ERROR".littlePaperString)
                    }
                })
            }else{
                self.showPaperMessageDetailViewController(paper)
            }
        }else{
            self.showAlert("NO_PAPER_CAN_OPEN_TITLE".littlePaperString, msg: "NO_PAPER_CAN_OPEN_MSG".littlePaperString)
        }
    }
    
    private func showPaperMessageDetailViewController(paper:LittlePaperMessage){
        let controller = PaperMessageDetailViewController.showPaperMessageDetailViewController(self.navigationController!)
        controller.paperMessage = paper
        LittlePaperManager.instance.clearPaperMessageUpdated(paper)
        
    }
    
    private func showAskSenderAlert(info:LittlePaperReadResponse,indexPath:NSIndexPath) {
        let alertController = UIAlertController(title: "AGREE_USER_OPEN_U_PAPER".littlePaperString, message: "", preferredStyle: .ActionSheet)
        let asker = UIAlertAction(title: info.askerNick, style: .Default, handler: { (ac) in
            ConversationViewController.showConversationViewController(self.navigationController!, userId: info.asker)
        })
        let accept = UIAlertAction(title: "ACCEPT_READ".littlePaperString, style: .Default, handler: { (ac) in
            let hud = self.showAnimationHud()
            LittlePaperManager.instance.acceptReadPaperForReader(info.paperId, reader: info.asker, callback: { (isOk, errorMsg) in
                hud.hide(true)
                if isOk{
                    self.tableView.reloadData()
                }else{
                    self.playToast(errorMsg!.littlePaperString)
                }
            })
        })
        
        let reject = UIAlertAction(title: "REJECT_READ".littlePaperString, style: .Default, handler: { (ac) in
            let hud = self.showAnimationHud()
            LittlePaperManager.instance.rejectReadPaperForReader(info.paperId, reader: info.asker, callback: { (isOk, errorMsg) in
                hud.hide(true)
                if isOk{
                    self.tableView.reloadData()
                }else{
                    self.playToast(errorMsg!.littlePaperString)
                }
            })
        })
        alertController.addAction(asker)
        alertController.addAction(accept)
        alertController.addAction(reject)
        alertController.addAction(ALERT_ACTION_CANCEL)
        self.showAlert(alertController)
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let info = LittlePaperManager.instance.readPaperResponses[indexPath.row]
        let actionTitle = "REMOVE".littlePaperString
        let action = UITableViewRowAction(style: .Default, title: actionTitle, handler: { (ac, indexPath) -> Void in
            LittlePaperManager.instance.removeReadResponse(info.paperId)
            self.tableView.reloadData()
        })
        return [action]
    }
    
    static func showLittlePaperResponseViewController(vc:UIViewController){
        let controller = instanceFromStoryBoard("LittlePaperMessage", identifier: "LittlePaperResponseViewController")
        let nvc = UINavigationController(rootViewController: controller)
        vc.presentViewController(nvc, animated: true, completion: nil)
    }

}
