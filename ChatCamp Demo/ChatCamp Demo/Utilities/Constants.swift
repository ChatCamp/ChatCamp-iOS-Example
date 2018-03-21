//
//  Constants.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

enum Tab: Int {
    case openChannels = 0
    case groupChannels = 1
    case settings = 2
}

enum TabName: String {
    case openChannels = "Open Channels"
    case groupChannels = "Group Channels"
    case settings = "Settings"
}

let DefaultAnimationDuration: TimeInterval = 0.3
let gradientTransitionDuration: TimeInterval = 1.5
