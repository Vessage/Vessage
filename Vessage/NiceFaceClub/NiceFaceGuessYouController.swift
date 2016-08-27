//
//  NiceFaceGuessYouController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import LTMorphingLabel
import MJRefresh

class NiceFaceGuessYouController: UIViewController {
    
    @IBOutlet weak var leftAnswerLabel: LTMorphingLabel!{
        didSet{
            leftAnswerLabel.hidden = true
            leftAnswerLabel.morphingEffect = .Evaporate
            leftAnswerLabel.backgroundColor = UIColor.orangeColor()
            leftAnswerLabel.clipsToBounds = true
            leftAnswerLabel.layer.cornerRadius = leftAnswerLabel.frame.height / 2
            leftAnswerLabel.userInteractionEnabled = true
            leftAnswerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.tapLeftAnswer(_:))))
        }
    }
    @IBOutlet weak var rightAnswerLabel: LTMorphingLabel!{
        didSet{
            rightAnswerLabel.hidden = true
            rightAnswerLabel.morphingEffect = .Evaporate
            rightAnswerLabel.backgroundColor = UIColor.purpleColor()
            rightAnswerLabel.clipsToBounds = true
            rightAnswerLabel.layer.cornerRadius = rightAnswerLabel.frame.height / 2
            rightAnswerLabel.userInteractionEnabled = true
            rightAnswerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.tapRightAnswer(_:))))
        }
    }
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            self.tableView.hidden = true
        }
    }
    
    @IBOutlet weak var puzzleLabel: LTMorphingLabel!{
        didSet{
            puzzleLabel.text = nil
            puzzleLabel.morphingEffect = .Sparkle
        }
    }
    
    private var tipsLabel:UILabel!{
        didSet{
            tipsLabel.text = nil
            tipsLabel.clipsToBounds = true
            tipsLabel.layer.cornerRadius = 8
            tipsLabel.textColor = UIColor.orangeColor()
            tipsLabel.textAlignment = .Center
            tipsLabel.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.6)
        }
    }
    private var myProfile:UserNiceFaceProfile!{
        return NiceFaceClubManager.instance.myNiceFaceProfile
    }
    private var profiles = [UserNiceFaceProfile]()
    private var profile:UserNiceFaceProfile!{
        didSet{
            if profile != nil {
                self.tableView.hidden = false
                self.puzzles = self.profile.getPuzzles().getRandomSubArray(3)
                self.currentPuzzleIndex = 0
                self.selectedAnswer.removeAll()
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Bottom)
                if isShowingMyProfile {
                    flashTipsLabel(" \("PULL_TO_LOAD_OTHER_PROFILE".niceFaceClubString)   ")
                }else if !swipeTipsShown{
                    flashTipsLabel("SELECT_ANSWER_TIPS".niceFaceClubString)
                    swipeTipsShown = true
                }
            }
        }
    }
    private var puzzles:[GuessYouPuzzle]!{
        didSet{
            tableView?.reloadData()
        }
    }
    
    private var isShowingMyProfile:Bool{
        return profile != nil && myProfile != nil && profile.profileId == myProfile.profileId
    }
    
    private var swipeTipsShown = false
    
    private var currentPuzzleIndex = 0{
        didSet{
            leftAnswerLabel?.hidden = currentPuzzle == nil || isShowingMyProfile
            rightAnswerLabel?.hidden = currentPuzzle == nil || isShowingMyProfile
            self.puzzleLabel?.text = nil
            if isShowingMyProfile {
                puzzleLabel?.text = nil
            }else if self.profile?.sex > 0{
                puzzleLabel?.text = "HE_LIKES".niceFaceClubString
            }else if self.profile?.sex < 0{
                puzzleLabel?.text = "SHE_LIKES".niceFaceClubString
            }else{
                puzzleLabel?.text = "TA_LIKES".niceFaceClubString
            }
            if currentPuzzle != nil {
                loadPuzzle()
            }
        }
    }
    private var currentPuzzle:GuessYouPuzzle!{
        if currentPuzzleIndex < puzzles?.count{
            return self.puzzles[currentPuzzleIndex]
        }
        return nil
    }
    private var selectedAnswer = [String]()
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
}

extension NiceFaceGuessYouController{
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(NiceFaceGuessYouController.onPullTableView(_:)))
        header.setTitle("PULL_TO_NEXT_PROFILE".niceFaceClubString, forState: .Idle)
        header.setTitle("PULL_TO_NEXT_PROFILE".niceFaceClubString, forState: .Pulling)
        header.setTitle("LOADING_OTHER_MEMBER".niceFaceClubString, forState: .Refreshing)
        header.setTitle("PULL_TO_NEXT_PROFILE".niceFaceClubString, forState: .WillRefresh)
        header.lastUpdatedTimeLabel.hidden = true
        tableView.mj_header = header
        let swipeLeftGes = UISwipeGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.swipeLeft(_:)))
        let swipeRightGes = UISwipeGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.swipeRight(_:)))
        swipeLeftGes.direction = .Left
        swipeRightGes.direction = .Right
        self.view.addGestureRecognizer(swipeLeftGes)
        self.view.addGestureRecognizer(swipeRightGes)
    }
    
    func showBenchMarkAlert() {
        let alert = NFCMessageAlert.showNFCMessageAlert(self, title: "NICE_FACE_CLUB".niceFaceClubString, message: "YOU_NEED_FACE_BENCHMARK".niceFaceClubString)
        alert.onTestScoreHandler = { alert in
            alert.dismissViewControllerAnimated(true, completion: {
                self.modifyNiceFace(false)
            })
        }
        alert.onCloseHandler = { alert in
            alert.dismissViewControllerAnimated(true, completion: { 
                self.navigationController?.popViewControllerAnimated(true)
            })
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.hidesBarsOnTap = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        hideNavBar()
        initMyProfile()
    }
    
    private func hideNavBar(){
        self.navigationController?.hidesBarsOnTap = true
        dispatch_main_queue_after(1000) {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    private func initMyProfile(){
        if NiceFaceClubManager.instance.refreshCachedMyFaceProfile() == nil{
            let hud = self.showAnimationHud()
            NiceFaceClubManager.instance.getMyNiceFaceProfile({ (mp) in
                hud.hide(true)
                if let p = mp{
                    self.profile = p
                    if p.score < NiceFaceClubManager.minScore{
                        self.showBenchMarkAlert()
                    }
                }else{
                    let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                    self.showAlert("NICE_FACE_CLUB".niceFaceClubString, msg: "FETCH_YOUR_PROFILE_ERROR".niceFaceClubString, actions: [ok])
                }
            })
        }else if myProfile.score < NiceFaceClubManager.minScore{
            self.showBenchMarkAlert()
        }else if profile == nil{
            profile = myProfile
        }
    }
}

extension NiceFaceGuessYouController{
    
    private func flashTipsLabel(msg:String){
    
        if tipsLabel == nil {
            tipsLabel = UILabel()
        }
        self.tipsLabel.text = msg
        self.tipsLabel.sizeToFit()
        let x = self.view.frame.width / 2
        let y = self.tableView.frame.origin.y + self.tableView.frame.height + 16
        self.tipsLabel.center = CGPointMake(x, y)
        self.view.addSubview(self.tipsLabel)
        UIAnimationHelper.flashView(self.tipsLabel, duration: 0.6, autoStop: true, stopAfterMs: 3600){
            self.tipsLabel.removeFromSuperview()
        }
    }
    
    @IBAction func onClickProfile(sender: AnyObject) {
        let modifyNiceFace = UIAlertAction(title: "MODIFY_NICE_FACE".niceFaceClubString, style: .Default) { (ac) in
            self.modifyNiceFace()
        }
        modifyNiceFace.setValue(UIImage(named: "nice_face_face")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        
        let modifyPuzzleAnswer = UIAlertAction(title: "MODIFY_PUZZLE_ANSWER".niceFaceClubString, style: .Default) { (ac) in
        }
        modifyPuzzleAnswer.setValue(UIImage(named: "nice_face_puzzle")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        
        let modifySex = UIAlertAction(title: "MODIFY_SEX".niceFaceClubString, style: .Default) { (ac) in
            self.modifySex()
        }
        modifySex.setValue(UIImage(named: "nice_face_sex")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        
        let alert = UIAlertController(title: "NICE_FACE_MEMBER".niceFaceClubString, message: "UPDATE_MEMBER_PROFILE".niceFaceClubString, preferredStyle: .ActionSheet)
        alert.addAction(modifyNiceFace)
        alert.addAction(modifyPuzzleAnswer)
        alert.addAction(modifySex)
        alert.addAction(ALERT_ACTION_CANCEL)
        self.showAlert(alert)
    }
    
    private func modifyNiceFace(aleadyMember:Bool = true){
        let controller = SetupNiceFaceViewController.instanceFromStoryBoard("NiceFaceClub", identifier: "SetupNiceFaceViewController")
        self.presentViewController(controller, animated: true){
            if aleadyMember{
                NFCMessageAlert.showNFCMessageAlert(controller, title: "NICE_FACE_CLUB".niceFaceClubString, message: "UPDATE_YOUR_NICE_FACE".niceFaceClubString)
            }
        }
    }
    
    private func modifySex() {
        UserSexValueViewController.showUserProfileViewController(self, sexValue: ServiceContainer.getUserService().myProfile.sex){ newValue in
            let hud = self.showAnimationHud()
            ServiceContainer.getUserService().setUserSexValue(newValue){ suc in
                hud.hide(true)
                if suc{
                    self.playCheckMark("EDIT_SEX_VALUE_SUC".localizedString()){
                    }
                }else{
                    self.playCrossMark("EDIT_SEX_VALUE_ERROR".localizedString())
                }
            }
        }
    }
    
    func onPullTableView(sender:AnyObject) {
        nextProfile()
    }
    
    func swipeDown(ges:UISwipeGestureRecognizer)  {
        
    }
    
    func swipeLeft(ges:UITapGestureRecognizer)  {
        tapLeftAnswer(ges)
    }
    
    func swipeRight(ges:UITapGestureRecognizer)  {
        tapRightAnswer(ges)
    }
    
    func tapLeftAnswer(ges:UITapGestureRecognizer) {
        if isShowingMyProfile {
            return
        }
        if let cp = currentPuzzle {
            SystemSoundHelper.keyTink()
            leftAnswerLabel.animationMaxToMin(0.1, maxScale: 1.2, completion: {
                self.selectedAnswer.append(cp.leftAnswer)
                self.nextPuzzle()
            })
        }
    }
    
    func tapRightAnswer(ges:UITapGestureRecognizer) {
        if isShowingMyProfile {
            return
        }
        if let cp = currentPuzzle {
            SystemSoundHelper.keyTink()
            rightAnswerLabel.animationMaxToMin(0.1, maxScale: 1.2, completion: {
                self.selectedAnswer.append(cp.rightAnswer)
                self.nextPuzzle()
            })
        }
    }
    
    private func nextProfile(){
        if profiles.count <= 1 {
            loadMoreProfiles()
        }else if self.profiles.count > 1{
            if let p = self.profile {
                profiles.removeElement{$0.profileId == p.profileId}
            }
        }
        if profiles.count > 0 {
            self.profile = profiles[random() % profiles.count]
            self.tableView?.mj_header.endRefreshing()
        }else{
            loadMoreProfiles()
        }
    }
    
    private func loadMoreProfiles() {
        let hud = self.showAnimationHud()
        NiceFaceClubManager.instance.loadProfiles({ (profiles) in
            hud.hide(true)
            self.tableView?.mj_header.endRefreshing()
            if profiles.count > 0{
                self.profiles.appendContentsOf(profiles)
                self.profile = self.profiles[random() % profiles.count]
            }
        })
    }
    
    private func nextPuzzle(){
        currentPuzzleIndex += 1
        if currentPuzzleIndex == puzzles.count {
            finishAnswer()
        }else{
            loadPuzzle()
        }
    }
    
    private func finishAnswer(){
        puzzleLabel.text = selectedAnswer.joinWithSeparator("")
        let hud = self.showAnimationHud()
        NiceFaceClubManager.instance.guessMember(self.profile.profileId, answer: selectedAnswer){ res in
            hud.hide(true)
            if res.pass{
                let ok = UIAlertAction(title: "GO_CHAT".niceFaceClubString, style: .Default, handler: { (ac) in
                    ConversationViewController.showConversationViewController(self.navigationController!, userId: res.memberUserId)
                })
                self.showAlert(self.profile.nick, msg: "YOU_GUESS_ME".niceFaceClubString,actions: [ok])
            }else{
                let oo = UIAlertAction(title: "OO".niceFaceClubString, style: .Cancel, handler: nil)
                self.showAlert(self.profile.nick, msg: "YOU_NOT_GUESS_ME".niceFaceClubString,actions: [oo])
            }
        }
    }
    
    private func loadPuzzle(){
        if let cp = currentPuzzle{
            leftAnswerLabel.text = nil
            rightAnswerLabel.text = nil
            if cp.leftAnswer.hasBegin("#") {
                leftAnswerLabel.backgroundColor = UIColor(hexString: cp.leftAnswer)
            }else{
                leftAnswerLabel.text = cp.leftAnswer
                leftAnswerLabel.backgroundColor = UIColor.orangeColor()
            }
            
            if cp.rightAnswer.hasBegin("#") {
                rightAnswerLabel.backgroundColor = UIColor(hexString: cp.rightAnswer)
            }else{
                rightAnswerLabel.text = cp.rightAnswer
                rightAnswerLabel.backgroundColor = UIColor.redColor()
            }
        }
    }
    
}

class NiceFaceImageCell: UITableViewCell {
    static let reuseId = "NiceFaceImageCell"
    weak var profile:UserNiceFaceProfile!{
        didSet{
            updateCell()
        }
    }
    
    @IBOutlet weak var flashTipsLabel: UILabel!{
        didSet{
            flashTipsLabel.clipsToBounds = true
            flashTipsLabel.hidden = true
            flashTipsLabel.layer.cornerRadius = flashTipsLabel.frame.height / 2
            flashTipsLabel.textColor = UIColor.orangeColor()
            flashTipsLabel.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.6)
        }
    }
    
    @IBOutlet weak var faceScoreProgress: UIProgressView!{
        didSet{
            faceScoreProgress.superview?.clipsToBounds = true
            faceScoreProgress.superview?.layer.cornerRadius = faceScoreProgress.superview!.frame.height / 2
        }
    }
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var faceScoreLabel: UILabel!
    
    func updateCell() {
        likeButton?.hidden = true
        dislikeButton?.hidden = true
        flashTipsLabel?.hidden = true
        if let p = self.profile {
            faceScoreProgress?.setProgress(p.score / 10, animated: true)
            faceScoreLabel?.text = "\(p.score)"
            ServiceContainer.getFileService().setAvatar(self.faceImageView, iconFileId: p.faceImage)
        }
        
    }
    
    @IBAction func dislike(sender: AnyObject) {
        NiceFaceClubManager.instance.dislikeMember(self.profile.profileId)
        likeButton.hidden = true
        dislikeButton.hidden = true
        flashTipsLabel.text = "PROFILE_NICE_DOWN".niceFaceClubString
        startFlashTipsLabel()
    }
    
    private func startFlashTipsLabel(){
        flashTipsLabel.hidden = false
        UIAnimationHelper.flashView(flashTipsLabel, duration: 0.6, autoStop: true, stopAfterMs: 1800) {
            self.flashTipsLabel.hidden = true
        }
    }
    
    @IBAction func like(sender: AnyObject) {
        NiceFaceClubManager.instance.likeMember(self.profile.profileId)
        likeButton.hidden = true
        dislikeButton.hidden = true
        flashTipsLabel.text = "PROFILE_NICE_UP".niceFaceClubString
        startFlashTipsLabel()
    }
    
}

extension NiceFaceGuessYouController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profile == nil ? 0 : 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NiceFaceImageCell.reuseId, forIndexPath: indexPath) as! NiceFaceImageCell
        cell.profile = self.profile
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.height
    }
}