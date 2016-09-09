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
    
    init(keyword:String,user:VessageUser,activeUser:Bool = false){
        self.keyword = keyword
        self.user = user
        self.activeUser = activeUser
    }
    
    init(keyword:String,conversation:Conversation){
        self.keyword = keyword
        self.conversation = conversation
    }
    
    init(keyword:String,mobile:String){
        self.keyword = keyword
        self.mobile = mobile
    }
    
    var keyword:String!
    var conversation:Conversation!
    var user:VessageUser!
    var activeUser:Bool = false
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
            return true
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
                            self.playToast(String(format: "SEARCH_ACCOUNTID_LIMITED_X".localizedString(), "\(searchAccountIdLimitedPerMinute)"))
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
        #if DEBUG
            let users = userService.activeUsers.getRandomSubArray(3)
            let hotUserRes = users.map({ (resultUser) -> SearchResultModel in
                return SearchResultModel(keyword: resultUser.accountId,user:resultUser,activeUser: true)
            })
            searchResult.appendContentsOf(hotUserRes)
        #endif
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if String.isNullOrWhiteSpace(searchBar.text){
            isSearching = false
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        let testModeStrs = searchText.split(">")
        if testModeStrs.count == 2 {
            if DeveloperMainPanelController.isShowDeveloperPanel(self, id: testModeStrs[0], psw: testModeStrs[1]){
                isSearching = false
                return
            }
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
                u.mobile = c.chatterMobile
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
