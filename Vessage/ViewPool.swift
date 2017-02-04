//
//  ViewPool.swift
//  Vessage
//
//  Created by Alex Chow on 2017/2/4.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
public class ViewPool<T:UIView> {
    
    private var views = [T]()
    
    public convenience init() {
        self.init(initViews: [])
    }
    
    public init(initViews:[T]) {
        views.appendContentsOf(initViews)
    }
    
    public func getFreeView() -> T?{
        for v in views {
            if v.superview == nil {
                return v
            }
        }
        return nil
    }
    
    public func pushNewPooledView(v:T) -> T{
        views.append(v)
        return v
    }
    
    public func clearPool(){
        views.removeAll()
    }
    
    public func removeAllPooledViews() -> [T]{
        let arr = views.map{$0}
        views.removeAll()
        return arr
    }
    
    public func removePooledView(pooledView:T) -> T?{
        for v in views {
            if v == pooledView {
                return v
            }
        }
        return nil
    }
}
