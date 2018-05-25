//
//  ChannelProfileViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 23/04/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp

class ChannelProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var channelAvatarImageView: UIImageView! {
        didSet {
            channelAvatarImageView.layer.cornerRadius = channelAvatarImageView.bounds.width/2
            channelAvatarImageView.layer.masksToBounds = true
        }
    }
    
    var participants: [CCPParticipant]?
    var channel: CCPGroupChannel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Group info"
        setupTableView()
        if let avatarUrl = channel?.getAvatarUrl() {
            channelAvatarImageView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            channelAvatarImageView.setImageForName(string: channel?.getName() ?? "?", circular: true, textAttributes: nil)
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
    }
}

extension ChannelProfileViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
 
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return participants?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelProfileCell", for: indexPath) as! ChannelProfileTableViewCell
        
        if indexPath.section == 0 {
            cell.avatarImageView.setImageForName(string: channel?.getName() ?? "?", circular: true, textAttributes: nil)
            cell.displayNameLabel.text = channel?.getName()
        } else {
            if let avatarURL = participants?[indexPath.row].getAvatarUrl() {
                cell.avatarImageView.sd_setImage(with: URL(string: avatarURL), completed: nil)
            } else {
                cell.avatarImageView.setImageForName(string: participants?[indexPath.row].getDisplayName() ?? "?", circular: true, textAttributes: nil)
            }
            cell.displayNameLabel.text = participants?[indexPath.row].getDisplayName()
            if participants?[indexPath.row].getIsOnline() ?? false {
                cell.onlineStatusImageView.image = #imageLiteral(resourceName: "online")
            } else {
                cell.onlineStatusImageView.image = #imageLiteral(resourceName: "offline")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "PARTICIPANTS"
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let profileViewController = UIViewController.profileViewController()
            profileViewController.participant = participants?[indexPath.row]
            self.navigationController?.pushViewController(profileViewController, animated: true)
        }
    }
}
