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
    
    func loadFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        return bundle.loadNibNamed(type(of: self).string(), owner: nil, options: nil)![0] as! UIView
    }
    
    class func loadViewFromNib() -> UIView? {
        return Bundle.main.loadNibNamed(self.nameOfClass, owner: nil, options: nil)?.first as? UIView
    }
    
    func animateAlpha(alpha: CGFloat, duration: Double = gradientTransitionDuration / 2, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .autoreverse], animations: { [weak self] in
            self?.alpha = alpha
            }, completion: completion)
    }
}
