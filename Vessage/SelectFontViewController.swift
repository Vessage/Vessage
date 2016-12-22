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

private var downloadedFonts = [String:String]()
private let downloadedFontMapKey = "DownloadedFontMapKey"

private func addDownloadedFont(fontName:String,fontUrl:NSURL){
    if let path = fontUrl.path{
        downloadedFonts.updateValue(path, forKey: fontName)
        NSUserDefaults.standardUserDefaults().setObject(downloadedFonts, forKey: downloadedFontMapKey)
    }
}

private func unloadDownloadedFontMap(){
    downloadedFonts.removeAll()
}

private func loadDownloadedFontMap(){
    if let map = readCachedFontMap(){
        for (name,item) in map {
            if let fontUrl = item as? String{
                downloadedFonts.updateValue(fontUrl, forKey: name)
            }
        }
    }
}

private func readCachedFontMap()->[String:AnyObject?]?{
    return NSUserDefaults.standardUserDefaults().dictionaryForKey(downloadedFontMapKey)
}

extension UIFont{
    static func loadFontWith(fontName:String) -> UIFont?{
        var aFont = UIFont(name: fontName, size: 12.0)
        
        if aFont == nil {
            if let fontUrl = readCachedFontMap()?[fontName] as? String{
                let url = NSURL.fileURLWithPath(fontUrl)
                CTFontManagerRegisterFontsForURL(url, .Process, nil)
                aFont = UIFont(name: fontName, size: 12.0)
            }
        }
        
        // If the font is already download
        if let font = aFont {
            if (font.fontName.compare(fontName) == .OrderedSame ||
                font.familyName.compare(fontName) == .OrderedSame) {
                return aFont
            }
        }
        return nil;
    }
}

private func getFontByName(fontName:String) -> UIFont?{
    var aFont = UIFont(name: fontName, size: 12.0)
    
    if aFont == nil {
        if let fontUrl = downloadedFonts[fontName]{
            let url = NSURL.fileURLWithPath(fontUrl)
            CTFontManagerRegisterFontsForURL(url, .Process, nil)
            aFont = UIFont(name: fontName, size: 12.0)
        }
    }
    
    // If the font is already download
    if let font = aFont {
        if (font.fontName.compare(fontName) == .OrderedSame ||
            font.familyName.compare(fontName) == .OrderedSame) {
            return aFont
        }
    }
    return nil;
}

//MARK:FontItemCell
class FontItemCell: UITableViewCell {
    
    static let reuseId = "FontItemCell"
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
    func selectFontViewController(ender:SelectFontViewController,onSelectedFont font:UIFont)
}

class SelectFontViewController: UIViewController {
    var delegate:SelectFontViewControllerDelegate?
    
    @IBOutlet weak var doneBarItem: UIBarButtonItem!
    
    @IBAction func onDoneClick(sender: AnyObject) {
        if let index = self.tableView.indexPathForSelectedRow{
            if let cell = tableView.cellForRowAtIndexPath(index) as? FontItemCell {
                if cell.fontIsReady {
                    self.delegate?.selectFontViewController(self, onSelectedFont: cell.fontDemoLabel.font)
                    self.navigationController?.popViewControllerAnimated(true)
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
        loadDownloadedFontMap()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true
        self.tableView.tableFooterView?.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView?.reloadData()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        unloadDownloadedFontMap()
    }
}

extension SelectFontViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontConfigList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(FontItemCell.reuseId, forIndexPath: indexPath) as! FontItemCell
        let info = fontConfigList[indexPath.row]
        cell.fontDict = info
        cell.fontDemoLabel.text = info["display"]
        cell.checkedImage.hidden = true
        cell.setSeparatorFullWidth()
        if let fontName = info["name"]{
            cell.setFontNameIfExists(fontName)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? FontItemCell{
            if cell.fontIsReady{
                cell.checkedImage.hidden = false
            }else{
                let info = fontConfigList[indexPath.row]
                let title = String(format: "DOWNLOAD_FONT_X".localizedString(),info["display"]!)
                let msg = String(format: "DOWNLOAD_FONT_X_SIZE_MSG".localizedString(),info["size"]!)
                let alert = UIAlertController.create(title: title, message: msg, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK".localizedString(), style: .Default, handler: { (ac) in
                    cell.asynchronousSetFontsName()
                })
                alert.addAction(ok)
                alert.addAction(ALERT_ACTION_CANCEL)
                self.showAlert(alert)
            }
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? FontItemCell{
            cell.checkedImage.hidden = true
        }
    }
}

extension FontItemCell{
    
    private func setFontNameIfExists(fontName:String) -> Bool{
        if let font = getFontByName(fontName) {
            self.fontDemoLabel.font = font.fontWithSize(18.0)
            self.fontIsReady = true
            return true
        }else{
            return false
        }
    }
    
    private func asynchronousSetFontsName() {
        
        if self.fontDict == nil || self.fontDict?["name"] == nil{
            return
        }
        let fontName = self.fontDict!["name"]!
        
        // Creat a dictionary with the font's PostScript name.
        let attrs = NSDictionary(object: fontName, forKey: kCTFontNameAttribute as String)
        // Creat a new font descriptor reference from the attributtes dictionary
        let desc = CTFontDescriptorCreateWithAttributes(attrs as CFDictionaryRef)
        
        var descs = NSMutableArray()
        descs = NSMutableArray(capacity: 0)
        descs.addObject(desc)
        
        CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs, nil) {
            (state: CTFontDescriptorMatchingState, progressParameter: CFDictionary) -> Bool in
            
            let parameter = progressParameter as NSDictionary
            let progressValue = parameter.objectForKey(kCTFontDescriptorMatchingPercentage)?.doubleValue
            
            switch state {
            case .DidBegin:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let name = self.fontDict?["name"]{
                        if fontName == name{
                            self.statusLabel.text = String(format: "DOWNLOADING".localizedString(), "")
                            self.fontDemoLabel.font = UIFont.systemFontOfSize(18.0)
                        }
                    }
                    debugPrint("Begin Matching")
                })
                
            case .DidFinish:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if let name = self.fontDict?["name"]{
                        if fontName == name{
                            // display the sample text for the newly downloaded font
                            self.statusLabel.text = nil
                            self.fontDemoLabel.font = UIFont(name: fontName, size: 18)
                            self.fontIsReady = true
                            if self.selected{
                                self.checkedImage?.hidden = false
                            }
                            // Log the font URL in the console
                            let font = CTFontCreateWithName(fontName, 0.0, nil)
                            if let fontURL = CTFontCopyAttribute(font, kCTFontURLAttribute) as? NSURL{
                                addDownloadedFont(fontName, fontUrl: fontURL)
                                debugPrint(fontURL)
                            }
                        }
                    }
                })
                
                
            case .WillBeginDownloading:
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    debugPrint("Begin Downloading")
                })
                
            case .DidFinishDownloading:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    debugPrint("Finish Downloading")
                })
                
                
            case .Downloading:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let name = self.fontDict?["name"]{
                        if fontName == name{
                            if let progress = progressValue{
                                self.statusLabel.text = String(format: "DOWNLOADING".localizedString(), "\(progress)%")
                            }
                        }
                    }
                })
                
            case .DidFailWithError:
                if let name = self.fontDict?["name"]{
                    if fontName == name{
                        // display the sample text for the newly downloaded font
                        self.statusLabel.text = "DOWNLOAD_ERR".localizedString()
                    }
                }
            default:
                break
            }
            
            return true
        }
    }
}

extension SelectFontViewController{
    static func showSelectFontViewController(nvc:UINavigationController,delegate:SelectFontViewControllerDelegate){
        let controller = instanceFromStoryBoard("SelectFontViewController", identifier: "SelectFontViewController") as! SelectFontViewController
        controller.delegate = delegate
        nvc.pushViewController(controller, animated: true)
    }
}
