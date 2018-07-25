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
    
    fileprivate var loadingChannels = false
    fileprivate var db: SQLiteDatabase!
    var channels: [CCPGroupChannel] = []
    var groupChannelsQuery: CCPGroupChannelListQuery!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupChannelsQuery = CCPGroupChannel.createGroupChannelListQuery()
        
        do {
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("ChatDatabase.sqlite")
            db = try! SQLiteDatabase.open(path: fileURL.path)
            print("Successfully opened connection to database.")
            do {
                try db.createTable(table: Channel.self)
            } catch {
                print(db.errorMessage)
            }
        } catch SQLiteError.OpenDatabase(let message) {
            print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
        }
        
        loadChannels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        CCPClient.addChannelDelegate(channelDelegate: self, identifier: GroupChannelsViewController.string())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        CCPClient.removeChannelDelegate(identifier: GroupChannelsViewController.string())
    }
    
    fileprivate func loadChannels() {
        if let loadedChannels = self.db.getGroupChannels() {
            if loadedChannels.count > 0 {
                
                self.channels = loadedChannels
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
//        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
//        progressHud.label.text = "Loading..."
//        progressHud.contentColor = .black
        loadingChannels = true
        groupChannelsQuery.get { [unowned self] (channels, error) in
//            progressHud.hide(animated: true)
            if error == nil {
                guard let channels = channels else { return }
                self.channels = channels
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.loadingChannels = false
                }
                
                do {
                    try self.db.insertGroupChannels(channels: channels)
                } catch {
                    print(self.db.errorMessage)
                }
                
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Group Channels", message: "Unable to load Group Channels right now. Please try later.", actionText: "Ok")
                    self.loadingChannels = false
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

// MARK:- CCPChannelDelegate
extension GroupChannelsViewController: CCPChannelDelegate {
    func channelDidReceiveMessage(channel: CCPBaseChannel, message: CCPMessage) {
        if let index = channels.index(where: { (groupChannel) -> Bool in
            groupChannel.getId() == channel.getId()
        }) {
            channels.remove(at: index)
            channels.insert(channel as! CCPGroupChannel, at: 0)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func channelDidChangeTypingStatus(channel: CCPBaseChannel) {
        // Not applicable
    }
    
    func channelDidUpdateReadStatus(channel: CCPBaseChannel) {
        // Not applicable
    }
}

// MARK:- ScrollView Delegate Methods
extension GroupChannelsViewController {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (tableView.indexPathsForVisibleRows?.contains([0, channels.count - 1]) ?? false) && !loadingChannels && channels.count >= 20 {
            loadingChannels = true
            groupChannelsQuery.get { [unowned self] (channels, error) in
                if error == nil {
                    guard let channels = channels else { return }
                    self.channels.append(contentsOf: channels)
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.loadingChannels = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Can't Load Group Channels", message: "Unable to load Group Channels right now. Please try later.", actionText: "Ok")
                        self.loadingChannels = false
                    }
                }
            }
        }
    }
}


