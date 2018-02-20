/*
 MIT License

 Copyright (c) 2017-2018 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
import UIKit

/// A intermediate context used to store recently calculated values used by
/// the `MessagesCollectionViewFlowLayout` object to reduce redundant calculations.
final class MessageIntermediateLayoutAttributes {

    // Message
    var message: MessageType
    var indexPath: IndexPath
    
    // Cell
    var itemHeight: CGFloat = 0
    var cellFrame: CGRect = .zero

    // AvatarView
    var avatarPosition = AvatarPosition(horizontal: .cellLeading, vertical: .cellBottom)
    var avatarSize: CGSize = .zero
    
    lazy var avatarFrame: CGRect = {
        
        guard self.avatarSize != .zero else { return .zero }
        
        var origin = CGPoint.zero
        
        switch self.avatarPosition.horizontal {
        case .cellLeading:
            break
        case .cellTrailing:
            origin.x = self.cellFrame.width - self.avatarSize.width
        case .natural:
            fatalError(MessageKitError.avatarPositionUnresolved)
        }
        
        switch self.avatarPosition.vertical {
        case .cellTop:
            break
        case .cellBottom:
            origin.y = self.cellFrame.height - self.avatarSize.height
        case .messageTop:
            origin.y = self.messageContainerFrame.minY
        case .messageBottom:
            origin.y = self.messageContainerFrame.maxY - self.avatarSize.height
        case .messageCenter:
            origin.y = self.messageContainerFrame.midY - (self.avatarSize.height/2)
        }
        
        return CGRect(origin: origin, size: self.avatarSize)
        
    }()

    // MessageContainerView
    var messageContainerSize: CGSize = .zero
    var messageContainerMaxWidth: CGFloat = 0
    var messageContainerPadding: UIEdgeInsets = .zero
    var messageLabelInsets: UIEdgeInsets = .zero
    
    lazy var messageContainerFrame: CGRect = {
        
        guard self.messageContainerSize != .zero else { return .zero }
        
        var origin: CGPoint = .zero
        origin.y = self.topLabelSize.height + self.messageContainerPadding.top + self.topLabelVerticalPadding
        
        switch self.avatarPosition.horizontal {
        case .cellLeading:
            origin.x = self.avatarSize.width + self.messageContainerPadding.left
        case .cellTrailing:
            origin.x = self.cellFrame.width - self.avatarSize.width - self.messageContainerSize.width - self.messageContainerPadding.right
        case .natural:
            fatalError(MessageKitError.avatarPositionUnresolved)
        }
        
        return CGRect(origin: origin, size: self.messageContainerSize)
        
    }()
    
    // Cell Top Label
    var topLabelAlignment: LabelAlignment = .cellLeading(.zero)
    var topLabelSize: CGSize = .zero
    var topLabelMaxWidth: CGFloat = 0
    
    lazy var topLabelFrame: CGRect = {
        
        guard self.topLabelSize != .zero else { return .zero }
        
        var origin = CGPoint.zero
        
        origin.y = self.topLabelPadding.top
        
        switch self.topLabelAlignment {
        case .cellLeading:
            origin.x = self.topLabelPadding.left
        case .cellCenter:
            origin.x = (self.cellFrame.width/2) + self.topLabelPadding.left - self.topLabelPadding.right
        case .cellTrailing:
            origin.x = self.cellFrame.width - self.topLabelSize.width - self.topLabelPadding.right
        case .messageLeading:
            origin.x = self.messageContainerFrame.minX + self.topLabelPadding.left
        case .messageTrailing:
            origin.x = self.messageContainerFrame.maxX - self.topLabelSize.width - self.topLabelPadding.right
        }
        
        return CGRect(origin: origin, size: self.topLabelSize)
        
    }()

    // Cell Bottom Label
    var bottomLabelAlignment: LabelAlignment = .cellTrailing(.zero)
    var bottomLabelSize: CGSize = .zero
    var bottomLabelMaxWidth: CGFloat = 0
    
    lazy var bottomLabelFrame: CGRect = {
        
        guard self.bottomLabelSize != .zero else { return .zero }
        
        var origin: CGPoint = .zero
        
        origin.y = self.messageContainerFrame.maxY + self.messageContainerPadding.bottom + self.bottomLabelPadding.top
        
        switch self.bottomLabelAlignment {
        case .cellLeading:
            origin.x = self.bottomLabelPadding.left
        case .cellCenter:
            origin.x = (self.cellFrame.width/2) + self.bottomLabelPadding.left - self.bottomLabelPadding.right
        case .cellTrailing:
            origin.x = self.cellFrame.width - self.bottomLabelSize.width - self.bottomLabelPadding.right
        case .messageLeading:
            origin.x = self.messageContainerFrame.minX + self.bottomLabelPadding.left
        case .messageTrailing:
            origin.x = self.messageContainerFrame.maxX - self.bottomLabelSize.width - self.bottomLabelPadding.right
        }
        
        return CGRect(origin: origin, size: self.bottomLabelSize)

    }()
    
    // MARK: - Initializer
    
    init(message: MessageType, indexPath: IndexPath) {
        self.message = message
        self.indexPath = indexPath
    }

}

// MARK: - Helpers

extension MessageIntermediateLayoutAttributes {
    
    var bottomLabelPadding: UIEdgeInsets {
        return bottomLabelAlignment.insets
    }
    
    var bottomLabelVerticalPadding: CGFloat {
        return bottomLabelPadding.top + bottomLabelPadding.bottom
    }
    
    var bottomLabelHorizontalPadding: CGFloat {
        return bottomLabelPadding.left + bottomLabelPadding.right
    }
    
    var topLabelPadding: UIEdgeInsets {
        return topLabelAlignment.insets
    }
    
    var topLabelVerticalPadding: CGFloat {
        return topLabelPadding.top + topLabelPadding.bottom
    }
    
    var topLabelHorizontalPadding: CGFloat {
        return topLabelPadding.left + topLabelPadding.right
    }
    
    var messageLabelVerticalInsets: CGFloat {
        return messageLabelInsets.top + messageLabelInsets.bottom
    }
    
    var messageLabelHorizontalInsets: CGFloat {
        return messageLabelInsets.left + messageLabelInsets.right
    }
    
    var messageVerticalPadding: CGFloat {
        return messageContainerPadding.top + messageContainerPadding.bottom
    }
    
    var messageHorizontalPadding: CGFloat {
        return messageContainerPadding.left + messageContainerPadding.right
    }

}
