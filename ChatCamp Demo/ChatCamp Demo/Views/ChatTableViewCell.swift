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
    @IBOutlet weak var accessoryLabel: UILabel!
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
    
    var user: ParticipantViewModelItem? {
        didSet {
            nameLabel?.text = user?.displayName
            if let avatarUrl = user?.avatarURL {
                avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
            } else {
                avatarImageView.setImageForName(string: user?.displayName ?? "?", circular: true, textAttributes: nil)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarImageView.image = #imageLiteral(resourceName: "user_placeholder")
        nameLabel.text = ""
        messageLabel.text = ""
        lastMessageLabel.text = ""
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // update UI
        accessoryType = selected ? .checkmark : .none
    }
}
