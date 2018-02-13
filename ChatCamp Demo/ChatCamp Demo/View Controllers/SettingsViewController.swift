//
//  SettingsViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { (action) in
            DispatchQueue.main.async {
                WindowManager.shared.showLoginWithAnimation()
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(logoutAction)
        
        present(alertController, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
