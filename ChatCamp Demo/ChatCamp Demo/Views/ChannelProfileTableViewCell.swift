//
//  ChannelProfileTableViewCell.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 23/04/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

class ChannelProfileTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = avatarImageView.bounds.width/2
            avatarImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var displayNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(avatarURL: String, displayName: String) {
        avatarImageView.downloadedFrom(link: avatarURL)
        displayNameLabel.text = displayName
    }

}
