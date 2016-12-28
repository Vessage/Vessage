//
//  MatchContactUserViewController.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/28.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class MatchContactUserCell: UITableViewCell {
    static let reuseId = "MatchContactUserCell"
    
    @IBOutlet weak var checkedImage: UIImageView!
    @IBOutlet weak var nick: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var inviteButton: UIButton!
    @IBAction func onClickInviteButton(sender: AnyObject) {
        
    }
    
}



class MatchContactUserViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
}

extension MatchContactUserViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MatchContactUserCell.reuseId, forIndexPath: indexPath) as! MatchContactUserCell
        
        return cell
    }
}
