//
//  OpenChannelChatViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 28/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import SafariServices
import SQLite3

class OpenChannelChatViewController: MessagesViewController {
    
    fileprivate var db: SQLiteDatabase!
    fileprivate var channel: CCPOpenChannel
    fileprivate var sender: Sender
    fileprivate var mkMessages: [Message] = []
    fileprivate var messages: [CCPMessage] = []
    fileprivate var loadingMessages: Bool
    fileprivate var previousMessagesQuery: CCPPreviousMessageListQuery
    fileprivate var messageCount: Int = 30
    
    init(channel: CCPOpenChannel, sender: Sender) {
        self.channel = channel
        self.sender = sender
        previousMessagesQuery = channel.createPreviousMessageListQuery()
        self.loadingMessages = false
        super.init(nibName: nil, bundle: nil)
        CCPOpenChannel.get(openChannelId: channel.getId()) {(openChannel, error) in
            if let openChannel = openChannel {
                self.channel = openChannel
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        channel.leave() { error in
            if error == nil {
                print("Channel Left")
            } else {
                print("Channel Leave Error")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        setupMessageInputBar()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        do {
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("ChatDatabase.sqlite")
            db = try! SQLiteDatabase.open(path: fileURL.path)
            print("Successfully opened connection to database.")
            do {
                try db.createTable(table: Chat.self)
            } catch {
                print("could not create DB table")
            }
        } catch SQLiteError.OpenDatabase(let message) {
            print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
        }
        
        loadMessages(count: messageCount)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        CCPClient.addChannelDelegate(channelDelegate: self, identifier: OpenChannelChatViewController.string())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CCPClient.removeChannelDelegate(identifier: OpenChannelChatViewController.string())
    }
}

// MARK:- MessagesDataSource
extension OpenChannelChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return sender
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mkMessages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return mkMessages[indexPath.section]
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        guard let dataSource = messagesCollectionView.messagesDataSource else {
            fatalError(MessageKitError.nilMessagesDataSource)
        }
        return dataSource.isFromCurrentSender(message: message) ? .messageTrailing(.zero) : .messageLeading(.zero)
    }
}

// MARK:- MessagesLayoutDelegate
extension OpenChannelChatViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func widthForMedia(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return view.bounds.width / 2
    }
    
    func heightForMedia(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        switch message.data {
        case .photo(let image):
            let height = image.size.height * view.bounds.width / (2 * image.size.width)
            
            return height
        default:
            return view.bounds.width / 2
        }
    }
    
    func widthForImageInCustom(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return view.bounds.width / 2
    }
    
    func heightForImageInCustom(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        switch message.data {
        case .custom(let metadata):
            let image = metadata["Image"] as! UIImage
            let height = image.size.height * view.bounds.width / (2 * image.size.width)
            
            return height
        default:
            return view.bounds.width / 2
        }
    }
}

// MARK:- MessagesDisplayDelegate
extension OpenChannelChatViewController: MessagesDisplayDelegate {
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let message = mkMessages[indexPath.section]
        
        switch message.data {
        case .photo(_):
            let configurationClosure = { (containerView: UIImageView) in
                let imageMask = UIImageView()
                imageMask.image = MessageStyle.bubble.image
                imageMask.frame = containerView.bounds
                containerView.mask = imageMask
                containerView.contentMode = .scaleAspectFill
            }
            return .custom(configurationClosure)
        case .custom(let metadata):
            let configurationClosure = { (containerView: UIImageView) in
                
                containerView.layer.cornerRadius = 4
                containerView.layer.masksToBounds = true
                containerView.layer.borderWidth = 1
                containerView.layer.borderColor = UIColor.lightGray.cgColor
                
                let customView = CustomMessageContentView().loadFromNib() as! CustomMessageContentView
                
                customView.nameLabel.text = metadata["Name"] as? String
                customView.codeLabel.text = metadata["Code"] as? String
                customView.descriptionLabel.text = metadata["ShortDescription"] as? String
                customView.shippingLabel.text = metadata["ShippingCost"] as? String
                customView.imageView.image = metadata["Image"] as? UIImage
                
                containerView.addSubview(customView)
                customView.fillSuperview()
            }
            return .custom(configurationClosure)
        case .document(let url):
            let configurationClosure = { (containerView: UIImageView) in
                containerView.layer.cornerRadius = 4
                containerView.layer.masksToBounds = true
                containerView.layer.borderWidth = 1
                containerView.layer.borderColor = UIColor.lightGray.cgColor
                
                let documentView = DocumentView().loadFromNib() as! DocumentView
                documentView.documentNameLabel.text = url.lastPathComponent
                containerView.addSubview(documentView)
                documentView.fillSuperview()
            }
            return .document(configurationClosure)
        default:
            return .bubble
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let ccpMessage = self.messages[indexPath.section]
        if let avatarUrl = ccpMessage.getUser().getAvatarUrl() {
            avatarView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            avatarView.setImageForName(string: CCPClient.getCurrentUser().getDisplayName() ?? "?", circular: true, textAttributes: nil)
        }
    }
}

// MARK:- MessageCellDelegate
extension OpenChannelChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        let indexPath = messagesCollectionView.indexPath(for: cell)!
        let message = mkMessages[indexPath.section]
        
        switch message.data {
        case .custom(let metadata):
            let link = metadata["ImageURL"] as! String
            let safariViewController = SFSafariViewController(url: URL(string: link)!)
            present(safariViewController, animated: true, completion: nil)
        case .video(let videoURL, let thumbnail):
            let videoViewController = VideoViewController(videoURL: videoURL)
            self.present(videoViewController, animated: true, completion: nil)
        case .photo(let image):
            let imagePreviewViewController = UIViewController.imagePreviewViewController()
            imagePreviewViewController.image = image
            navigationController?.pushViewController(imagePreviewViewController, animated: true)
//        case .document(let url):
//            let documentInteractionController = UIDocumentInteractionController(url: url)
//            documentInteractionController.delegate = self
//            documentInteractionController.presentPreview(animated: true)
        default:
            break
        }
    }
}

// MARK:- MessageInputBarDelegate
extension OpenChannelChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        channel.sendMessage(text: text) { [unowned self] (message, error) in
            inputBar.inputTextView.text = ""
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert(title: "Unable to Send Message", message: "An error occurred while sending the message.", actionText: "Ok")
                    inputBar.inputTextView.text = text
                }
            } else if let _ = message {
                // message sent successfully
            }
        }
    }
}

// MARK:- MessageImageDelegate
extension OpenChannelChatViewController: MessageImageDelegate {
    func messageDidUpdateWithImage(message: Message) {
        if let index = mkMessages.index(of: message) {
            let indexPath = IndexPath(row: 0, section: index)
            
            if messagesCollectionView.indexPathsForVisibleItems.contains(indexPath) {
                messagesCollectionView.reloadItems(at: [indexPath])
            }
        }
    }
}

// MARK:- CCPChannelDelegate
extension OpenChannelChatViewController: CCPChannelDelegate {
    func channelDidReceiveMessage(channel: CCPBaseChannel, message: CCPMessage) {
        if channel.getId() == self.channel.getId() {
            let mkMessage = Message(fromCCPMessage: message)
            mkMessages.append(mkMessage)
            messages.append(message)
            
            mkMessage.delegate = self
            
            messagesCollectionView.insertSections(IndexSet([mkMessages.count - 1]))
            messagesCollectionView.scrollToBottom(animated: true)
        }
        
        do {
            try self.db.insertChat(channel: channel, message: message)
        } catch {
            print("Error: Could not insert received message")
        }
    }
    
    func channelDidChangeTypingStatus(channel: CCPBaseChannel) {
        // Not applicable
    }
    
    func channelDidUpdateReadStatus(channel: CCPBaseChannel) {
        // Not applicable
    }
}

// MARK: Scroll View Delegate Methods
extension OpenChannelChatViewController {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if messagesCollectionView.indexPathsForVisibleItems.contains([0, 0]) && !self.loadingMessages && self.mkMessages.count >= 30 {
            self.loadingMessages = true
            let count = self.messageCount
            self.previousMessagesQuery.load(limit: count, reverse: true) { (messages, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Can't Load Messages", message: "An error occurred while loading the messages. Please try again.", actionText: "Ok")
                    }
                } else if let loadedMessages = messages {
                    for message in loadedMessages {
                        do {
                            try self.db.insertChat(channel: self.channel, message: message)
                            self.messages.insert(message, at: 0)
                            self.mkMessages.insert(Message(fromCCPMessage: message), at: 0)
                            self.mkMessages[0].delegate = self
                        } catch {
                            print("Error, Scroll View: Could not insert message in DB")
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToItem(at:IndexPath(row: 0, section: count - 1), at: .top, animated: false)
                        self.loadingMessages = false
                    }
                }
            }
        }
    }
}

// MARK: Helper Methods
extension OpenChannelChatViewController {
    fileprivate func setupMessageInputBar() {
        messageInputBar.sendButton.setTitle(nil, for: .normal)
        messageInputBar.sendButton.setImage(#imageLiteral(resourceName: "chat_send_button"), for: .normal)
        
        //        let attachmentButton = InputBarButtonItem(frame: CGRect(x: 3, y: 2, width: 30, height: 30))
        //        attachmentButton.setImage(#imageLiteral(resourceName: "attachment"), for: .normal)
        //
        //        attachmentButton.onTouchUpInside { [unowned self] attachmentButton in
        //            self.presentAlertController()
        //        }
        //
        //        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        //        messageInputBar.leftStackView.addSubview(attachmentButton)
    }
    
    fileprivate func setupNavigationItems() {
        navigationController?.navigationBar.items?.first?.title = ""
        navigationItem.leftItemsSupplementBackButton = true
        let channelNameBarButtonItem = UIBarButtonItem(title: channel.getName(), style: .plain, target: self, action: #selector(channelProfileButtonTapped))
        
        let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 35, height: 35))
        let profileButton = UIButton()
        profileButton.frame = CGRect(0, 0, 35, 35)
        if let avatarUrl = channel.getAvatarUrl() {
            imageView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
            if let image = imageView.image {
                UIGraphicsBeginImageContextWithOptions(profileButton.frame.size, false, image.scale)
                let rect  = CGRect(0, 0, profileButton.frame.size.width, profileButton.frame.size.height)
                UIBezierPath(roundedRect: rect, cornerRadius: rect.width/2).addClip()
                image.draw(in: rect)
                
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                let color = UIColor(patternImage: newImage!)
                profileButton.backgroundColor = color
            } else {
                let color = UIColor(patternImage: UIImage(named: "avatar_placeholder")!)
                profileButton.backgroundColor = color
            }
            profileButton.layer.cornerRadius = 0.5 * profileButton.bounds.size.width
            let channelAvatarBarButtonItem = UIBarButtonItem(customView: profileButton)
            navigationItem.leftBarButtonItems = [channelAvatarBarButtonItem, channelNameBarButtonItem]
        } else {
            imageView.setImageForName(string: channel.getName(), circular: true, textAttributes: nil)
            let channelAvatarBarButtonItem = UIBarButtonItem(customView: imageView)
            navigationItem.leftBarButtonItems = [channelAvatarBarButtonItem, channelNameBarButtonItem]
        }
    }
    
    @objc func channelProfileButtonTapped() {
        let channelProfileViewController = UIViewController.channelProfileViewController()
        //        channelProfileViewController.channel = self.channel
//        CCPGroupChannel.get(groupChannelId: channel.getId()) {(groupChannel, error) in
//            if let gC = groupChannel {
//                //                self.allParticipants = gC.getParticipants()
//                //                channelProfileViewController.participants = self.allParticipants
//                self.navigationController?.pushViewController(channelProfileViewController, animated: true)
//            }
//        }
    }
    
    fileprivate func loadMessages(count: Int) {
        var cachedMessages: [CCPMessage]?
        if let loadedMessages = self.db.chat(channel: self.channel) {
            cachedMessages = loadedMessages
            let reverseChronologicalMessages = Array(loadedMessages.reversed())
            self.messages = reverseChronologicalMessages
            self.mkMessages = Message.array(withCCPMessages: reverseChronologicalMessages)

            for message in self.mkMessages {
                message.delegate = self
            }

            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: false)
            }
        }
        
        previousMessagesQuery.load(limit: count, reverse: true) { (messages, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Messages", message: "An error occurred while loading the messages. Please try again.", actionText: "Ok")
                }
            } else if let loadedMessages = messages {
                let reverseChronologicalMessages = Array(loadedMessages.reversed())
                self.messages = reverseChronologicalMessages
                for message in self.messages {
                    do {
                        try self.db.insertChat(channel: self.channel, message: message)
                    } catch {
                        print("Error: could not insert chat")
                    }
                }
                
                if !(cachedMessages != nil && cachedMessages?.first?.getId() == loadedMessages.first?.getId()) {
                    self.mkMessages = Message.array(withCCPMessages: reverseChronologicalMessages)

                    for message in self.mkMessages {
                        message.delegate = self
                    }
                    
                    DispatchQueue.main.async {
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToBottom(animated: false)
                    }
                }
            }
        }
    }
}
