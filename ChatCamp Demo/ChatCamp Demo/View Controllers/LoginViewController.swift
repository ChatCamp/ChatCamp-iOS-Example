//
//  LoginViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp

class LoginViewController: UIViewController {
    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
}

// MARK:- Actions
extension LoginViewController {
    @IBAction func didTapOnConnect(_ sender: UIButton) {
        guard let userID = userIDTextField.text, !userID.isEmpty else {
            showAlert(title: "No User ID", message: "Please enter a valid User ID.", actionText: "Ok")
            return
        }
        
        activityIndicator.startAnimating()
        CCPClient.connect(uid: "1") { (user, error) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                if error != nil {
                    let alertController = UIAlertController(title: "Error In Login", message: "An error occurred while logging you in.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                        alertController.dismiss(animated: true, completion: nil)
                    })
                    alertController.addAction(okAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                    return
                } else {
                    WindowManager.shared.showHomeWithAnimation()
                }
            }
        }
    }
}
