//
//  DocumentMessageCell.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 15/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

open class DocumentMessageCell: MessageCollectionViewCell {
    
    open override class func reuseIdentifier() -> String { return "messagekit.cell.documentcell" }
    
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
