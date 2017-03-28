//
//  SelectFontViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/18.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

//MARK: Font
private let fontConfigList = [
    
    ["name":"DFWaWaSC-W5","display":"娃娃体","size":"17MB"],
    
    ["name":"STKaitiSC-Regular","display":"楷体-简","size":"106MB"],
    ["name":"STKaitiSC-Bold","display":"楷体-简-粗","size":"106MB"],
    ["name":"STKaitiSC-Black","display":"楷体-简-黑体","size":"106MB"],
    ["name":"STKaitiTC-Regular","display":"楷体-繁","size":"106MB"],
    ["name":"STKaitiTC-Bold","display":"楷体-繁-粗","size":"106MB"],
    ["name":"STKaitiTC-Black","display":"楷体-繁-黑体","size":"106MB"],
    
    ["name":"STXingkaiSC-Light","display":"行楷-简-细","size":"88MB"],
    ["name":"STXingkaiSC-Bold","display":"行楷-简-粗","size":"88MB"],
    ["name":"STXingkaiTC-Light","display":"行楷-繁-细","size":"88MB"],
    ["name":"STXingkaiTC-Bold","display":"行楷-繁-粗","size":"88MB"],
    
    ["name":"MLingWaiMedium-SC","display":"凌慧体-简-中黑","size":"24MB"],
    ["name":"MLingWaiMedium-TC","display":"凌慧体-繁-中黑","size":"24MB"],
    
    ["name":"HanziPenSC-W3","display":"翩翩体-简","size":"72MB"],
    ["name":"HanziPenSC-W5","display":"翩翩体-简-粗","size":"72MB"],
    ["name":"HanziPenTC-W3","display":"翩翩体-繁","size":"72MB"],
    ["name":"HanziPenTC-W5","display":"翩翩体-繁-粗","size":"72MB"],
    
    ["name":"ChalkboardSE-Regular","display":"Chalkboard SE","size":"520KB"],
    ["name":"BradleyHandITCTT-Bold","display":"Bradley Hand Bold","size":"592KB"],
    
]

extension UIFont{
    fileprivate static func loadFontWith(_ fontName:String,size:CGFloat = 12.0) -> UIFont?{
        if let font = UIFont(name: fontName, size: size) {
            if (font.fontName.compare(fontName) == .orderedSame ||
                font.familyName.compare(fontName) == .orderedSame) {
                return font
            }
        }
        return nil;
    }
}

func createFontDescWithFontName(_ fontName:String) -> NSMutableArray{
    // Creat a dictionary with the font's PostScript name.
    let attrs = NSDictionary(object: fontName, forKey: kCTFontNameAttribute as String as String as NSCopying)
    // Creat a new font descriptor reference from the attributtes dictionary
    let desc = CTFontDescriptorCreateWithAttributes(attrs as CFDictionary)
    
    var descs = NSMutableArray()
    descs = NSMutableArray(capacity: 0)
    descs.add(desc)
    return descs
}

@discardableResult
private func matchFont(_ fontName:String,handler:CTFontDescriptorProgressHandler? = nil) -> Bool {
    let descs = createFontDescWithFontName(fontName)
    return CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs, nil) {
        (state: CTFontDescriptorMatchingState, progressParameter: CFDictionary) -> Bool in
        if let callback = handler{
            return callback(state, progressParameter)
        }
        return true
    }
}

//MARK:FontItemCell
class FontItemCell: UITableViewCell {
    
    static let reuseId = "FontItemCell"
    var isSystemDefaultFont = false
    var fontDict:[String:String]?
    var fontIsReady = false{
        didSet{
            if fontIsReady {
                statusLabel?.text = nil
            }else{
                statusLabel?.text = "NOT_DOWNLOAD".localizedString()
            }
        }
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var fontDemoLabel: UILabel!
    @IBOutlet weak var checkedImage: UIImageView!
}

protocol SelectFontViewControllerDelegate {
    func selectFontViewController(_ ender:SelectFontViewController,onSelectedFont font:UIFont)
}

class SelectFontViewController: UIViewController {
    var delegate:SelectFontViewControllerDelegate?
    
    @IBOutlet weak var doneBarItem: UIBarButtonItem!
    
    @IBAction func onDoneClick(_ sender: AnyObject) {
        if let index = self.tableView.indexPathForSelectedRow{
            if let cell = tableView.cellForRow(at: index) as? FontItemCell {
                if cell.fontIsReady {
                    self.delegate?.selectFontViewController(self, onSelectedFont: cell.fontDemoLabel.font)
                    let _ = self.navigationController?.popViewController(animated: true)
                }else{
                    self.showAlert(nil, msg: "FONT_IS_NOT_READY".localizedString())
                }
            }
        }else{
            self.showAlert(nil, msg: "PLEASE_SELECT_A_FONT".localizedString())
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true
        self.tableView.tableFooterView?.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView?.reloadData()
    }
}

extension SelectFontViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontConfigList.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FontItemCell.reuseId, for: indexPath) as! FontItemCell
        if indexPath.row == 0 {
            cell.isSystemDefaultFont = true
        }else{
            cell.isSystemDefaultFont = false
            let info = fontConfigList[indexPath.row - 1]
            cell.fontDict = info
        }
        cell.checkedImage.isHidden = true
        cell.setSeparatorFullWidth()
        cell.setFontNameIfExists()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FontItemCell{
            if cell.fontIsReady{
                cell.checkedImage.isHidden = false
            }else if indexPath.row > 0{
                let info = fontConfigList[indexPath.row - 1]
                let title = String(format: "DOWNLOAD_FONT_X".localizedString(),info["display"]!)
                let msg = String(format: "DOWNLOAD_FONT_X_SIZE_MSG".localizedString(),info["size"]!)
                let alert = UIAlertController.create(title: title, message: msg, preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK".localizedString(), style: .default, handler: { (ac) in
                    cell.asynchronousSetFontsName()
                })
                alert.addAction(ok)
                alert.addAction(ALERT_ACTION_CANCEL)
                self.showAlert(alert)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FontItemCell{
            cell.checkedImage.isHidden = true
        }
    }
}

extension FontItemCell{
    
    @discardableResult
    fileprivate func setFontNameIfExists() -> Bool{
        if isSystemDefaultFont {
            self.fontDemoLabel.text = "DEFAULT".localizedString()
            self.fontDemoLabel.font = UIFont.systemFont(ofSize: 18.0)
            self.fontIsReady = true
            return true
        }
        
        self.fontDemoLabel.text = fontDict?["display"]
        if let fontName = fontDict?["name"]{
            if let font = UIFont.loadFontWith(fontName) {
                self.fontDemoLabel.font = font.withSize(18.0)
                self.fontIsReady = true
                return true
            }else{
                self.fontDemoLabel.font = UIFont.systemFont(ofSize: 18.0)
                self.fontIsReady = false
                self.asynchronousSetFontsName(false)
                return false
            }
        }
        return false
    }
    
    fileprivate func asynchronousSetFontsName(_ autoDownload:Bool = true) {
        
        if self.fontDict == nil || self.fontDict?["name"] == nil{
            return
        }
        let fontName = self.fontDict!["name"]!
        
        matchFont(fontName) { (state, progressParameter) -> Bool in
            let parameter = progressParameter as NSDictionary
            let progressValue = (parameter.object(forKey: kCTFontDescriptorMatchingPercentage) as AnyObject).doubleValue
            
            switch state {
            case .didBegin:
                debugPrint("Begin Matching")
                
            case .didFinish:
                DispatchQueue.main.async(execute: { () -> Void in
                    // display the sample text for the newly downloaded font
                    if let name = self.fontDict?["name"]{
                        if fontName == name{
                            if let font = UIFont(name: fontName, size: 18){
                                self.statusLabel.text = nil
                                self.fontDemoLabel.font = font
                                self.fontIsReady = true
                                if self.isSelected{
                                    self.checkedImage?.isHidden = false
                                }
                            }
                        }
                    }
                })
                
                
            case .willBeginDownloading:
                if !autoDownload{
                    return false
                }
                self.statusLabel.text = String(format: "DOWNLOADING".localizedString(), "")
                debugPrint("Begin Downloading")
            case .didFinishDownloading:
                debugPrint("Finish Downloading")
            case .downloading:
                DispatchQueue.main.async(execute: { () -> Void in
                    if let name = self.fontDict?["name"]{
                        if fontName == name{
                            if let progress = progressValue{
                                self.statusLabel.text = String(format: "DOWNLOADING".localizedString(), "\(progress)%")
                            }
                        }
                    }
                })
                
            case .didFailWithError:
                DispatchQueue.main.async(execute: { () -> Void in
                    if let name = self.fontDict?["name"]{
                        if fontName == name{
                            // display the sample text for the newly downloaded font
                            self.statusLabel.text = "DOWNLOAD_ERR".localizedString()
                        }
                    }
                })
                
            default:
                break
            }
            
            return true
        }
    }
}

extension SelectFontViewController{
    static func showSelectFontViewController(_ nvc:UINavigationController,delegate:SelectFontViewControllerDelegate){
        let controller = instanceFromStoryBoard("SelectFontViewController", identifier: "SelectFontViewController") as! SelectFontViewController
        controller.delegate = delegate
        nvc.pushViewController(controller, animated: true)
    }
}
