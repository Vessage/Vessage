//
//  SearchExtension.swift
//  Vessage
//
//  Created by AlexChow on 16/8/20.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: SearchResultModel
class SearchResultModel{
    
    enum Type {
        case undefine,userNormal, userActive,userNear,userActiveNear,conversation,mobile
    }
    
    static let typeUserNormal = 0
    static let typeUserActive = 1
    static let typeUserNear = 2
    static let typeConversation = 10
    static let typeMobile = 20
    init(keyword:String,user:VessageUser,userType:Type = .userNormal){
        self.conversation = nil
        self.keyword = keyword
        self.user = user
        self.type = userType
    }
    
    init(keyword:String,conversation:Conversation){
        self.user = nil
        self.keyword = keyword
        self.conversation = conversation
        self.type = .conversation
    }
    
    init(keyword:String,mobile:String){
        self.conversation = nil
        self.user = nil
        self.keyword = keyword
        self.mobile = mobile
        self.type = .mobile
    }
    
    var type:Type = .undefine
    var keyword:String!
    
    var conversation:Conversation!
    var user:VessageUser!
    var mobile:String!
}


//MARK: ConversationListController extension UISearchBarDelegate
let searchAccountIdLimitedPerMinute = 3
extension ConversationListController:UISearchBarDelegate
{
    
    private var lastMinuteSearchAccountId:NSNumber{
        get{
            return UserSetting.getUserNumberValue("LST_GET_ANT_ID_M") ?? NSNumber(integer:0)
        }
        set{
            return UserSetting.setUserNumberValue("LST_GET_ANT_ID_M", value: newValue)
        }
    }
    
    private var lastMinuteSearchAccountIdCount:Int{
        get{
            return UserSetting.getUserIntValue("LST_M_GET_ANT_ID_CNT")
        }
        set{
            return UserSetting.setUserIntValue("LST_M_GET_ANT_ID_CNT", value: newValue)
        }
    }
    
    private var canSearchByAccountId:Bool{
        if UserSetting.godMode {
            //return true
        }
        
        let now = NSDate().totalMinutesSince1970
        if now.integerValue > lastMinuteSearchAccountId.integerValue{
            lastMinuteSearchAccountId = now
            lastMinuteSearchAccountIdCount = 0
            return true
        }else{
            return lastMinuteSearchAccountIdCount < searchAccountIdLimitedPerMinute
        }
    }
    
    //MARK: search bar delegate
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text.hasEnd("\n") {
            if let accoundId = searchBar.text{
                if accoundId.isBahamutAccount() ?? false{
                    if nil == userService.getCachedUserByAccountId(accoundId){
                        if canSearchByAccountId {
                            let hud = self.showAnimationHud()
                            userService.getUserProfileByAccountId(accoundId, updatedCallback: { (user) in
                                hud.hideAnimated(true)
                                if let u = user{
                                    self.lastMinuteSearchAccountIdCount += 1
                                    let model = SearchResultModel(keyword: accoundId,user: u)
                                    self.searchResult.insert(model, atIndex: 0)
                                }
                            })
                        }else{
                            self.showAlert("SEARCH_LIMIT".localizedString(), msg: String(format: "SEARCH_ACCOUNTID_LIMITED_X".localizedString(), "\(searchAccountIdLimitedPerMinute)"))
                        }
                    }
                }
            }
            return false
        }
        return true
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchResult.removeAll()
        
        var nearActiveUsers = [VessageUser]()
        
        var nearUsers = userService.nearUsers.getRandomSubArray(6)
        var activeUsers = userService.activeUsers.getRandomSubArray(3)
        nearUsers.forEach{ n in
            let contain = activeUsers.contains{ a in
                a.userId == n.userId
            }
            if contain{
                nearActiveUsers.append(n)
            }
        }
        
        nearActiveUsers.forEach{ na in
            nearUsers.removeElement{ n in
                n.userId == na.userId
            }
            activeUsers.removeElement{ n in
                n.userId == na.userId
            }
        }
        
        var usersModel = [SearchResultModel]()
        
        let naus = nearActiveUsers.map({ (resultUser) -> SearchResultModel in
            return SearchResultModel(keyword: resultUser.accountId,user:resultUser,userType: .userActiveNear)
        })
        usersModel.appendContentsOf(naus)
        
        let nus = nearUsers.map({ (resultUser) -> SearchResultModel in
            return SearchResultModel(keyword: resultUser.accountId,user:resultUser,userType: .userNear)
        })
        usersModel.appendContentsOf(nus)
        
        let aus = activeUsers.map({ (resultUser) -> SearchResultModel in
            return SearchResultModel(keyword: resultUser.accountId,user:resultUser,userType: .userActive)
        })
        usersModel.appendContentsOf(aus)
        searchResult.appendContentsOf(usersModel)
        
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        dispatch_async(dispatch_get_main_queue()) {             
            if let cancelButton = searchBar.valueForKey("cancelButton") as? UIButton{
                cancelButton.enabled = true
            }
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if GodModeManager.checkGodCode(self, code: searchText) {
            isSearching = false
            return
        }
        
        searchResult.removeAll()
        if String.isNullOrWhiteSpace(searchText) == false{
            let conversations = conversationService.searchConversation(searchText)
            let res = conversations.map({ (c) -> SearchResultModel in
                return SearchResultModel(keyword: searchText,conversation: c)
            })
            searchResult.appendContentsOf(res)
            let existsUsers = conversations.map({ (c) -> VessageUser in
                let u = VessageUser()
                u.userId = c.chatterId
                return u
            })
            
            userService.searchUser(searchText, callback: { (keyword, resultUsers) in
                if !String.isNullOrEmpty(searchBar.text) && keyword != searchBar.text{
                    #if DEBUG
                        print("ignore search result")
                    #endif
                    return
                }
                
                let results = resultUsers.filter({ (resultUser) -> Bool in
                    
                    return !existsUsers.contains({ (eu) -> Bool in
                        return VessageUser.isTheSameUser(resultUser, userb: eu)
                    })
                }).map({ (resultUser) -> SearchResultModel in
                    return SearchResultModel(keyword: searchText,user: resultUser)
                })
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.searchResult.appendContentsOf(results)
                    if self.searchResult.count == 0 && searchText.isMobileNumber(){
                        let model = SearchResultModel(keyword: searchText,mobile: searchText)
                        self.searchResult.append(model)
                    }
                })
            })
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        isSearching = false
    }
}
