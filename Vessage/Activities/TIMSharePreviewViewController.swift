//
//  TIMSharePreviewViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/18.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class TIMSharePreviewViewController: UIViewController {

    private static var font:UIFont?
    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet weak var bcgCollectionView: UICollectionView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var maskView: UIView!
    @IBOutlet weak var shareTextContentLabel: UILabel!
    
    var shareTextContent:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fontSize = UserSetting.getUserNumberValue(cachedFontSizeKey)?.floatValue ?? 17.0
        let cgFontSize = CGFloat(fontSize)
        if let f =  TIMSharePreviewViewController.font{
            shareTextContentLabel.font = f
        }else if let fontName = UserSetting.getUserValue(cachedFontKey) as? String {
            if let font = UIFont(name: fontName, size:cgFontSize){
                shareTextContentLabel.font = font
            }else{
                let descs = createFontDescWithFontName(fontName)
                CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs, nil, { (state, progressDict) -> Bool in
                    switch state{
                    case .WillBeginDownloading:
                        return false
                    case .DidFinish:
                        if let newFont = UIFont(name: fontName, size: self.shareTextContentLabel?.font?.pointSize ?? cgFontSize){
                            self.shareTextContentLabel?.font = newFont
                        }
                    default:break
                    }
                    return true
                })
            }
        }
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
        
        if let fontSize = UserSetting.getUserNumberValue(cachedFontSizeKey){
            if fontSize.floatValue > fontSizeSlider.minimumValue {
                shareTextContentLabel.font = shareTextContentLabel.font.fontWithSize(CGFloat(fontSize.floatValue))
            }
            fontSizeSlider.setValue(fontSize.floatValue, animated: true)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let index = UserSetting.getUserIntValue(selectedStyleIndexKey)
        bcgCollectionView.selectItemAtIndexPath(NSIndexPath.init(forRow: index, inSection: 0), animated: true, scrollPosition: .CenteredHorizontally)
        setStyle(index)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? TIMShareAndSaveViewController{
            controller.image = shareTextContentLabel.superview?.viewToImage()
        }
    }
}

extension TIMSharePreviewViewController:SelectFontViewControllerDelegate{
    func selectFontViewController(ender: SelectFontViewController, onSelectedFont font: UIFont) {
        let fontSize = self.shareTextContentLabel.font.pointSize
        TIMSharePreviewViewController.font = font
        UserSetting.setUserValue(cachedFontKey, value: font.fontName)
        self.shareTextContentLabel.font = font.fontWithSize(fontSize)
    }
}

private let selectedStyleIndexKey = "TIMselectedStyleKey"
private let cachedFontSizeKey = "TIMFontSizeKey"
private let cachedFontKey = "TIMFontKey"

private let TIMDefaultStyles = [
    ["bcg":"tim_bcg_0","textColor":"#8D75FF"],
    ["bcg":"tim_bcg_1","textColor":"#DE67FF"],
    ["bcg":"tim_bcg_2","textColor":"#4C4C4C"],
    ["bcg":"tim_bcg_3","textColor":"#ffffff"],
    ["bcg":"tim_bcg_4","textColor":"#02C1FA"],
    ["bcg":"tim_bcg_5","textColor":"#CACACA"],
    ["bcg":"tim_bcg_6","textColor":"#ffffff"],
    ["bcg":"tim_bcg_7","textColor":"#ffffff"],
    ["bcg":"tim_bcg_8","textColor":"#000000"],
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
    @IBOutlet weak var imageView: UIImageView!{
        didSet{
            selected = false
        }
    }
    override var selected: Bool{
        didSet{
            if selected {
                imageView?.layer.borderColor = UIColor.orangeColor().CGColor
                imageView?.layer.borderWidth = 1
            }else{
                imageView?.layer.borderColor = UIColor.lightGrayColor().CGColor
                imageView?.layer.borderWidth = 0.5
            }
        }
    }
}
