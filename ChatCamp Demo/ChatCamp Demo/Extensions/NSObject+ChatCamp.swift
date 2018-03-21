//
//  NSObject+ChatCamp.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

extension NSObject {
    class func string() -> String {
        return String(describing: self)
    }
    
    public class var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
}
