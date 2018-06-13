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
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        let audioView = (self.messageContainerView.subviews.first) as? AudioView
        audioView?.audioPlayer = nil
        audioView?.displayLink = nil
        audioView?.audioTimeLabel.text = nil
        audioView?.audioTimeSlider.removeTarget(nil, action: nil, for: .allEvents)
        audioView?.audioTimeSlider.isHidden = true
        audioView?.playButton.isHidden = true
    }
}
