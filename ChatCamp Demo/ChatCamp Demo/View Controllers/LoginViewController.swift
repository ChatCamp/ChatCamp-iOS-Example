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
    @IBOutlet weak var connectButton: UIButton! {
        didSet {
            connectButton.layer.cornerRadius = 23
            connectButton.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
}

// MARK:- Actions
extension LoginViewController {
    @IBAction func didTapOnConnect(_ sender: UIButton) {
        guard let userID = userIDTextField.text, !userID.isEmpty else {
            showAlert(title: "No User ID", message: "Please enter a valid User ID.", actionText: "Ok")
            return
        }
        
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(title: "No Username", message: "Please enter a valid Username.", actionText: "Ok")
            return
        }
        
        activityIndicator.startAnimating()
        CCPClient.connect(uid: userID) { [unowned self] (user, error) in
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
                    UserDefaults.standard.setUserID(userID: userID)
                    UserDefaults.standard.setUsername(username: username)
                    if let deviceToken = UserDefaults.standard.deviceToken() {
                        CCPClient.updateUserPushToken(token: deviceToken) { (_,_) in
                            print("update device token on the server.")
                        }
                    }
                    WindowManager.shared.showHomeWithAnimation()
                }
            }
        }
    }
}
