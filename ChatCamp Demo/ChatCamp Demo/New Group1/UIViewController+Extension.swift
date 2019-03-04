//
//  UIViewController+Extension.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import ChatCampUIKit

extension UIViewController {
    
    static func loginViewController() -> LoginViewController {
        return UIStoryboard.login().instantiateViewController(withIdentifier: LoginViewController.string()) as! LoginViewController
    }
    
}

// MARK:- Alerts
extension UIViewController {
    
    public func showAlert(title: String, message: String, actionText: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionText, style: .default) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        
        present(alertController, animated: true, completion: nil)
    }
    
}
