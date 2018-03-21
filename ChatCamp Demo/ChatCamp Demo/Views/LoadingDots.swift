//
//  LoadingDots.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 21/03/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

class LoadingDots: UIView {
    
    @IBOutlet weak var dotImage1: UIImageView!
    @IBOutlet weak var dotImage2: UIImageView!
    @IBOutlet weak var dotImage3: UIImageView!
    
    var shouldAnimate = true {
        didSet {
            animate()
        }
    }
    
    func animate() {
        hideDots()
        dotImage1.animateAlpha(alpha: 1, duration: gradientTransitionDuration, completion: nil)
        delay(gradientTransitionDuration / 2, closure: {
            self.dotImage2.animateAlpha(alpha: 1, duration: gradientTransitionDuration, completion: nil)
        })
        delay(gradientTransitionDuration, closure: {
            self.dotImage3.animateAlpha(alpha: 1, duration: gradientTransitionDuration, completion: nil)
        })
    }
    
    func hideDots() {
        dotImage1.alpha = 0
        dotImage2.alpha = 0
        dotImage3.alpha = 0
    }
    
    
}
