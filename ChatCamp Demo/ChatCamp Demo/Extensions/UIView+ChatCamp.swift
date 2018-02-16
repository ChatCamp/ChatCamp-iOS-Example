//
//  UIView+ChatCamp.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    class func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    class func loadFromNib() -> UIView {
        let bundle = Bundle(identifier: self.string())!
        return bundle.loadNibNamed(self.string(), owner: nil, options: nil)![0] as! UIView
    }
}
