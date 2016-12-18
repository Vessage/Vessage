//
//  TIMSharePreviewViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/18.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class TIMSharePreviewViewController: UIViewController {

    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet weak var bcgCollectionView: UICollectionView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var maskView: UIView!
    @IBOutlet weak var shareTextContentLabel: UILabel!
    
    var shareTextContent:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bcgCollectionView.allowsMultipleSelection = false
        bcgCollectionView.allowsSelection = true
    }
    
    @IBAction func onClickFont(sender: AnyObject) {
        SelectFontViewController.showSelectFontViewController(self.navigationController!, delegate: self)
    }

    @IBAction func onSliderValueChanged(sender: AnyObject) {
        let newSize = fontSizeSlider.value
        shareTextContentLabel.font = shareTextContentLabel.font.fontWithSize(CGFloat(newSize))
        UserSetting.setUserNumberValue(cachedFontSizeKey, value: NSNumber(float: newSize))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        shareTextContentLabel.text = shareTextContent
        bcgCollectionView.delegate = self
        bcgCollectionView.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let index = UserSetting.getUserIntValue(selectedStyleIndexKey)
        bcgCollectionView.selectItemAtIndexPath(NSIndexPath.init(forRow: index, inSection: 0), animated: true, scrollPosition: .CenteredHorizontally)
        setStyle(index)
        if let fontSize = UserSetting.getUserNumberValue(cachedFontSizeKey){
            fontSizeSlider.setValue(fontSize.floatValue, animated: true)
            shareTextContentLabel.font = shareTextContentLabel.font.fontWithSize(CGFloat(fontSize.floatValue))
        }
    }
}

extension TIMSharePreviewViewController:SelectFontViewControllerDelegate{
    func selectFontViewController(ender: SelectFontViewController, onSelectedFont font: UIFont) {
        let fontSize = self.shareTextContentLabel.font.pointSize
        self.shareTextContentLabel.font = font.fontWithSize(fontSize)
    }
}

private let selectedStyleIndexKey = "TIMselectedStyleKey"
private let cachedFontSizeKey = "TIMFontSizeKey"

private let TIMDefaultStyles = [
    ["bcg":"tim_bcg_0","textColor":"#8D75FF","font":""],
    ["bcg":"tim_bcg_1","textColor":"#DE67FF","font":""],
    ["bcg":"tim_bcg_2","textColor":"#4C4C4C","font":""],
    ["bcg":"tim_bcg_3","textColor":"#ffffff","font":""],
    ["bcg":"tim_bcg_4","textColor":"#02C1FA","font":""],
    ["bcg":"tim_bcg_5","textColor":"#CACACA","font":""],
    ["bcg":"tim_bcg_6","textColor":"#ffffff","font":""],
    ["bcg":"tim_bcg_7","textColor":"#ffffff","font":""],
]

extension TIMSharePreviewViewController:UICollectionViewDelegate,UICollectionViewDataSource{
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return TIMDefaultStyles.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TIMBackgroundItemCell.reuseId, forIndexPath: indexPath) as! TIMBackgroundItemCell
        cell.imageView.image = UIImage(named: TIMDefaultStyles[indexPath.row]["bcg"]!)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        UserSetting.setUserIntValue(selectedStyleIndexKey, value: indexPath.row)
        setStyle(indexPath.row)
    }
    
    func setStyle(index:Int) {
        if index >= 0 && index < TIMDefaultStyles.count {
            let dict = TIMDefaultStyles[index]
            if let imgName = dict["bcg"],let img = UIImage(named:imgName){
                backgroundImage.image = img
            }
            if let textColor = dict["textColor"]{
                shareTextContentLabel.textColor = UIColor(hexString: textColor)
            }
        }
    }
}

class TIMBackgroundItemCell: UICollectionViewCell {
    static let reuseId = "TIMBackgroundItemCell"
    @IBOutlet weak var imageView: UIImageView!
    override var selected: Bool{
        didSet{
            if selected {
                imageView?.layer.borderColor = UIColor.orangeColor().CGColor
                imageView?.layer.borderWidth = 1
            }else{
                imageView?.layer.borderColor = nil
                imageView?.layer.borderWidth = 0
            }
        }
    }
}
