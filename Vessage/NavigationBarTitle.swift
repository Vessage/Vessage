//
//  NavigationBarTitle.swift
//  Vessage
//
//  Created by AlexChow on 16/6/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import UIKit

class NavigationBarTitle: UIView {

    @IBOutlet weak var indicatorView: UIActivityIndicatorView!{
        didSet{
            indicatorHidden = true
        }
    }
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.text = title
        }
    }
    
    var title:String?{
        get{
            return titleLabel?.text
        }
        set{
            titleLabel?.text = newValue
        }
    }
    
    var indicatorHidden:Bool{
        get{
            return indicatorView.isHidden
        }
        set{
            indicatorView?.isHidden = newValue
            if newValue {
                indicatorView?.stopAnimating()
            }else{
                indicatorView?.startAnimating()
            }
        }
    }
    
    
    static func instanceFromXib() -> NavigationBarTitle{
        let view = Bundle.main.loadNibNamed("NavigationBarTitle", owner: nil, options: nil)![0] as! NavigationBarTitle
        view.backgroundColor = UIColor.clear
        return view
    }
}
