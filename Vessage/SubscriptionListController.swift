//
//  SubscriptionListController.swift
//  Vessage
//
//  Created by Alex Chow on 2017/3/20.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation


typealias OnClickSubscriptionHandler = ((cell:SubscriptionListCell)->Void)

class SubscriptionListCell:UITableViewCell{
    @IBOutlet weak var icon: UIImageView!{
        didSet{
            icon.layer.cornerRadius = 10
            icon.clipsToBounds = true
        }
    }
    @IBOutlet weak var headline: UILabel!
    @IBOutlet weak var subline: UILabel!
    @IBOutlet weak var subscriptBtn: UIButton!
    
    var model:SubAccount!
    
    var onClickSubscriptonHandler:OnClickSubscriptionHandler?
    
    static let reuesId = "SubscriptionListCell"
    
    var subscripted = false{
        didSet{
            subscriptBtn?.enabled = !subscripted
        }
    }
    
    @IBAction func onClickSubsciptionBtn(sender: AnyObject) {
        onClickSubscriptonHandler?(cell: self)
    }
}

class SubscriptionListController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let defaultIcon = UIImage(named: "nav_subaccount_icon")
    private var data = [SubAccount]()
    private let conversationService = ServiceContainer.getConversationService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if data.count == 0 {
            ServiceContainer.getSubscriptionService().getOnlineSubscriptionAccounts { (result) in
                if let arr = result{
                    self.data.appendContentsOf(arr)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    static func showSubscriptioList(nav:UINavigationController) -> SubscriptionListController{
        let c = instanceFromStoryBoard("Subscription", identifier: "SubscriptionListController") as! SubscriptionListController
        nav.pushViewController(c, animated: true)
        return c
    }
}

private var snsIndex:NSIndexPath?

extension SubscriptionListController:UITableViewDataSource,UITableViewDelegate{
    func onClickSubscription(cell:SubscriptionListCell) {
        ServiceContainer.getConversationService().openConversationByUserId(cell.model.id, beforeRemoveTs: ConversationMaxTimeUpMS, createByActivityId: nil, type: Conversation.typeSubscription)
        ServiceContainer.getActivityService().setActivityMiniBadgeShow(SNSPostManager.activityId)
        cell.subscripted = true
    }
    
    func onSubscriptOnSNS(a:UIBarButtonItem) {
        if let index = snsIndex,let cell = self.tableView?.cellForRowAtIndexPath(index) as? SubscriptionListCell{
            onClickSubscription(cell)
            a.title = "SUBSCRIPTED".localizedString()
            a.enabled = false
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SubscriptionListCell{
            let model = data[indexPath.row]
            let controller = SNSMainViewController.showUserSNSPostViewController(self.navigationController!, userId: model.id, nick: model.title)
            if !cell.subscripted {
                controller.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "SUBSCRIPT".localizedString(), style: .Plain, target: self, action: #selector(SubscriptionListController.onSubscriptOnSNS(_:)))
                snsIndex = indexPath
            }else{
                controller.navigationItem.rightBarButtonItem = nil
                snsIndex = nil
            }
            
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SubscriptionListCell.reuesId, forIndexPath: indexPath) as! SubscriptionListCell
        let model = data[indexPath.row]
        cell.model = model
        cell.headline.text = model.title
        cell.subline.text = model.desc
        cell.onClickSubscriptonHandler = onClickSubscription
        cell.subscripted = conversationService.getConversationWithChatterId(model.id) != nil
        ServiceContainer.getFileService().setImage(cell.icon, iconFileId: model.avatar, defaultImage: defaultIcon, callback: nil)
        return cell
    }
}
