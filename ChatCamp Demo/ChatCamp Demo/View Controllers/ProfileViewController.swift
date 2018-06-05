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
        if let avatarUrl = participant?.getAvatarUrl() {
            profileImageView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            profileImageView.setImageForName(string: participant?.getDisplayName() ?? "?", circular: true, textAttributes: nil)
        }
        
        if participant?.getIsOnline() ?? false {
            onlineStatusImageView.image = #imageLiteral(resourceName: "online")
        } else {
            onlineStatusImageView.image = #imageLiteral(resourceName: "offline")
        }

        displayNameLabel.text = participant?.getDisplayName()

    }
}
