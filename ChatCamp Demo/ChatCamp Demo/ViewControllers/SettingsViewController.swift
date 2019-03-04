//
//  SettingsViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import ChatCampUIKit

open class SettingsViewController: UITableViewController {
    
    fileprivate var db: SQLiteDatabase!

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("ChatDatabase.sqlite")
            db = try! SQLiteDatabase.open(path: fileURL.path)
            print("Successfully opened connection to database.")
        } catch SQLiteError.OpenDatabase(let message) {
            print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
        }
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
    }
    
}

extension SettingsViewController {
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let alertController = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { (action) in
                if let token = UserDefaults.standard.deviceToken() {
                    CCPClient.deleteUserPushToken(token, completionHandler: { (error) in
                        if error == nil {
                            UserDefaults.standard.setUserID(userID: nil)
                            UserDefaults.standard.setUsername(username: nil)
                            CCPClient.disconnect() { (error) in
                                WindowManager.shared.showLoginWithAnimation()
                            }
                        } else {
                            self.showAlert(title: "Error", message: "Error while deleting push token on server. Please try again.", actionText: "OK")
                        }
                    })
                } else {
                    CCPClient.disconnect() { (error) in
                        WindowManager.shared.showLoginWithAnimation()
                    }
                }
                
                // clears group channel database cache
                do {
                    try self.db.deleteGroupChannelsLocalStorage()
                } catch {
                    print(self.db.errorMessage)
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(logoutAction)
            
            present(alertController, animated: true, completion: nil)
            
        case 1:
            let blockedUsersViewController = UIViewController.blockedUsersViewController()
            navigationController?.pushViewController(blockedUsersViewController, animated: true)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Logout"
        case 1:
            cell.textLabel?.text = "Manage Blocked Users"
        default:
            break
        }
        
        return cell
    }
    
}
