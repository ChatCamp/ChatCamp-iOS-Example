//
//  ChatTableViewCell.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = 25
            avatarImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var unreadCountLabel: UILabel! {
        didSet {
            unreadCountLabel.layer.cornerRadius = unreadCountLabel.frame.width / 2
            unreadCountLabel.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var lastMessageLabel: UILabel! {
        didSet {
            lastMessageLabel.text = ""
        }
    }
    
    override func prepareForReuse() {
        avatarImageView.image = #imageLiteral(resourceName: "user_placeholder")
        nameLabel.text = ""
        messageLabel.text = ""
        lastMessageLabel.text = ""
    }
}
