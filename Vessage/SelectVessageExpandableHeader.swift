//
//  SelectVessageExpandableHeader.swift
//  Vessage
//
//  Created by AlexChow on 16/7/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

class SelectVessageExpandableHeader: UIView {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icon: UIImageView!{
        didSet{
            icon?.hidden = expanded
        }
    }
    var expanded = false{
        didSet{
            icon?.hidden = expanded
        }
    }
    
    static func instanceFromXib() -> SelectVessageExpandableHeader{
        return NSBundle.mainBundle().loadNibNamed("SelectVessageExpandableHeader", owner: nil, options: nil)[0] as! SelectVessageExpandableHeader
    }
    
}