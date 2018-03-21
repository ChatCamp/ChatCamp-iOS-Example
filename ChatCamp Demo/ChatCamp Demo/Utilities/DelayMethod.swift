//
//  DelayMethod.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 21/03/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

func delay(_ delay:Double, closure:@escaping ()->()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}
