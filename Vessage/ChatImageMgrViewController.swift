//
//  ChatImageMgrViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import LTMorphingLabel

class ChatImageMgrViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    let imageTypes = [
        ["type":"正常","settedMsg":"Test","notSetMsg":"Test"],
        ["type":"逗逼","settedMsg":"Test","notSetMsg":"Test"],
        ["type":"卖萌","settedMsg":"Test","notSetMsg":"Test"],
        ["type":"高兴","settedMsg":"Test","notSetMsg":"Test"],
        ["type":"伤心","settedMsg":"Test","notSetMsg":"Test"],
        ["type":"傲娇","settedMsg":"Test","notSetMsg":"Test"]
    ]

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageTypeLabel: LTMorphingLabel!{
        didSet{
            imageTypeLabel.morphingEffect = .Evaporate
        }
    }
    @IBOutlet weak var pageControl: UIPageControl!
    private var userService = ServiceContainer.getUserService()
    private var index = 0
    private var numOfImages:Int{
        return imageTypes.count + 1
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let dict = [NSForegroundColorAttributeName:UIColor.themeColor]
        self.navigationController?.navigationBar.titleTextAttributes = dict
        tableView.delegate = self
        tableView.dataSource = self
        let leftSwipeGes = UISwipeGestureRecognizer(target: self, action: #selector(ChatImageMgrViewController.onSwipe(_:)))
        leftSwipeGes.direction = .Left
        let rightSwipeGes = UISwipeGestureRecognizer(target: self, action: #selector(ChatImageMgrViewController.onSwipe(_:)))
        rightSwipeGes.direction = .Right
        self.view.addGestureRecognizer(leftSwipeGes)
        self.view.addGestureRecognizer(rightSwipeGes)
        self.pageControl.numberOfPages = numOfImages
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadIndex(index, rowAnimation: .Automatic)
    }
    
    func onSwipe(ges:UISwipeGestureRecognizer) {
        if ges.direction == .Left {
            loadIndex(index + 1,rowAnimation: .Left)
        }else if ges.direction == .Right{
            loadIndex(index - 1,rowAnimation: .Right)
        }
    }
    
    private func loadIndex(index:Int,rowAnimation:UITableViewRowAnimation){
        if index >= 0 && index < numOfImages {
            self.index = index
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: rowAnimation)
            pageControl.currentPage = index
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    private var cellBcgImageView = UIImageView()
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatImageCell", forIndexPath: indexPath)

        // Configure the cell...
        let faceImageView = FaceTextImageView()
        cell.contentView.removeAllSubviews()
        cellBcgImageView.image = getRandomConversationBackground()
        cellBcgImageView.frame = cell.contentView.bounds
        cell.contentView.addSubview(cellBcgImageView)
        faceImageView.initContainer(cell.contentView)
        cell.contentView.addSubview(faceImageView)
        if index == 0 {
            self.navigationItem.title = "视频对讲背景"
            faceImageView.setTextImage(userService.myProfile.mainChatImage, message: "设置视频对讲背景，让好友在对讲时可以看到你")
            if userService.isUserChatBackgroundIsSeted {
                self.imageTypeLabel.text = ""
            }else{
                self.imageTypeLabel.text = "未设置"
            }
        }else{
            self.navigationItem.title = "颜文字聊天表情"
            let dict = imageTypes[index - 1]
            self.imageTypeLabel.text = dict["type"]
            faceImageView.setTextImage("", message: dict["settedMsg"])
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.height
    }

    static func showChatImageMgrVeiwController(vc:UIViewController,defaultIndex:Int = 0){
        let controller = instanceFromStoryBoard("User", identifier: "ChatImageMgrViewController") as! ChatImageMgrViewController
        let nvc = UINavigationController(rootViewController: controller)
        controller.index = defaultIndex
        vc.presentViewController(nvc, animated: true, completion: nil)
    }
}
