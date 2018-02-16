//
//  CustomMessageCell.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 16/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

open class CustomMessageCell: MessageCollectionViewCell {
    
    open override class func reuseIdentifier() -> String {
        return "messagekit.cell.custommessage"
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        switch message.data {
        case .custom(let metadata):
            nameLabel.text = metadata["name"] as? String
            productCodeLabel.text = metadata["code"] as? String
            descriptionLabel.text = metadata["shortDescription"] as? String
            shippingLabel.text = metadata["shippingCost"] as? String
            imageView.image = metadata["image"] as? UIImage
        default:
            break
        }
    }
    
    // MARK:- Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var productCodeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shippingLabel: UILabel!
    
    class func bottomViewHeight() -> CGFloat {
        return 120
    }
}
