//
//  UsersViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 21/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import SDWebImage

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
    fileprivate var usersToFetch: Int = 5
    fileprivate var loadingUsers = false
    var usersQuery: CCPUserListQuery!

    override func viewDidLoad() {
        super.viewDidLoad()

        usersQuery = CCPClient.createUserListQuery()
        loadUsers(limit: 20)
    }

    fileprivate func loadUsers(limit: Int) {
        loadingUsers = true
        usersQuery.load(limit: limit) { [unowned self] (users, error) in
            if error == nil {
                guard let users = users else { return }
                self.users.append(contentsOf: users.filter({ $0.getId() != CCPClient.getCurrentUser().getId() }))
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.loadingUsers = false
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Users", message: "Unable to load Users right now. Please try later.", actionText: "Ok")
                    self.loadingUsers = false
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
            cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            cell.avatarImageView.setImageForName(string: user.getDisplayName() ?? "?", circular: true, textAttributes: nil)
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

// MARK:- ScrollView Delegate Methods
extension UsersViewController {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (tableView.indexPathsForVisibleRows?.contains([0, users.count - 1]) ?? false) && !loadingUsers && users.count >= 19 {
            loadUsers(limit: usersToFetch)
        }
    }
}
