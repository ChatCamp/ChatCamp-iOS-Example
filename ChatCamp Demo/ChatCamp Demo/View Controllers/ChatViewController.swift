//
//  ChatViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import SafariServices
import DKImagePickerController

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
        
        setupMessageInputBar()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        loadMessages(count: 30)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CCPClient.addChannelDelegate(channelDelegate: self, identifier: ChatViewController.string())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CCPClient.removeChannelDelegate(identifier: ChatViewController.string())
    }
}

// MARK:- MessageImageDelegate
extension ChatViewController: MessageImageDelegate {
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
extension ChatViewController: CCPChannelDelegate {
    func channelDidChangeTypingStatus(channel: CCPBaseChannel) {
        // TODO: add typing status
        print("do nothing")
    }
    
    func channelDidReceiveMessage(channel: CCPBaseChannel, message: CCPMessage) {
        let mkMessage = Message(fromCCPMessage: message)
        mkMessages.append(mkMessage)
        messages.append(message)
        
        mkMessage.delegate = self
        
        messagesCollectionView.insertSections(IndexSet([mkMessages.count - 1]))
        messagesCollectionView.scrollToBottom(animated: true)
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
    
    fileprivate func setupMessageInputBar() {
        messageInputBar.sendButton.setTitle(nil, for: .normal)
        messageInputBar.sendButton.setImage(#imageLiteral(resourceName: "chat_send_button"), for: .normal)
        
        let attachmentButton = InputBarButtonItem(frame: CGRect(x: 3, y: 2, width: 30, height: 30))
        attachmentButton.setImage(#imageLiteral(resourceName: "chat_image_button"), for: .normal)
        
        attachmentButton.onTouchUpInside { (attachmentButton) in
            let photoGalleryViewController = DKImagePickerController()
            photoGalleryViewController.singleSelect = true
            photoGalleryViewController.sourceType = .photo
            
            photoGalleryViewController.didSelectAssets = { (assets: [DKAsset]) in
                // TODO: UPLOAD IMAGE, GET A URL IN RETURN, AND SEND THAT URL AS MESSAGE
                ImageManager.shared.uploadAttachment()
                // THE ABOVE LINE OF CODE DOESN'T WORK
                
                self.channel.sendMessage(text: "photo is sent", completionHandler: { (message, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            self.showAlert(title: "Unable to Send Message", message: "An error occurred while sending the message.", actionText: "Ok")
                        }
                    } else if let _ = message {
                        self.messageInputBar.inputTextView.text = ""
                    }
                })
            }
            
            self.present(photoGalleryViewController, animated: true, completion: nil)
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.leftStackView.addSubview(attachmentButton)
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
            } else if let _ = message {
                inputBar.inputTextView.text = ""
            }
        }
    }
}

// MARK:- UICollectionViewDelegate
extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        let indexPath = messagesCollectionView.indexPath(for: cell)!
        let message = mkMessages[indexPath.section]
        
        switch message.data {
        case .custom(let metadata):
            let link = metadata["ImageURL"] as! String
            let safariViewController = SFSafariViewController(url: URL(string: link)!)
            present(safariViewController, animated: true, completion: nil)
        default:
            break
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
extension ChatViewController: MessagesDisplayDelegate {
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
        default:
            return .bubble
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let ccpMessage = self.messages[indexPath.section]
        
        avatarView.initials = String(CCPClient.getCurrentUser().getDisplayName().first!)
//        avatarView.downloadedFrom(link: ccpMessage.getUser().getAvatarUrl())
    }
}
