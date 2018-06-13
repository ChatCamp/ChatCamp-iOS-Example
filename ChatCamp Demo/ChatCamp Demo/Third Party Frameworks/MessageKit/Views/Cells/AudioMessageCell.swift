//
//  AudioMessageCell.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 12/06/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

open class AudioMessageCell: MessageCollectionViewCell {
    
    open override class func reuseIdentifier() -> String { return "messagekit.cell.audiocell" }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
    }
    
    class func sideViewWidth() -> CGFloat {
        return 30
    }
    
    class func paddingHeight() -> CGFloat {
        return 10
    }
}
