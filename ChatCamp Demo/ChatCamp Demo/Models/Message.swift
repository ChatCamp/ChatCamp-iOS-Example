//
//  Message.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation
import MessageKit
import ChatCamp

protocol MessageImageDelegate: NSObjectProtocol {
    func messageDidUpdateWithImage(message: Message)
}

class Message: NSObject, MessageType {
    let sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    
    weak var delegate: MessageImageDelegate?
    
    init(senderOfMessage: Sender, IDOfMessage: String, sentDate date: Date, messageData: MessageData) {
        sender = senderOfMessage
        messageId = IDOfMessage
        sentDate = date
        data = messageData
    }
    
    init(fromCCPMessage ccpMessage: CCPMessage) {
        sender = Sender(id: ccpMessage.getUser().getId(), displayName: ccpMessage.getUser().getDisplayName())
        messageId = ccpMessage.getId()
        sentDate = Date(timeIntervalSince1970: TimeInterval(exactly: ccpMessage.getInsertedAt())!)
        
        let errorMessageAttributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 12),
            ]
        let attributedString = NSMutableAttributedString(string: "can't display the message", attributes: errorMessageAttributes)
        
        data = MessageData.attributedText(attributedString)
        
        super.init()
        
        if ccpMessage.getType() == "text" {
            data = MessageData.text(ccpMessage.getText())
        } else if ccpMessage.getType() == "attachment" {
            data = MessageData.photo(#imageLiteral(resourceName: "chat_image_placeholder"))
            
            DispatchQueue.global().async {
                let imageData = try? Data(contentsOf: URL(string: ccpMessage.getAttachment()!.getUrl())!)
                
                DispatchQueue.main.async {
                    self.data = MessageData.photo(UIImage(data: imageData!)!)
                    self.delegate?.messageDidUpdateWithImage(message: self)
                }
            }
        }
    }
    
    static func array(withCCPMessages ccpMessages: [CCPMessage]) -> [Message] {
        var messages = [Message]()
        
        for ccpMessage in ccpMessages {
            messages.append(Message(fromCCPMessage: ccpMessage))
        }
    
        return messages
    }
}

