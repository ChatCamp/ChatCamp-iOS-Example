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
}
