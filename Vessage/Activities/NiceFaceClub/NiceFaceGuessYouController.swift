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
    static let audioSwipe:NSURL = {
        NSBundle.mainBundle().URLForResource("nfc_swipe", withExtension: "wav")!
    }()
    static let audioBingo:NSURL = {
        NSBundle.mainBundle().URLForResource("nfc_bingo", withExtension: "wav")!
    }()
    
    static let audioError:NSURL = {
        NSBundle.mainBundle().URLForResource("nfc_error", withExtension: "wav")!
    }()
    
    let leftAnswerColor = UIColor.orangeColor()
    let rightAnswerColor = UIColor.purpleColor()
    
    @IBOutlet weak var limitedTimesLabel: UILabel!{
        didSet{
            limitedTimesLabel.hidden = true
        }
    }
    
    @IBOutlet weak var leftAnswerLabel: UILabel!{
        didSet{
            leftAnswerLabel.layoutIfNeeded()
            leftAnswerLabel.hidden = true
            leftAnswerLabel.backgroundColor = leftAnswerColor
            leftAnswerLabel.clipsToBounds = true
            leftAnswerLabel.layer.cornerRadius = leftAnswerLabel.frame.height / 2
            leftAnswerLabel.userInteractionEnabled = true
            leftAnswerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.tapLeftAnswer(_:))))
            leftAnswerLabel.layer.borderColor = leftAnswerColor.CGColor
            leftAnswerLabel.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var rightAnswerLabel: UILabel!{
        didSet{
            rightAnswerLabel.layoutIfNeeded()
            rightAnswerLabel.hidden = true
            rightAnswerLabel.backgroundColor = rightAnswerColor
            rightAnswerLabel.clipsToBounds = true
            rightAnswerLabel.layer.cornerRadius = rightAnswerLabel.frame.height / 2
            rightAnswerLabel.userInteractionEnabled = true
            rightAnswerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.tapRightAnswer(_:))))
            rightAnswerLabel.layer.borderColor = rightAnswerColor.CGColor
            rightAnswerLabel.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            self.tableView.hidden = true
        }
    }
    
    @IBOutlet weak var puzzleLabel: UILabel!{
        didSet{
            puzzleLabel.layoutIfNeeded()
            puzzleLabel.text = nil
            puzzleLabel.layer.cornerRadius = puzzleLabel.frame.height / 2
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
                self.tableView.hidden = self.profile.score < NiceFaceClubManager.minScore
                
                if isShowingMyProfile {
                    self.currentPuzzleIndex = 0
                    if self.profile.score >= NiceFaceClubManager.minScore {
                        if NiceFaceClubManager.instance.loadMemberProfileLimitedTimes > 0 {
                            flashTipsLabel(" \("PULL_TO_LOAD_OTHER_PROFILE".niceFaceClubString)   ")
                        }
                        self.tableView.reloadData()
                    }
                }else {
                    self.puzzles = self.profile.getGuessPuzzles().messArrayUp()
                    self.selectedAnswer.removeAll()
                    self.currentPuzzleIndex = 0
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Bottom)
                    if !UserSetting.isSettingEnable("NFC_GUESS_PLAY_SHOWN_KEY"){
                        UserSetting.enableSetting("NFC_GUESS_PLAY_SHOWN_KEY")
                        self.showAlert("GUESS_PLAY_TIPS_TITLE".niceFaceClubString, msg: "GUESS_PLAY_TIPS".niceFaceClubString)
                    }
                    if !swipeTipsShown{
                        flashTipsLabel("SELECT_ANSWER_TIPS".niceFaceClubString)
                        swipeTipsShown = true
                    }
                }
            }
        }
    }
    private var puzzles:[GuessPuzzle]!
    
    private var isShowingMyProfile:Bool{
        return profile != nil && myProfile != nil && profile.id == myProfile.id
    }
    
    private var swipeTipsShown = false
    private var showLoadMordTipsTimes = 0
    
    private var currentPuzzleIndex = 0{
        didSet{
            leftAnswerLabel?.hidden = currentPuzzle == nil || isShowingMyProfile
            rightAnswerLabel?.hidden = currentPuzzle == nil || isShowingMyProfile
            self.puzzleLabel?.text = nil
            self.puzzleLabel?.layer.borderWidth = 0
            if isShowingMyProfile {
                puzzleLabel?.text = " "
            }else if currentPuzzle != nil {
                puzzleLabel?.text = currentPuzzle.question
                loadPuzzle()
            }
        }
    }
    private var currentPuzzle:GuessPuzzle!{
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
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.tapView(_:)))
        self.view.addGestureRecognizer(tapGes)
        let swipeLeftGes = UISwipeGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.swipeLeft(_:)))
        let swipeRightGes = UISwipeGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.swipeRight(_:)))
        let swipeDownGes = UISwipeGestureRecognizer(target: self, action: #selector(NiceFaceGuessYouController.swipeDown(_:)))
        swipeLeftGes.direction = .Left
        swipeRightGes.direction = .Right
        swipeDownGes.direction = .Down
        self.view.addGestureRecognizer(swipeLeftGes)
        self.view.addGestureRecognizer(swipeRightGes)
        self.view.addGestureRecognizer(swipeDownGes)
        refreshLimitedTimesLabel()
    }
    
    private func refreshLimitedTimesLabel() {
        let times = NiceFaceClubManager.instance.loadMemberProfileLimitedTimes
        if times > 0 {
            self.limitedTimesLabel?.text = String(format: "TODAY_LEFT_LOAD_MP_X_TIMES".niceFaceClubString, "\(times)")
        }else if NiceFaceClubManager.instance.canShareAddTimes{
            self.limitedTimesLabel?.text = "SWIPE_DOWN_TO_SHARE_ADD_LOAD_MP_TIMES".niceFaceClubString
        }else{
            self.limitedTimesLabel?.text = "TODAY_NO_LEFT_LOAD_MP_TIMES".niceFaceClubString
            
        }
    }
    
    private func showBenchMarkAlert() {
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
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        hideNavBar()
        initMyProfile()
    }
    
    private func hideNavBar(delay:UInt64=1000){
        dispatch_main_queue_after(delay) {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    private func initMyProfile(){
        let hud = self.showAnimationHud()
        NiceFaceClubManager.instance.getMyNiceFaceProfile({ (mp) in
            hud.hideAnimated(true)
            if let p = mp{
                self.profile = p
                if p.score < NiceFaceClubManager.minScore{
                    self.showBenchMarkAlert()
                }else{
                    self.limitedTimesLabel.hidden = false
                }
            }else{
                let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                    self.navigationController?.popViewControllerAnimated(true)
                })
                self.showAlert("NICE_FACE_CLUB".niceFaceClubString, msg: "FETCH_YOUR_PROFILE_ERROR".niceFaceClubString, actions: [ok])
            }
        })
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
        let y = self.tableView.frame.origin.y + self.tableView.frame.height + 13
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
            self.updateMemberPuzzles()
        }
        modifyPuzzleAnswer.setValue(UIImage(named: "nice_face_puzzle")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        
        let modifySex = UIAlertAction(title: "MODIFY_SEX".niceFaceClubString, style: .Default) { (ac) in
            self.modifySex()
        }
        modifySex.setValue(UIImage(named: "nice_face_sex")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        
        let userSettig = UIAlertAction(title: "USER_SETTING".niceFaceClubString, style: .Default) { (ac) in
            UserSettingViewController.showUserSettingViewController(self.navigationController!)
        }
        userSettig.setValue(UIImage(named: "nfc_user_setting")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        
        let alert = UIAlertController(title: "NICE_FACE_MEMBER".niceFaceClubString, message: "UPDATE_MEMBER_PROFILE".niceFaceClubString, preferredStyle: .ActionSheet)
        alert.addAction(modifyNiceFace)
        alert.addAction(modifyPuzzleAnswer)
        alert.addAction(modifySex)
        alert.addAction(userSettig)
        alert.addAction(ALERT_ACTION_CANCEL)
        self.showAlert(alert)
    }
    
    private func updateMemberPuzzles(){
        SetupNFCPuzzleViewController.showSetupNFCPuzzleController(self.navigationController!, puzzles: self.myProfile.getMemberPuzzle())
    }
    
    private func modifyNiceFace(aleadyMember:Bool = true){
        let controller = SetupNiceFaceViewController.instanceFromStoryBoard()
        self.presentViewController(controller, animated: true){
            if aleadyMember{
                NFCMessageAlert.showNFCMessageAlert(controller, title: "NICE_FACE_CLUB".niceFaceClubString, message: "UPDATE_YOUR_NICE_FACE".niceFaceClubString)
            }
        }
    }
    
    private func modifySex() {
        NFCSexAlertController.showNFCSexAlert(self)
    }
    
    func tapView(ges:UITapGestureRecognizer)  {
        let point = ges.locationInView(self.view)
        if point.y < self.view.frame.height * 0.36 {
            self.navigationController?.setNavigationBarHidden(!self.navigationController!.navigationBarHidden, animated: true)
        }
    }
    
    func swipeDown(ges:UIGestureRecognizer)  {
        hideNavBar(0)
        nextProfile()
    }
    
    func swipeLeft(ges:UIGestureRecognizer)  {
        tapLeftAnswer(ges)
    }
    
    func swipeRight(ges:UIGestureRecognizer)  {
        tapRightAnswer(ges)
    }
    
    func tapLeftAnswer(ges:UIGestureRecognizer) {
        selectAnswer(true, view: self.leftAnswerLabel)
    }
    
    func tapRightAnswer(ges:UIGestureRecognizer) {
        selectAnswer(false, view: self.rightAnswerLabel)
    }
    
    private func selectAnswer(left:Bool,view:UIView){
        hideNavBar(0)
        if isShowingMyProfile {
            return
        }
        if let cp = currentPuzzle {
            self.playSwipeAudio()
            view.animationMaxToMin(0.1, maxScale: 1.6, completion: {
                self.selectedAnswer.append(left ? cp.leftAnswer:cp.rightAnswer)
                self.nextPuzzle()
            })
        }
    }
    
    private func playSwipeAudio() {
        SystemSoundHelper.playSound(NiceFaceGuessYouController.audioSwipe)
    }
    
    private func nextProfile(){
        if NiceFaceClubManager.instance.needSetMemberPuzzle {
            showNeedSetPuzzleAlert()
        }else if profiles.count <= 1 {
            tryShowInviteAddTimesAlert()
            loadMoreProfiles()
        }else{
            if let p = self.profile {
                let readedProfile = profiles.removeElement{$0.id == p.id}
                PersistentManager.sharedInstance.removeModels(readedProfile)
            }
            setProfile(profiles.first!)
        }
    }
    
    private func setProfile(p:UserNiceFaceProfile){
        if self.profile.id == self.myProfile.id {
            self.profile = p
        }else if NiceFaceClubManager.instance.useLoadMemberProfileOnec() {
            self.profile = p
            self.playSwipeAudio()
        }else{
            self.tryShowInviteAddTimesAlert()
        }
        refreshLimitedTimesLabel()
    }
    
    private func tryShowInviteAddTimesAlert() -> Bool{
        if NiceFaceClubManager.instance.loadMemberProfileLimitedTimes == 0 && NiceFaceClubManager.instance.canShareAddTimes{
            let alert = NFCShareAlert.showNFCShareAlert(self, title: "SHARE_ADD_MP_TIMES_TITLE".niceFaceClubString, message: "SHARE_ADD_MP_TIMES_MSG".niceFaceClubString)
            alert.onSharedHandler = { alert in
                NiceFaceClubManager.instance.addLoadMemberTimes(10)
                NiceFaceClubManager.instance.setTodaySharedAddTimes()
                self.refreshLimitedTimesLabel()
            }
        }
        return false
    }
    
    private func showNeedSetPuzzleAlert(){
        let alert = NFCMessageAlert.showNFCMessageAlert(self, title: "CONTINUE_AFTER_SET_PUZZLE".niceFaceClubString, message: "CONTINUE_AFTER_SET_PUZZLE_MSG".niceFaceClubString)
        alert.shareTipsLabel.text = "PASS_SHARE_TIPS".niceFaceClubString
        alert.continueButton.setImage(UIImage(named: "nice_face_puzzle"), forState: .Normal)
        alert.continueButton.setTitle("SET_PUZZLE".niceFaceClubString, forState: .Normal)
        alert.shareButton.setTitle("INVITE_FRIENDS".niceFaceClubString, forState: .Normal)
        alert.onTestScoreHandler = { alt in
            alt.dismissViewControllerAnimated(true, completion: {
                self.updateMemberPuzzles()
            })
        }
    }
    
    private func loadMoreProfiles() {
        if NiceFaceClubManager.instance.loadMemberProfileLimitedTimes <= 0 {
            return
        }
        let hud = self.showAnimationHud()
        NiceFaceClubManager.instance.loadProfiles({ (profiles) in
            hud.hideAnimated(true)
            if profiles.count > 0{
                PersistentManager.sharedInstance.removeModels(self.profiles)
                self.profiles = profiles
                self.setProfile(self.profiles.first!)
            }else{
                NFCShareAlert.showNFCShareAlert(self, title: "NO_MORE_MEMBER_PROFILES".niceFaceClubString, message: "NO_MORE_MEMBER_PROFILES_MSG".niceFaceClubString)
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
        puzzleLabel.text = selectedAnswer.filter{!$0.hasBegin("#")}.joinWithSeparator("")
        if let colorHex = (selectedAnswer.filter{$0.hasBegin("#")}.first){
            let color = UIColor.init(hexString: colorHex)
            puzzleLabel.layer.borderColor = color.CGColor
            puzzleLabel.layer.borderWidth = 2
        }
        let hud = self.showAnimationHud()
        NiceFaceClubManager.instance.guessMember(self.profile.id, answer: selectedAnswer){ res in
            hud.hideAnimated(true)
            if res.pass{
                SystemSoundHelper.playSound(NiceFaceGuessYouController.audioBingo)
                let ok = UIAlertAction(title: "GO_CHAT".niceFaceClubString, style: .Default, handler: { (ac) in
                    ConversationViewController.showConversationViewController(self.navigationController!, userId: res.userId)
                })
                self.showAlert(self.profile.nick, msg: res.msg.niceFaceClubString,actions: [ok])
            }else{
                SystemSoundHelper.playSound(NiceFaceGuessYouController.audioError)
                self.showLoadMordTipsTimes += 1
                if self.showLoadMordTipsTimes < 3 && NiceFaceClubManager.instance.loadMemberProfileLimitedTimes > 0{
                    self.flashTipsLabel(" \("PULL_TO_LOAD_OTHER_PROFILE".niceFaceClubString)   ")
                }
                self.puzzleLabel?.text = " "
                self.puzzleLabel?.layer.borderWidth = 0
                self.puzzleLabel?.text = res.msg
            }
        }
    }
    
    private func loadPuzzle(){
        if let cp = currentPuzzle{
            leftAnswerLabel.text = nil
            rightAnswerLabel.text = nil
            if cp.leftAnswer.hasBegin("#") {
                leftAnswerLabel.text = " "
                leftAnswerLabel.backgroundColor = UIColor(hexString: cp.leftAnswer)
            }else{
                leftAnswerLabel.text = cp.leftAnswer
                leftAnswerLabel.backgroundColor = leftAnswerColor
            }
            
            if cp.rightAnswer.hasBegin("#") {
                rightAnswerLabel.text = " "
                rightAnswerLabel.backgroundColor = UIColor(hexString: cp.rightAnswer)
            }else{
                rightAnswerLabel.text = cp.rightAnswer
                rightAnswerLabel.backgroundColor = rightAnswerColor
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
            flashTipsLabel.layoutIfNeeded()
            flashTipsLabel.clipsToBounds = true
            flashTipsLabel.hidden = true
            flashTipsLabel.layer.cornerRadius = flashTipsLabel.frame.height / 2
            flashTipsLabel.textColor = UIColor.orangeColor()
            flashTipsLabel.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.6)
        }
    }
    
    @IBOutlet weak var faceScoreProgress: UIProgressView!{
        didSet{
            faceScoreProgress.superview?.layoutIfNeeded()
            faceScoreProgress.superview?.clipsToBounds = true
            faceScoreProgress.superview?.layer.cornerRadius = faceScoreProgress.superview!.frame.height / 2
        }
    }
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var faceScoreLabel: UILabel!
    weak var rootController:NiceFaceGuessYouController!
    func updateCell() {
        likeButton?.hidden = true
        dislikeButton?.hidden = true
        flashTipsLabel?.hidden = true
        if let p = self.profile {
            faceScoreProgress?.setProgress(p.score / 10, animated: true)
            faceScoreLabel?.text = "\(p.score)"
            let hud = rootController?.showAnimationHud()
            ServiceContainer.getFileService().setAvatar(self.faceImageView, iconFileId: p.faceId){ suc in
                hud?.hideAnimated(true)
            }
        }
        
    }
    
    @IBAction func dislike(sender: AnyObject) {
        NiceFaceClubManager.instance.dislikeMember(self.profile.id)
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
        NiceFaceClubManager.instance.likeMember(self.profile.id)
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
        cell.rootController = self
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.height
    }
}
