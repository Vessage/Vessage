//
//  SetupNFCPuzzleViewController.swift
//  Vessage
//
//  Created by AlexChow on 16/8/29.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection

class SetupNFCPuzzleViewController: UIViewController {
    let LEAST_PUZZLE = 3
    @IBOutlet weak var tableView: UITableView!
    private var puzzle:MemberPuzzles!
    private var showTips = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.tableView.delegate == nil {
            if self.puzzle == nil {
                if let url = NSBundle.mainBundle().URLForResource("nfc_puzzles", withExtension: "json"){
                    if let json = PersistentFileHelper.readTextFile(url){
                        self.puzzle = MemberPuzzles(json: json)
                        self.showTips = true
                    }
                }
            }
            if self.puzzle == nil {
                self.navigationController?.popViewControllerAnimated(true)
            }
            
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if showTips {
            self.showAlert("NFC_TIPS".niceFaceClubString, msg: "SET_PUZZLE_MESSAGE".niceFaceClubString)
        }
    }
    
    @IBAction func saveMemberPuzzle(sender: AnyObject) {
        if (self.puzzle.puzzles.filter{$0.correct.count > 0}.count) < LEAST_PUZZLE{
            self.playCrossMark(String(format: "AT_LEAST_X_PUZZLES".niceFaceClubString, "\(LEAST_PUZZLE)"))
            return
        }
        
        let hud = self.showAnimationHud()
        NiceFaceClubManager.instance.setUserPuzzle(self.puzzle) { (suc) in
            hud.hideAnimated(true)
            if suc{
                self.playCheckMark("MEMBER_PUZZLE_UPDATED".niceFaceClubString){
                    self.navigationController?.popViewControllerAnimated(true)
                    if NiceFaceClubManager.instance.needSetSex{
                        NFCSexAlertController.showNFCSexAlert(self.navigationController!)
                    }
                }
            }else{
                self.playCrossMark("UPDAT_MEMBER_PUZZLE_ERROR".niceFaceClubString)
            }
        }
    }
    
    static func instanceFromStoryBoard() -> SetupNFCPuzzleViewController{
        return instanceFromStoryBoard("NFCGuess", identifier: "SetupNFCPuzzleViewController") as! SetupNFCPuzzleViewController
    }
    
    static func showSetupNFCPuzzleController(nvc:UINavigationController,puzzles:MemberPuzzles?){
        let controller = instanceFromStoryBoard()
        controller.puzzle = puzzles
        nvc.pushViewController(controller, animated: true)
    }
}

extension SetupNFCPuzzleViewController:UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return puzzle == nil ? 0 : 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.puzzle?.puzzles?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PuzzleCell.reuseId, forIndexPath: indexPath) as! PuzzleCell
        let p = puzzle.puzzles[indexPath.row]
        cell.rootController = self
        cell.puzzleModel = p
        cell.setSeparatorFullWidth()
        return cell
    }
    
}

class PuzzleCell: UITableViewCell {
    static let reuseId = "PuzzleCell"
    weak var rootController:SetupNFCPuzzleViewController!
    @IBOutlet weak var qustionLabel: UILabel!
    @IBOutlet weak var answerCollectionView: UICollectionView!{
        didSet{
            answerCollectionView.allowsMultipleSelection = true
            answerCollectionView.delegate = self
            answerCollectionView.dataSource = self
        }
    }

    var puzzleModel:PuzzleModel!{
        didSet{
            self.qustionLabel.text = puzzleModel.question
            self.answerCollectionView?.reloadData()
        }
    }
    
    
}

extension PuzzleCell:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfItemsInSection > 0 ? 1 : 0
    }
    
    var numberOfItemsInSection:Int{
        return (self.puzzleModel?.correct?.count ?? 0) + (self.puzzleModel?.incorrect?.count ?? 0)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsInSection
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PuzzleAnswerCell.reuseId, forIndexPath: indexPath) as! PuzzleAnswerCell
        if indexPath.row < self.puzzleModel.correct.count {
            cell.answer = self.puzzleModel.correct[indexPath.row]
            cell.setBorder()
        }else{
            cell.answer = self.puzzleModel.incorrect[indexPath.row - self.puzzleModel.correct.count]
            cell.unSetBorder()
        }
        cell.rootCell = self
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if indexPath.row < self.puzzleModel.correct.count {
            return true
        }
        
        if self.puzzleModel.correct.count >= 2 || self.puzzleModel.correct.count >= self.puzzleModel.incorrect.count{
            self.rootController.playToast("CANT_SELECT_MORE".niceFaceClubString)
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.selected = false
        
        var correct = self.puzzleModel.correct
        var incorrect = self.puzzleModel.incorrect
        
        if indexPath.row < self.puzzleModel.correct.count {
            let c = correct.removeAtIndex(indexPath.row)
            incorrect.insert(c, atIndex: 0)
        }else{
            let c = incorrect.removeAtIndex(indexPath.row - correct.count)
            correct.insert(c, atIndex: 0)
        }
        
        self.puzzleModel.correct = correct
        self.puzzleModel.incorrect = incorrect
        collectionView.reloadData()
        collectionView.scrollToItemAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0), atScrollPosition: .Left, animated: true)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(56, 56)
    }
}

class PuzzleAnswerCell: UICollectionViewCell {
    static let reuseId = "PuzzleAnswerCell"
    weak var rootCell:PuzzleCell!
    
    var answer:String!{
        didSet{
            if answer.hasBegin("#") {
                let color = UIColor(hexString:answer)
                answerLabel.text = nil
                answerLabel.backgroundColor = color
            }else{
                answerLabel.backgroundColor = UIColor.clearColor()
                answerLabel.text = answer
            }
        }
    }
    
    func setBorder()  {
        answerLabel.layer.borderColor = UIColor.redColor().CGColor
        answerLabel.layer.borderWidth = 3
    }
    
    func unSetBorder() {
        answerLabel.layer.borderColor = UIColor.orangeColor().CGColor
        answerLabel.layer.borderWidth = 1
    }
    
    @IBOutlet weak var answerLabel: UILabel!{
        didSet{
            answerLabel.layoutIfNeeded()
            answerLabel.clipsToBounds = true
            answerLabel.layer.cornerRadius = self.answerLabel!.frame.height / 2
            answerLabel.layer.borderColor = UIColor.orangeColor().CGColor
            answerLabel.layer.borderWidth = 1
        }
    }
    
    override func layoutSubviews() {
                super.layoutSubviews()
    }
}
