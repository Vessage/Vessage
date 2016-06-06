//
//  LittlePaperMessageListController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/9.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class LittlePaperMessageListCell: UITableViewCell {
    static let reuseId = "LittlePaperMessageListCell"
    var paperMessage:LittlePaperMessage!{
        didSet{
            finishMarkImage.hidden = !paperMessage.isOpened
            messageTitleLabel.text = paperMessage.receiverInfo
            updatedMarkView.hidden = !paperMessage.isUpdated
        }
    }
    @IBOutlet weak var finishMarkImage: UIImageView!
    @IBOutlet weak var messageTitleLabel: UILabel!
    @IBOutlet weak var updatedMarkView: UIView!{
        didSet{
            updatedMarkView.clipsToBounds = true
            updatedMarkView.layer.cornerRadius = 3
        }
    }
}

class LittlePaperMessageListController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var receivedButton: UIButton!
    @IBOutlet weak var postedButton: UIButton!
    @IBOutlet weak var sendedButton: UIButton!
    @IBOutlet weak var openedButton: UIButton!
    
    private var trashButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.backgroundColor = UIColor.clearColor()
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    private var paperListType:Int = 0{
        didSet{
            if tableView != nil{
                tableView.reloadData()
                refreshTableViewFooter()
            }
        }
    }
    
    private var paperMessages:[LittlePaperMessage]!{
        return LittlePaperManager.instance.paperMessagesList.count > paperListType ?
            LittlePaperManager.instance.paperMessagesList[paperListType] : nil
    }

    private var isNothing:Bool{
        return (paperMessages == nil || paperMessages.count == 0)
    }
    
    private let emptyTableViewFooter:UIView = {
        let label = UILabel()
        label.textAlignment = .Center
        label.numberOfLines = 0
        label.textColor = UIColor.darkGrayColor()
        label.backgroundColor = UIColor.clearColor()
        label.text = "NO_PAPER_MESSAGE".littlePaperString
        label.userInteractionEnabled = true
        return label
    }()
    
    private var myProfile:VessageUser!
    
    private let defaultTableViewFooter:UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.clearColor()
        return v
    }()
    
    private func refreshTableViewFooter(){
        if isNothing {
            emptyTableViewFooter.frame = self.tableView.bounds
            tableView.scrollEnabled = false
            tableView.tableFooterView = emptyTableViewFooter
        }else{
            tableView.scrollEnabled = true
            tableView.tableFooterView = defaultTableViewFooter
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        trashButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(LittlePaperMessageListController.onClickTrash(_:)))
        emptyTableViewFooter.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LittlePaperMessageListController.onClickEmptyTableViewFooter(_:))))
        self.myProfile = ServiceContainer.getUserService().myProfile
        onClickReceived()
        emptyTableViewFooter.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setButtonBadges()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        refreshTableViewFooter()
        emptyTableViewFooter.hidden = false
    }
    
    private func setButtonBadges(){
        var cnt = 0
        receivedButton.badgeOriginX = -6
        receivedButton.badgeOriginY = -6
        cnt = LittlePaperManager.instance.myNotDealMessages.count
        receivedButton.badgeValue = cnt > 0 ? "\(cnt)": ""
        
        postedButton.badgeOriginX = -6
        postedButton.badgeOriginY = -6
        cnt = LittlePaperManager.instance.myPostededMessageUpdatedCount
        postedButton.badgeValue = cnt > 0 ? "\(cnt)": ""
        
        sendedButton.badgeOriginX = -6
        sendedButton.badgeOriginY = -6
        cnt = LittlePaperManager.instance.mySendedMessageUpdatedCount
        sendedButton.badgeValue = cnt > 0 ? "\(cnt)": ""
        
        openedButton.badgeOriginX = -6
        openedButton.badgeOriginY = -6
        cnt = LittlePaperManager.instance.myOpenedMessageUpdatedCount
        openedButton.badgeValue = cnt > 0 ? "\(cnt)": ""
    }
    
    //MARK: actions
    
    func onClickTrash(sender: AnyObject) {
        let alertYes = UIAlertAction(title: "YES".littlePaperString, style: .Default, handler: { (ac) in
            LittlePaperManager.instance.clearPaperMessageList(self.paperListType)
            self.paperListType = self.paperListType + 0
        })
        self.showAlert("CORFIRM_CLEAR_ALL_PAPER_MESSAGES".littlePaperString, msg: "CLEAR_ALL_PAPER_MESSAGES_TIPS".littlePaperString, actions: [ALERT_ACTION_CANCEL,alertYes])
    }
    
    func onClickEmptyTableViewFooter(_:UITapGestureRecognizer) {
        WritePaperMessageViewController.showWritePaperMessageViewController(self)
    }
    
    @IBAction func onClickReceived() {
        paperListType = LittlePaperManager.TYPE_MY_NOT_DEAL
        refreshButtons(receivedButton)
    }
    
    @IBAction func onClickPosted() {
        paperListType = LittlePaperManager.TYPE_MY_POSTED
        refreshButtons(postedButton)
    }
    
    @IBAction func onClickOpened() {
        paperListType = LittlePaperManager.TYPE_MY_OPENED
        refreshButtons(openedButton)
    }
    
    @IBAction func onClickSended() {
        paperListType = LittlePaperManager.TYPE_MY_SENDED
        refreshButtons(sendedButton)
    }
    
    private func refreshButtons(clickedButton:UIButton){
        receivedButton.enabled = receivedButton != clickedButton
        postedButton.enabled = postedButton != clickedButton
        openedButton.enabled = openedButton != clickedButton
        sendedButton.enabled = sendedButton != clickedButton
        if receivedButton != clickedButton {
            self.navigationItem.rightBarButtonItem = trashButton
        }else{
            self.navigationItem.rightBarButtonItem = nil
        }
        setButtonBadges()
    }
    
    @IBAction func onClickBack(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: TableView Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let cnt = paperMessages?.count ?? 0
        self.trashButton.enabled = cnt > 0
        return cnt
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LittlePaperMessageListCell.reuseId, forIndexPath: indexPath) as! LittlePaperMessageListCell
        cell.paperMessage = paperMessages[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let msg = paperMessages?[indexPath.row]{
            LittlePaperManager.instance.clearPaperMessageUpdated(paperListType, index: indexPath.row)
            let controller = PaperMessageDetailViewController.showPaperMessageDetailViewController(self.navigationController!)
            controller.paperMessage = msg
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.navigationItem.rightBarButtonItem != nil
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let actionTitle = "REMOVE".littlePaperString
        let action = UITableViewRowAction(style: .Default, title: actionTitle, handler: { (ac, indexPath) -> Void in
            let alertYes = UIAlertAction(title: "YES".littlePaperString, style: .Default, handler: { (ac) in
                LittlePaperManager.instance.removePaperMessage(self.paperListType, index: indexPath.row)
                self.paperListType = self.paperListType + 0
            })
            self.showAlert("CORFIRM_CLEAR_PAPER_MESSAGE".littlePaperString, msg: "CLEAR_ALL_PAPER_MESSAGES_TIPS".littlePaperString, actions: [ALERT_ACTION_CANCEL,alertYes])
        })
        return [action]
    }

    static func showLittlePaperMessageListController(vc:UIViewController){
        let controller = instanceFromStoryBoard("LittlePaperMessage", identifier: "LittlePaperMessageListController")
        let nvc = UINavigationController(rootViewController: controller)
        vc.presentViewController(nvc, animated: true, completion: nil)
    }
}