//
//  DKBaseManager.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 17/11/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation

protocol DKBaseManagerObserver {
    
    func add(observer object: AnyObject)
    
    func remove(observer object: AnyObject)
    
    func notify(with selector: Selector, object: AnyObject?)
    
    func notify(with selector: Selector, object: AnyObject?, objectTwo: AnyObject?)
    
}

//////////////////////////////////////////////////////////////////////

open class DKBaseManager: NSObject, DKBaseManagerObserver {
    
    private let observers = NSHashTable<AnyObject>.weakObjects()
    
    open func add(observer object: AnyObject) {
        self.observers.add(object)
    }
    
    open func remove(observer object: AnyObject) {
        self.observers.remove(object)
    }
    
    open func notify(with selector: Selector, object: AnyObject?) {
        self.notify(with: selector, object: object, objectTwo: nil)
    }
    
    open func notify(with selector: Selector, object: AnyObject?, objectTwo: AnyObject?) {
        if self.observers.count > 0 {
            let block = {
                for observer in self.observers.allObjects {
                    if observer.responds(to: selector) {
                        _ = observer.perform(selector, with: object, with: objectTwo)
                    }
                }
            }
            
            if Thread.isMainThread {
                block()
            } else {
                DispatchQueue.main.async(execute: block)
            }
        }
    }
    
}
