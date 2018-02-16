//
//  CustomMessageCell.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 16/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

open class CustomMessageCell: MessageCollectionViewCell {
    
    open override class func reuseIdentifier() -> String { return "messagekit.cell.customcell" }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
    }
    
    class func bottomViewHeight() -> CGFloat {
        return 127
    }
}
