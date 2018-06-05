//
//  GroupChannelsViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import SDWebImage
import MBProgressHUD

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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadChannels()
    }
    
    fileprivate func loadChannels() {
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.label.text = "Loading..."
        progressHud.contentColor = .black
        let groupChannelsQuery = CCPGroupChannel.createGroupChannelListQuery()
        groupChannelsQuery.get { [unowned self] (channels, error) in
            progressHud.hide(animated: true)
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
        
        (createChannelViewController.viewControllers.first as? CreateChannelViewController)?.channelCreated = {
            self.loadChannels()
        }
        
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
        
        if channel.getParticipantsCount() == 2 && channel.isDistinct() {
            CCPGroupChannel.get(groupChannelId: channel.getId()) { (groupChannel, error) in
                if let gC = groupChannel {
                    let participants = gC.getParticipants()
                    for participant in participants {
                        if participant.getId() != CCPClient.getCurrentUser().getId() {
                            cell.nameLabel.text = participant.getDisplayName()
                            if let avatarUrl = participant.getAvatarUrl() {
                                cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
                            } else {
                                cell.avatarImageView.setImageForName(string: participant.getDisplayName() ?? "?", backgroundColor: nil, circular: true, textAttributes: nil)
                            }
                        } else {
                            continue
                        }
                    }
                }
            }
        } else {
            cell.nameLabel.text = channel.getName()
            if let avatarUrl = channel.getAvatarUrl() {
                cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
            } else {
                cell.avatarImageView.setImageForName(string: channel.getName(), circular: true, textAttributes: nil)
            }
        }
        let unreadMessageCount = channel.getUnreadMessageCount()
        if unreadMessageCount > 0 {
            cell.unreadCountLabel.isHidden = false
            if unreadMessageCount < 10 {
                cell.unreadCountLabel.text = String(unreadMessageCount)
            } else {
                cell.unreadCountLabel.text = "9+"
            }
        } else {
            cell.unreadCountLabel.isHidden = true
        }
        if let message = channel.getLastMessage(), let displayName = channel.getLastMessage()?.getUser().getDisplayName() {
            if message.getType() == "text" {
                cell.messageLabel.text =  displayName + ": " + message.getText()
            } else {
                cell.messageLabel.text =  displayName + ": " + message.getType()
            }
        }
        if let lastMessage = channel.getLastMessage() {
            let lastMessageTimeInterval = lastMessage.getInsertedAt()
            cell.lastMessageLabel.text = LastMessage.getDisplayableMessage(timeInterval: Double(lastMessageTimeInterval))
        }
        
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
