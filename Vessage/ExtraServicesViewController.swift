//
//  ExtraServicesListController.swift
//  Vessage
//
//  Created by AlexChow on 16/5/5.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

class ExtraServiceCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!{
        didSet{
            badgeLabel.hidden = true
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = 10
        }
    }
    var badgeValue:Int = 0 {
        didSet{
            if badgeLabel != nil{
                if badgeValue == 0{
                    badgeLabel.hidden = true
                }else{
                    badgeLabel.text = "\(badgeValue)"
                }
            }
        }
    }
    
    static let reuseId = "ExtraServiceCell"
    private var rootController:ExtraServicesListController!
    var serviceInfo:ExtraServiceInfo!{
        didSet{
            badgeValue = 99
            nameLabel.text = serviceInfo.cellTitle
            iconImageView.image = UIImage(named: serviceInfo.cellIconName)
            iconImageView.clipsToBounds = true
            iconImageView.layer.cornerRadius = 3
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ExtraServiceCell.onClickCell(_:))))
    }
    
    func onClickCell(gesture:UITapGestureRecognizer){
        let controller = UIViewController.instanceFromStoryBoard(serviceInfo.storyBoardName, identifier: serviceInfo.controllerIdentifier)
        if(serviceInfo.isPushController){
            rootController.navigationController?.pushViewController(controller, animated: true)
        }else{
            rootController.presentViewController(controller, animated: true, completion: nil)
        }
    }
}

//MARK:ExtraServicesListController
class ExtraServicesListController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.tableView.scrollEnabled = false
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ExtraServiceInfoList.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 18
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ExtraServiceCell.reuseId, forIndexPath: indexPath) as! ExtraServiceCell
        cell.rootController = self
        cell.serviceInfo = ExtraServiceInfoList[indexPath.row]
        return cell
    }
    
}
