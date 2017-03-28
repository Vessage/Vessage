//
//  ViewPool.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/4.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
open class ViewPool<T:UIView> {
    
    fileprivate var views = [T]()
    
    public convenience init() {
        self.init(initViews: [])
    }
    
    public init(initViews:[T]) {
        views.append(contentsOf: initViews)
    }
    
    open func getFreeView() -> T?{
        for v in views {
            if v.superview == nil {
                return v
            }
        }
        return nil
    }
    
    @discardableResult
    open func pushNewPooledView(_ v:T) -> T{
        views.append(v)
        return v
    }
    
    open func clearPool(){
        views.removeAll()
    }
    
    open func removeAllPooledViews() -> [T]{
        let arr = views.map{$0}
        views.removeAll()
        return arr
    }
    
    open func removePooledView(_ pooledView:T) -> T?{
        for v in views {
            if v == pooledView {
                return v
            }
        }
        return nil
    }
}
