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

class Message: MessageType {
    let sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    
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
        
        if ccpMessage.getType() == "text" {
            data = MessageData.text(ccpMessage.getText())
        } else if ccpMessage.getType() == "attachment" {
            data = MessageData.photo(#imageLiteral(resourceName: "chat_image_placeholder"))
            
//            if let imageURLString = (ccpMessage.getAttachment() as CCPMessage.Attachment)
//                let imageURL = URL(string: imageURLString) {
                DispatchQueue.global().async {
                    let imageData = try? Data(contentsOf: URL(string: "https://s3.amazonaws.com/chatcamp-data/6346990561630613504/group_channel/5a5f156c48bdc63ad6236929/2018-02-14/1518592488_firebase-project-settings.png")!)
                    DispatchQueue.main.async {
                        self.data = MessageData.photo(UIImage(data: imageData!)!)
                    }
                }
//            }
        } else {
            let errorMessageAttributes: [NSAttributedStringKey: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
            ]
            let attributedString = NSMutableAttributedString(string: "can't display the message", attributes: errorMessageAttributes)
            
            data = MessageData.attributedText(attributedString)
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

// MARK:- Helpers
//extension Message {
//    fileprivate func downloadedFrom(url: URL, completion: () -> UIImage? ) {
//
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            guard
//                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
//                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
//                let data = data, error == nil,
//                let image = UIImage(data: data)
//                else { return nil }
//            DispatchQueue.main.async() {
//                return image
//            }
//            }.resume()
//    }
//
//    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
//        guard let url = URL(string: link) else { return }
//        downloadedFrom(url: url, contentMode: mode)
//    }
//}

