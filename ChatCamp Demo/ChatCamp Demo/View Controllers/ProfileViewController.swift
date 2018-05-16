//
//  ProfileViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 20/04/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp

class ProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.bounds.width/2
            profileImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var onlineStatusImageView: UIImageView!
    
    var participant: CCPParticipant?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Contact Info"
        let avatarUrl = participant?.getAvatarUrl()
        if avatarUrl != nil {
            profileImageView.downloadedFrom(link: avatarUrl!)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user_placeholder")
        }
        
        if participant?.getIsOnline() ?? false {
            onlineStatusImageView.image = #imageLiteral(resourceName: "online")
        } else {
            onlineStatusImageView.image = #imageLiteral(resourceName: "offline")
        }

        displayNameLabel.text = participant?.getDisplayName()

    }
}
