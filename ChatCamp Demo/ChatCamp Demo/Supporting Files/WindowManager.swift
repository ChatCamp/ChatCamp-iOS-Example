//
//  WindowManager.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCampUIKit

public class WindowManager {
    
    public class var shared: WindowManager {
        struct Singleton {
            static let instance = WindowManager()
        }
        
        return Singleton.instance
    }
    
    public var window: UIWindow
    
    public init() {
        window = UIWindow(frame: UIScreen.main.bounds)
    }
    
    public func prepareWindow(isLoggedIn: Bool) {
        window.rootViewController = initialRootViewController(isLoggedIn: isLoggedIn)
        window.makeKeyAndVisible()
    }
    
}

// MARK:- API
extension WindowManager {
    
    public func showLoginWithAnimation() {
        makeRootViewController(viewController: UIViewController.loginViewController())
    }
    
    public func showHomeWithAnimation() {
        makeRootViewController(viewController: UIViewController.homeTabBarNavigationController())
    }
    
}

// MARK:- Helpers
extension WindowManager {
    
    public func initialRootViewController(isLoggedIn: Bool) -> UIViewController {
        if isLoggedIn {
            return UIViewController.homeTabBarNavigationController()
        } else {
            return UIViewController.loginViewController()
        }
    }
    
    public func makeRootViewController(viewController: UIViewController) {
        viewController.view.alpha = 0
        
        UIView.animate(withDuration: DefaultAnimationDuration,
                       animations: { () -> Void in
                        if let rootViewController = self.window.rootViewController {
                            rootViewController.view.alpha = 0
                        }
        },
                       completion: { (finished) -> Void in
                        self.window.rootViewController = viewController
                        
                        UIView.animate(withDuration: 2 * DefaultAnimationDuration,
                                       animations: { () -> Void in
                                        viewController.view.alpha = 1
                        })
        })
    }
    
}
