//
//  CreateChannelViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 14/06/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

import UIKit
import ChatCamp
import MBProgressHUD

class CreateChannelViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var creatButton: UIBarButtonItem!
    @IBOutlet weak var channelNameTextField: UITextField!
    
    var viewModel = ParticipantViewModel()
    
    var users: [CCPUser] = []
    fileprivate var usersToFetch: Int = 20
    fileprivate var loadingUsers = false
    var usersQuery: CCPUserListQuery!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.register(ChatTableViewCell.nib(), forCellReuseIdentifier: ChatTableViewCell.identifier)
        tableView?.estimatedRowHeight = 100
        tableView?.rowHeight = UITableViewAutomaticDimension
        tableView?.allowsMultipleSelection = true
        tableView?.dataSource = viewModel
        tableView?.delegate = viewModel
        
        usersQuery = CCPClient.createUserListQuery()
        loadUsers(limit: usersToFetch)
        
        viewModel.didToggleSelection = { [weak self] hasSelection in
            self?.creatButton.isEnabled = hasSelection
        }
        
        viewModel.loadMoreUsers = {
            if (self.tableView?.indexPathsForVisibleRows?.contains([0, self.users.count - 1]) ?? false) && !self.loadingUsers && self.users.count >= 19 {
                self.loadUsers(limit: self.usersToFetch)
            }
        }
    }
    
    fileprivate func loadUsers(limit: Int) {
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.label.text = "Loading..."
        progressHud.contentColor = .black
        loadingUsers = true
        usersQuery.load(limit: limit) { [unowned self] (users, error) in
            progressHud.hide(animated: true)
            if error == nil {
                guard let users = users else { return }
                self.users.append(contentsOf: users.filter({ $0.getId() != CCPClient.getCurrentUser().getId() }))
                
                DispatchQueue.main.async {
                    self.viewModel.users.append(contentsOf: users.map { ParticipantViewModelItem(user: $0) })
                    self.loadingUsers = false
                    self.tableView?.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Users", message: "Unable to load Users right now. Please try later.", actionText: "Ok")
                    self.loadingUsers = false
                }
            }
        }
    }
    
    @IBAction func didTapOnCreate(_ sender: UIBarButtonItem) {
        let channelName = channelNameTextField.text ?? ""
        
        if channelName.isEmpty {
            showAlert(title: "Empty Channel Name!", message: "Channel Name cannot be blank", actionText: "OK")
            
            return
        }
        
        if viewModel.selectedItems.isEmpty || viewModel.selectedItems.count == 1 {
            showAlert(title: "Empty Participants!", message: "Minimum 2 participants are required to create a channel.", actionText: "OK")

            return
        }
        
        CCPGroupChannel.create(name: channelName, userIds: viewModel.selectedItems.map { $0.userId }, isDistinct: false) { groupChannel, error in
            if error == nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.showAlert(title: "Error!", message: "Some error occured, please try again.", actionText: "OK")
            }
        }
    }
    
    @IBAction func didTapOnCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

