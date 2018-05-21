//
//  HomeTabBarController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

class HomeTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        title = TabName.groupChannels.rawValue
        selectedIndex = Tab.groupChannels.rawValue
    }
}

extension HomeTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        switch selectedIndex {
        case Tab.openChannels.rawValue:
            title = TabName.openChannels.rawValue
        case Tab.groupChannels.rawValue:
            title = TabName.groupChannels.rawValue
        case Tab.settings.rawValue:
            title = TabName.settings.rawValue
        case Tab.users.rawValue:
            title = TabName.users.rawValue
        default:
            break
        }
    }
}
