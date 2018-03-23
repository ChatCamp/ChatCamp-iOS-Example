//
//  WritingMessageCell.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 23/03/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

open class WritingMessageCell: MessageCollectionViewCell {
    
    open override class func reuseIdentifier() -> String { return "messagekit.cell.writingCell" }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
    }
}
