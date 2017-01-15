//
//  PaperAirplaneDetailViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/1/13.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import UIKit

class PaperAirplaneMessageCell: UITableViewCell {
    static let reuseId = "PaperAirplaneMessageCell"
    
    var message:PaperAirplaneMessage?
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nickLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    func updateCell() {
        nickLabel.text = message?.nick
        contentLabel.text = message?.msg
    }
    
    func updateImages() {
        ServiceContainer.getFileService().setImage(self.avatarImageView, iconFileId: message?.avatar)
    }
}

protocol PaperAirplaneDetailViewControllerDelegate {
    func paperAirplaneDetailViewController(sender:PaperAirplaneDetailViewController,plane:PaperAirplane,isFlyOut:Bool)
}

class PaperAirplaneDetailViewController: UIViewController {

    var paperAirplane:PaperAirplane!{
        didSet{
            tableView?.reloadData()
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate:PaperAirplaneDetailViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.autoRowHeight()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func flyOut(sender: AnyObject) {
        PaperAirplaneWriteMSGViewController.showFlyoutPlaneWriteNoteController(self.navigationController!, plane: self.paperAirplane,delegate: self)
    }
    
    @IBAction func destroyAirplane(sender: AnyObject) {
        let req = DestroyPaperAirplaneRequest()
        req.paId = paperAirplane.id
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<MsgResult>) in
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
}

extension PaperAirplaneDetailViewController:PaperAirplaneWriteMSGViewControllerDelegate{
    func paperAirplaneWriteMSGViewController(sender: PaperAirplaneWriteMSGViewController, onFlyedPlane plane: PaperAirplane) {
        self.navigationController?.popViewControllerAnimated(true)
        self.delegate?.paperAirplaneDetailViewController(self, plane: plane, isFlyOut: true)
    }
}

//MARK:UITableViewDelegate
extension PaperAirplaneDetailViewController:UITableViewDataSource,UITableViewDelegate{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return paperAirplane == nil ? 0 : 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paperAirplane.msgs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PaperAirplaneMessageCell.reuseId, forIndexPath: indexPath) as! PaperAirplaneMessageCell
        cell.message = paperAirplane.msgs[indexPath.row]
        cell.updateCell()
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let c = cell as? PaperAirplaneMessageCell{
            c.updateImages()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PaperAirplaneMessageCell,let msg = cell.message{
            cell.selected = false
            ConversationViewController.showConversationViewController(self.navigationController!, userId: msg.usrId, beforeRemoveTs: 1000 * 60 * 60 * 6, createByActivityId: PaperAirplaneActivityId, initMessage: nil)
        }
    }
}

extension PaperAirplaneDetailViewController{
    static func showDetailViewController(nvc:UINavigationController,plane:PaperAirplane,delegate:PaperAirplaneDetailViewControllerDelegate? = nil) -> PaperAirplaneDetailViewController{
        let controller = instanceFromStoryBoard("PaperAirplane", identifier: "PaperAirplaneDetailViewController") as! PaperAirplaneDetailViewController
        controller.paperAirplane = plane
        controller.delegate = delegate
        nvc.pushViewController(controller, animated: true)
        return controller
    }
}
