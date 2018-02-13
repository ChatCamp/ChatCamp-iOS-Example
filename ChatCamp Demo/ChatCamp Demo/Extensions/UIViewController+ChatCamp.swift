//
//  UIViewController+ChatCamp.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import MessageKit
import ChatCamp

extension UIViewController {
    static func loginViewController() -> LoginViewController {
        return UIStoryboard.login().instantiateViewController(withIdentifier: LoginViewController.string()) as! LoginViewController
    }
    
    static func homeTabBarNavigationController() -> UINavigationController {
        return UIStoryboard.home().instantiateViewController(withIdentifier: UINavigationController.string()) as! UINavigationController
    }
    
    static func chatViewController(channel: CCPGroupChannel, sender: Sender) -> ChatViewController {
        return ChatViewController(channel:channel, sender: sender)
    }
}

// MARK:- Alerts
extension UIViewController {
    func showAlert(title: String, message: String, actionText: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionText, style: .default) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        
        present(alertController, animated: true, completion: nil)
    }
}
