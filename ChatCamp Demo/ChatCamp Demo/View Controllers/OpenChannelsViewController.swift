//
//  OpenChannelsViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import SDWebImage
import MBProgressHUD

class OpenChannelsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(ChatTableViewCell.nib(), forCellReuseIdentifier: ChatTableViewCell.string())
        }
    }
    
    var channels: [CCPOpenChannel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadChannels()
    }
    
    fileprivate func loadChannels() {
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.label.text = "Loading..."
        progressHud.contentColor = .black
        let openChannelsQuery = CCPOpenChannel.createOpenChannelListQuery()
        openChannelsQuery.get { [unowned self] (channels, error) in
            progressHud.hide(animated: true)
            if error == nil {
                self.channels = channels!
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Open Channels", message: "Unable to load Open Channels right now. Please try later.", actionText: "Ok")
                }
            }
        }
    }
}

// MARK:- UITableViewDataSource
extension OpenChannelsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.string(), for: indexPath) as! ChatTableViewCell
        cell.nameLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
        
        let channel = channels[indexPath.row]
        cell.messageLabel.isHidden = true
        cell.unreadCountLabel.isHidden = true
        cell.nameLabel.text = channel.getName()
        if let avatarUrl = channel.getAvatarUrl() {
            cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            cell.avatarImageView.setImageForName(string: channel.getName(), backgroundColor: nil, circular: true, textAttributes: nil)
        }
        
        return cell
    }
}

// MARK:- UITableViewDelegate
extension OpenChannelsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userID = CCPClient.getCurrentUser().getId()
        let username = CCPClient.getCurrentUser().getDisplayName()
        
        let sender = Sender(id: userID, displayName: username!)
        let channel = channels[indexPath.row]
        channel.join() { error in
            if error == nil {
                print("Channel Joined")
                let openChannelChatViewController = OpenChannelChatViewController(channel: channel, sender: sender)
                self.navigationController?.pushViewController(openChannelChatViewController, animated: true)
            } else {
                self.showAlert(title: "Error!", message: "Unable to join this open channel. Please try again.", actionText: "Ok")
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
