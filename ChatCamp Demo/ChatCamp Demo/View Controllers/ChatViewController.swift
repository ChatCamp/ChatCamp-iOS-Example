//
//  ChatViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import MessageKit
import ChatCamp

class ChatViewController: MessagesViewController {
    fileprivate var channel: CCPGroupChannel
    fileprivate var sender: Sender
    fileprivate var messages: [CCPMessage] = []
    
    fileprivate var mkMessages: [Message] = []
    
    init(channel: CCPGroupChannel, sender: Sender) {
        self.channel = channel
        self.sender = sender
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = channel.getName()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        loadMessages(count: 50)
    }
}

// MARK:- Helpers
extension ChatViewController {
    fileprivate func loadMessages(count: Int) {
        let previousMessagesQuery = channel.createPreviousMessageListQuery()
        previousMessagesQuery.load(limit: count, reverse: true) { (messages, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Messages", message: "An error occurred while loading the messages. Please try again.", actionText: "Ok")
                }
            } else if let loadedMessages = messages {
                let reverseChronologicalMessages = Array(loadedMessages.reversed())
                
                self.messages = reverseChronologicalMessages
                self.mkMessages = Message.array(withCCPMessages: reverseChronologicalMessages)
                
                DispatchQueue.main.async {
                    self.messagesCollectionView.reloadData()
                }
            }
        }
    }
}

// MARK:- MessageInputBarDelegate
extension ChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        channel.sendMessage(text: text) { (message, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert(title: "Unable to Send Message", message: "An error occurred while sending the message.", actionText: "Ok")
                }
            } else if let sentMessage = message {
                inputBar.inputTextView.text = ""
                
                self.messages.append(sentMessage)
                self.mkMessages.append(Message(fromCCPMessage: sentMessage))
                
                DispatchQueue.main.async {
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom(animated: true)
                }
            }
        }
    }
}

// MARK:- MessagesDataSource
extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return sender
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mkMessages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return mkMessages[indexPath.section]
    }
}

// MARK:- MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {

}

// MARK:- MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    
}


// TODO:- REMOVE CODE BELOW

//let sender = Sender(id: "any_unique_id", displayName: "Steven")
//let friendSender = Sender(id: "friend_id", displayName: "Kate")
 /*
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
*/
// TODO:- REMOVE CODE ABOVE
