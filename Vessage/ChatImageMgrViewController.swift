//
//  ChatImageMgrViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/7/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit
import LTMorphingLabel

let defaultImageTypes = [
    ["type":"正常","settedMsg":"蜀黍，我不约😝","notSetMsg":"嗨，约吗？"],
    ["type":"逗逼","settedMsg":"你才是逗逼😊","notSetMsg":"听说聊天时逗逼的人最可爱~"],
    ["type":"卖萌","settedMsg":"感觉全世界萌萌哒~","notSetMsg":"和Ta聊天时可以卖个萌哦😉"],
    ["type":"高兴","settedMsg":"今天不知道为什么，我很嗨心~~~","notSetMsg":"一个高兴表情，把快乐传递给朋友~"],
    ["type":"伤心","settedMsg":"我心里苦，但我不说...","notSetMsg":"☹️"],
    ["type":"傲娇","settedMsg":"哼😏","notSetMsg":"哼😏"]
]

class ChatImageMgrViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,ChatBackgroundPickerControllerDelegate {

    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageTypeLabel: LTMorphingLabel!{
        didSet{
            imageTypeLabel.morphingEffect = .Evaporate
        }
    }
    @IBOutlet weak var pageControl: UIPageControl!
    private var myChatImages = [String:ChatImage]()
    private var userService = ServiceContainer.getUserService()
    private var index = 0
    private var numOfImages:Int{
        return defaultImageTypes.count + 1
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let dict = [NSForegroundColorAttributeName:UIColor.themeColor]
        self.navigationController?.navigationBar.titleTextAttributes = dict
        let leftSwipeGes = UISwipeGestureRecognizer(target: self, action: #selector(ChatImageMgrViewController.onSwipe(_:)))
        leftSwipeGes.direction = .Left
        let rightSwipeGes = UISwipeGestureRecognizer(target: self, action: #selector(ChatImageMgrViewController.onSwipe(_:)))
        rightSwipeGes.direction = .Right
        self.view.addGestureRecognizer(leftSwipeGes)
        self.view.addGestureRecognizer(rightSwipeGes)
        self.pageControl.numberOfPages = numOfImages
        initMyChatImages()
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func initMyChatImages(){
        myChatImages.removeAll()
        if let images = userService.myChatImages{
            images.forEach({ (ci) in
                myChatImages.updateValue(ci, forKey: ci.imageType)
            })
        }
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
            faceImageView.setTextImage(userService.myProfile.mainChatImage, message: "设置你的视频对讲背景，好友对讲时可以看到")
            if userService.isUserChatBackgroundIsSeted {
                self.imageTypeLabel.text = " "
            }else{
                self.imageTypeLabel.text = "未设置"
            }
        }else{
            self.navigationItem.title = "颜文字聊天表情"
            let dict = defaultImageTypes[index - 1]
            if let type = dict["type"]{
                if let ci = self.myChatImages[type] {
                    self.imageTypeLabel.text = type
                    faceImageView.setTextImage(ci.imageId, message: dict["settedMsg"])
                }else{
                    self.imageTypeLabel.text = "\(type)(未设置)"
                    faceImageView.setTextImage("", message: dict["notSetMsg"])
                }
            }
            
        }
        if let chatBubbleMoveGesture = faceImageView.chatBubbleMoveGesture{
            self.view.gestureRecognizers?.forEach{$0.requireGestureRecognizerToFail(chatBubbleMoveGesture)}
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        if index == 0 {
            ChatBackgroundPickerController.showPickerController(self, delegate: self)
        }else{
            ChatBackgroundPickerController.showPickerController(self, delegate: self,imageType: defaultImageTypes[index - 1]["type"])
        }
    }
    
    func chatBackgroundPickerSetedImage(sender: ChatBackgroundPickerController) {
        initMyChatImages()
        sender.dismissViewControllerAnimated(true) {
            self.loadIndex(self.index, rowAnimation: .Automatic)
        }
    }
    
    func chatBackgroundPickerSetImageCancel(sender: ChatBackgroundPickerController) {
        
    }

    static func showChatImageMgrVeiwController(vc:UIViewController,defaultIndex:Int = 0){
        let controller = instanceFromStoryBoard("User", identifier: "ChatImageMgrViewController") as! ChatImageMgrViewController
        let nvc = UINavigationController(rootViewController: controller)
        controller.index = defaultIndex
        vc.presentViewController(nvc, animated: true, completion: nil)
    }
}
