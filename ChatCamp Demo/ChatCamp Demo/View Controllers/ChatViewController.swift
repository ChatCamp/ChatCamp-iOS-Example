//
//  ChatViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import MessageKit

// TODO:- REMOVE CODE BELOW

let sender = Sender(id: "any_unique_id", displayName: "Steven")
let friendSender = Sender(id: "friend_id", displayName: "Kate")
let messages: [Message] = [
    Message(senderOfMessage: sender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.text("Hey, how are you?")),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
            sentDate: Date(),
            messageData: MessageData.text("I'm good. What about you?")),
    Message(senderOfMessage: sender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
            sentDate: Date(),
            messageData: MessageData.text("Great here as well. We are planning for a day trip, you in?")),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
            sentDate: Date(),
            messageData: MessageData.text("Absolutely!")),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
            sentDate: Date(),
            messageData: MessageData.photo(UIImage(named: "user_placeholder")!)),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
            sentDate: Date(),
            messageData: MessageData.emoji("Check this image.👆")),
    Message(senderOfMessage: sender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
            sentDate: Date(),
            messageData: MessageData.photo(#imageLiteral(resourceName: "sunset_image"))),
    Message(senderOfMessage: sender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.text("Seems like image are not appearing.")),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.text("Yeah, strange.")),
    Message(senderOfMessage: sender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.text("But MessageKit's documentation says that you can render images as well.")),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.text("Not sure what is happening. You have to debug I think.")),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.text("Yeah, seem like it.")),
    Message(senderOfMessage: friendSender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.emoji("😏😏😏")),
    Message(senderOfMessage: sender,
            IDOfMessage: "\(Date().timeIntervalSince1970)",
        sentDate: Date(),
        messageData: MessageData.emoji("😤"))
]

// TODO:- REMOVE CODE ABOVE

class ChatViewController: MessagesViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = friendSender.displayName
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
}

// MARK:- MessagesDataSource
extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return sender
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
}

// MARK:- MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    
}

// MARK:- MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    
}
