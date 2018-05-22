//
//  UsersViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 21/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp

class UsersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 44
            tableView.register(ChatTableViewCell.nib(), forCellReuseIdentifier: ChatTableViewCell.string())
        }
    }
    
    var users: [CCPUser] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        loadUsers()
    }

    fileprivate func loadUsers() {
        let usersQuery = CCPUserListQuery()
        usersQuery.get { [unowned self] (users, error) in
            if error == nil {
                guard let allUsers = users else { return }
                self.users = allUsers.filter({ $0.getId() != CCPClient.getCurrentUser().getId() })
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Users", message: "Unable to load Users right now. Please try later.", actionText: "Ok")
                }
            }
        }
    }
}

// MARK:- UITableViewDataSource
extension UsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.string(), for: indexPath) as! ChatTableViewCell
        
        let user = users[indexPath.row]
        cell.nameLabel.text = user.getDisplayName()
        cell.messageLabel.text = ""
        cell.unreadCountLabel.isHidden = true
        if let avatarUrl = user.getAvatarUrl() {
            cell.avatarImageView.downloadedFrom(link: avatarUrl)
        }
        
        return cell
    }
}

// MARK:- UITableViewDelegate
extension UsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        let userID = CCPClient.getCurrentUser().getId()
        let username = CCPClient.getCurrentUser().getDisplayName()
        
        let sender = Sender(id: userID, displayName: username!)
        
        CCPGroupChannel.create(name: user.getDisplayName() ?? "", userIds: [userID, user.getId()], isDistinct: true) { groupChannel, error in
            if error == nil {
                let chatViewController = ChatViewController(channel: groupChannel!, sender: sender)
                self.navigationController?.pushViewController(chatViewController, animated: true)
                tableView.deselectRow(at: indexPath, animated: true)
            } else {
                self.showAlert(title: "Error!", message: "Some error occured, please try again.", actionText: "OK")
            }
        }
    }
}
