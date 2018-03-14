//
//  GroupChannelsViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp

class GroupChannelsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(ChatTableViewCell.nib(), forCellReuseIdentifier: ChatTableViewCell.string())
        }
    }
    @IBOutlet weak var addChannelFAB: UIButton! {
        didSet {
            addChannelFAB.layer.cornerRadius = 30
            addChannelFAB.layer.masksToBounds = true
        }
    }
    
    var channels: [CCPGroupChannel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let groupChannelsQuery = CCPGroupChannel.createGroupChannelListQuery()
        groupChannelsQuery.get { [unowned self] (channels, error) in
            if error == nil {
                self.channels = channels!
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Group Channels", message: "Unable to load Group Channels right now. Please try later.", actionText: "Ok")
                }
            }
        }
    }
}

// MARK:- Actions
extension GroupChannelsViewController {
    @IBAction func didTapOnAddChannelFAB(_ sender: UIButton) {
        let createChannelViewController = UIViewController.createChannelViewController()
        present(createChannelViewController, animated: true, completion: nil)
    }
}

// MARK:- UITableViewDataSource
extension GroupChannelsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.string(), for: indexPath) as! ChatTableViewCell
        
        let channel = channels[indexPath.row]
        
        cell.nameLabel.text = channel.getName()
        cell.messageLabel.text = channel.getId()    // TODO: change ID to last message
        
        return cell
    }
}

// MARK:- UITableViewDelegate
extension GroupChannelsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userID = CCPClient.getCurrentUser().getId()
        let username = CCPClient.getCurrentUser().getDisplayName()
        
        let sender = Sender(id: userID, displayName: username!)
        
        let chatViewController = ChatViewController(channel: channels[indexPath.row], sender: sender)
        navigationController?.pushViewController(chatViewController, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
