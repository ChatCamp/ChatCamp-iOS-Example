//
//  UIStoryboard+ChatCamp.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

extension UIStoryboard {
    static func login() -> UIStoryboard {
        return UIStoryboard(name: "Login", bundle: nil)
    }
    
    static func home() -> UIStoryboard {
        return UIStoryboard(name: "Home", bundle: nil)
    }
}
