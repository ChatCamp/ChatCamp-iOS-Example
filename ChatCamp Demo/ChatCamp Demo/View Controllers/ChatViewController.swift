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
import Photos
import SQLite3

class ChatViewController: MessagesViewController {
    fileprivate var participant: CCPParticipant?
    fileprivate var allParticipants: [CCPParticipant]?
    fileprivate var db: SQLiteDatabase!
    fileprivate var channel: CCPGroupChannel
    fileprivate var sender: Sender
    fileprivate var lastRead: Double
    fileprivate var lastReadSent: Double
    fileprivate var messages: [CCPMessage] = []
    fileprivate var loadingMessages: Bool
    fileprivate var mkMessages: [Message] = []
    fileprivate var previousMessagesQuery: CCPPreviousMessageListQuery
    fileprivate var partnerTyping = false
    fileprivate var messageCount: Int = 30
    var loadingDots = LoadingDots()
    let loadingDotsAnimationDelay : TimeInterval = 0.5
    
    init(channel: CCPGroupChannel, sender: Sender) {
        self.channel = channel
        self.sender = sender
        self.lastRead = 0
        self.lastReadSent = 0
        self.loadingMessages = false
        previousMessagesQuery = channel.createPreviousMessageListQuery()
        super.init(nibName: nil, bundle: nil)
        CCPGroupChannel.get(groupChannelId: channel.getId()) {(groupChannel, error) in
            if let gC = groupChannel {
                self.channel = gC
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItemsForIndividualChat()
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
                print(db.errorMessage)
            }
        } catch SQLiteError.OpenDatabase(let message) {
            print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
        }
        
        loadMessages(count: messageCount)
//        addNavigationRightBarButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CCPClient.addChannelDelegate(channelDelegate: self, identifier: ChatViewController.string())
        channel.markAsRead()
        self.lastReadSent = NSDate().timeIntervalSince1970 * 1000
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CCPClient.removeChannelDelegate(identifier: ChatViewController.string())
    }
    
    //    override func viewDidDisappear(_ animated: Bool) {
    //        super.viewDidDisappear(animated)
    //        db = nil
    //    }
//    func addNavigationRightBarButton() {
//        let barButtonItem = UIBarButtonItem(image: UIImage(named: "fab_add"),
//                                            style: .plain,
//                                            target: self,
//                                            action: #selector(addTypingText))
//        navigationItem.rightBarButtonItem = barButtonItem
//    }
    
    fileprivate func setupNavigationItemsForIndividualChat() {
        if channel.getParticipantsCount() == 2 && channel.isDistinct() {
            navigationController?.navigationBar.items?.first?.title = ""
            CCPGroupChannel.get(groupChannelId: channel.getId()) {(groupChannel, error) in
                if let gC = groupChannel {
                    self.allParticipants = gC.getParticipants()
                    for participant in gC.getParticipants() {
                        if participant.getId() != self.sender.id {
                            self.participant = participant
                            self.title = nil
                            let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
                            imageView.layer.cornerRadius = imageView.bounds.width/2
                            imageView.layer.masksToBounds = true
                            let avatarUrl = participant.getAvatarUrl()
                            if avatarUrl != nil {
                                imageView.downloadedFrom(link: avatarUrl!)
                            }
                            
                            let userNameBarButtonItem = UIBarButtonItem(title: participant.getDisplayName(), style: .plain, target: self, action: #selector(self.userProfileTapped))
                            let profileImage = UIBarButtonItem(customView: imageView)
                            
                            self.navigationItem.leftItemsSupplementBackButton = true
                            self.navigationItem.leftBarButtonItems = [profileImage, userNameBarButtonItem]
                        } else {
                            continue
                        }
                    }
                }
            }
        } else {
            navigationController?.navigationBar.items?.first?.title = ""
            let channelAvatarBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "user_placeholder"), style: .plain, target: self, action: nil)
            let channelNameBarButtonItem = UIBarButtonItem(title: channel.getName(), style: .plain, target: self, action: #selector(channelProfileButtonTapped))
            navigationItem.leftItemsSupplementBackButton = true
            navigationItem.leftBarButtonItems = [channelAvatarBarButtonItem, channelNameBarButtonItem]
        }
    }
    
    func addTypingText() {
        if partnerTyping {
            removeLoadingDots()
//            messageInputBar.topStackViewPadding = .zero
//            messageInputBar.topStackView.arrangedSubviews.first?.removeFromSuperview()
            
//            messagesCollectionView.deleteSections(IndexSet([mkMessages.count - 1]))
            mkMessages.removeLast()
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToBottom(animated: false)
        } else {
//            showLoadingDots()
        }
        partnerTyping = !partnerTyping
    }
    
    func showLoadingDots(sender: Sender) {
        if !partnerTyping {
            partnerTyping = true
            let data = MessageData.writingView(loadingDots)
            let writingMessage = Message.init(senderOfMessage: sender, IDOfMessage: "TYPING_INDICATOR", sentDate: Date(), messageData: data)
            mkMessages.append(writingMessage)
            messagesCollectionView.insertSections(IndexSet([mkMessages.count - 1]))
            messagesCollectionView.scrollToBottom(animated: true)
        }
    }
    
    func removeLoadingDots() {
        if partnerTyping {
            partnerTyping = false
            loadingDots.removeFromSuperview()
            mkMessages.removeLast()
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToBottom(animated: false)
        }
    }
    
    @objc func userProfileTapped() {
        let profileViewController = UIViewController.profileViewController()
        profileViewController.participant = self.participant
        self.navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    @objc func channelProfileButtonTapped() {
        let channelProfileViewController = UIViewController.channelProfileViewController()
        channelProfileViewController.channel = self.channel
        CCPGroupChannel.get(groupChannelId: channel.getId()) {(groupChannel, error) in
            if let gC = groupChannel {
                self.allParticipants = gC.getParticipants()
                channelProfileViewController.participants = self.allParticipants
                self.navigationController?.pushViewController(channelProfileViewController, animated: true)
            }
        }
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
        if channel.getId() == self.channel.getId() {
            if let c = channel as? CCPGroupChannel {
                if let p = c.getTypingParticipants().first {
                    if p.getId() != self.sender.id {
                        let sender = Sender(id: p.getId(), displayName: p.getDisplayName()!)
                        self.showLoadingDots(sender: sender)
                    }
                }
                else {
                    self.removeLoadingDots()
                }
            }
        }
    }
    
    func channelDidReceiveMessage(channel: CCPBaseChannel, message: CCPMessage) {
        if channel.getId() == self.channel.getId() {
            let mkMessage = Message(fromCCPMessage: message)
            self.removeLoadingDots()
            mkMessages.append(mkMessage)
            messages.append(message)
            
            mkMessage.delegate = self
            
            messagesCollectionView.insertSections(IndexSet([mkMessages.count - 1]))
            messagesCollectionView.scrollToBottom(animated: true)
        }
            
        do {
            try self.db.insertChat(channel: channel, message: message)
        } catch {
            print(self.db.errorMessage)
        }
        
    }
    
    func channelDidUpdateReadStatus(channel: CCPBaseChannel) {
        if channel.getId() == self.channel.getId() {
            if let c = channel as? CCPGroupChannel {
                if c.getReadReceipt().count > 0 {
                    var r: Double = 0
                    (_, r) = c.getReadReceipt().first!
                    for (_, time) in c.getReadReceipt() {
                        if(time < r) {
                            r = time
                        }
                    }
                    self.lastRead = r
                    DispatchQueue.main.async {
                        self.messagesCollectionView.reloadData()
//                        self.messagesCollectionView.scrollToBottom(animated: false)
                    }
                }
            }
        }
    }
}

// MARK:- Helpers
extension ChatViewController {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if ((NSDate().timeIntervalSince1970 * 1000) - self.lastReadSent) > 10000 {
            channel.markAsRead()
            self.lastReadSent = NSDate().timeIntervalSince1970 * 1000
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if messagesCollectionView.indexPathsForVisibleItems.contains([0, 0]) && !self.loadingMessages && self.mkMessages.count >= 30 {
            print("REACHED TOP")
            self.loadingMessages = true
            let count = self.messageCount
            self.previousMessagesQuery.load(limit: count, reverse: true) { (messages, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Can't Load Messages", message: "An error occurred while loading the messages. Please try again.", actionText: "Ok")
                    }
                } else if let loadedMessages = messages {
//                    let reverseChronologicalMessages = Array(loadedMessages.reversed())
                    
//                    self.messages = reverseChronologicalMessages
                    
                    for message in loadedMessages {
                        //                    let m = CCPMessage.createfromSerializedData(jsonString: message.serialize()!)
                        do {
                            try self.db.insertChat(channel: self.channel, message: message)
                            self.messages.insert(message, at: 0)
                            self.mkMessages.insert(Message(fromCCPMessage: message), at: 0)
                            self.mkMessages[0].delegate = self
                        } catch {
                            print(self.db.errorMessage)
                        }
//                        print("MEssage Serialize: \(message.serialize())")
                        //                    print("MEssage DeSerialize: \(m)")
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
                    //                    let m = CCPMessage.createfromSerializedData(jsonString: message.serialize()!)
                    do {
                        try self.db.insertChat(channel: self.channel, message: message)
                    } catch {
                        print(self.db.errorMessage)
                    }
//                    print("MEssage Serialize: \(message.serialize())")
                    //                    print("MEssage DeSerialize: \(m)")
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
    
    fileprivate func compressImage(image:UIImage) -> Data? {
        // Reducing file size to a 10th
        
        var actualHeight : CGFloat = image.size.height
        var actualWidth : CGFloat = image.size.width
        let maxHeight : CGFloat = 1280.0
        let maxWidth : CGFloat = 800.0
        var imgRatio : CGFloat = actualWidth/actualHeight
        let maxRatio : CGFloat = maxWidth/maxHeight
        var compressionQuality : CGFloat = 0.5
        
        if (actualHeight > maxHeight || actualWidth > maxWidth){
            if(imgRatio < maxRatio){
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if(imgRatio > maxRatio){
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else{
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }
        
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        guard let imageData = UIImageJPEGRepresentation(img, compressionQuality)else{
            return nil
        }
        return imageData
    }
    
    fileprivate func setupMessageInputBar() {
        messageInputBar.sendButton.setTitle(nil, for: .normal)
        messageInputBar.sendButton.setImage(#imageLiteral(resourceName: "chat_send_button"), for: .normal)
        
        let attachmentButton = InputBarButtonItem(frame: CGRect(x: 3, y: 2, width: 30, height: 30))
        attachmentButton.setImage(#imageLiteral(resourceName: "chat_image_button"), for: .normal)
        
        attachmentButton.onTouchUpInside { [unowned self] (attachmentButton) in
            let photoGalleryViewController = DKImagePickerController()
            photoGalleryViewController.singleSelect = true
            photoGalleryViewController.sourceType = .both
            
            photoGalleryViewController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
                guard assets[0].type == .photo else { return }
                
                let pickedAsset = assets[0].originalAsset!
                let requestOptions = PHImageRequestOptions()
                requestOptions.deliveryMode = .fastFormat
                requestOptions.resizeMode = .fast
                requestOptions.version = .original
                PHImageManager.default().requestImageData(for: pickedAsset, options: requestOptions, resultHandler: { [unowned self] (data, string, orientation, info) in
                    if var originalData = data {
                        let image = UIImage(data: originalData)
                        originalData = self.compressImage(image: image!)!
                        ImageManager.shared.uploadAttachment(imageData: originalData, channelID: self.channel.getId())
                        { [unowned self] (successful, imageURL, imageName, imageType) in
                            
                            if successful,
                                let urlString = imageURL,
                                let name = imageName,
                                let type = imageType {
                                
                                self.channel.sendAttachmentRaw(url: urlString, name: name, type: type, completionHandler: { [unowned self] (message, error) in
                                    if error != nil {
                                        DispatchQueue.main.async {
                                            self.showAlert(title: "Unable to Send Message", message: "An error occurred while sending the message.", actionText: "Ok")
                                        }
                                    } else if let _ = message {
                                        self.messageInputBar.inputTextView.text = ""
                                        self.channel.markAsRead()
                                        self.lastReadSent = NSDate().timeIntervalSince1970 * 1000
                                    }
                                })
                                
                            } else {
                                DispatchQueue.main.async {
                                    self.showAlert(title: "Unable to Send Message", message: "An error occurred while sending the message.", actionText: "Ok")
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showAlert(title: "Unable to get image", message: "An error occurred while getting the image.", actionText: "Ok")
                        }
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
        inputBar.inputTextView.text = ""
        channel.sendMessage(text: text) { [unowned self] (message, error) in
            inputBar.inputTextView.text = ""
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert(title: "Unable to Send Message", message: "An error occurred while sending the message.", actionText: "Ok")
                    inputBar.inputTextView.text = text
                }
            } else if let _ = message {
                self.channel.markAsRead()
                self.lastReadSent = NSDate().timeIntervalSince1970 * 1000
            }
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        if !text.isEmpty {
            channel.startTyping()
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
    
    func cellBottomReadReceiptImage(for message: MessageType, at indexPath: IndexPath) -> UIImage? {
        if message.messageId != "TYPING_INDICATOR" {
            let ccpMessage = self.messages[indexPath.section]
            if self.lastRead > Double(ccpMessage.getInsertedAt()) {
                return #imageLiteral(resourceName: "double-tick-blue")
            }
            else {
                return #imageLiteral(resourceName: "tick-grey")
            }
        }
        else {
            return #imageLiteral(resourceName: "fab_add")
        }
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        guard let dataSource = messagesCollectionView.messagesDataSource else {
            fatalError(MessageKitError.nilMessagesDataSource)
        }
        return dataSource.isFromCurrentSender(message: message) ? .messageTrailing(.zero) : .messageLeading(.zero)
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
        case .writingView(_):
            let configurationClosure = { (containerView: UIImageView) in
                containerView.layer.cornerRadius = 4
                containerView.layer.masksToBounds = true
                containerView.layer.borderWidth = 1
                containerView.layer.borderColor = UIColor.lightGray.cgColor
                
                let loadingView = LoadingDots.loadViewFromNib() as! LoadingDots
                loadingView.animate()
                containerView.addSubview(loadingView)
                containerView.fillSuperview()
            }
            return .writingView(configurationClosure)
        default:
            return .bubble
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        if message.messageId == "TYPING_INDICATOR" {
            if let participant = self.channel.getTypingParticipants().first {
                avatarView.initials = String(describing: participant.getDisplayName()!.first!)
                let avatarUrl = participant.getAvatarUrl()
                if avatarUrl != nil {
                    avatarView.downloadedFrom(link: avatarUrl!)
                }
            }
            
        }
        else {
        
            let ccpMessage = self.messages[indexPath.section]
            
            avatarView.initials = String(describing: CCPClient.getCurrentUser().getDisplayName()!.first!)
            
            let avatarUrl = ccpMessage.getUser().getAvatarUrl()
            if avatarUrl != nil {
                avatarView.downloadedFrom(link: avatarUrl!)
            }
        }
    }
}



enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

class SQLiteDatabase {
    
    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    fileprivate let dbPointer: OpaquePointer?
    
    fileprivate init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
        print("Successfully closed connection to database.")
    }
    
    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer? = nil
        // 1
        if sqlite3_open(path, &db) == SQLITE_OK {
            // 2
            return SQLiteDatabase(dbPointer: db)
        } else {
            // 3
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String.init(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
}



extension SQLiteDatabase {
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer? = nil
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        
        return statement
    }
    
    func createTable(table: SQLTable.Type) throws {
        // 1
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        // 2
        defer {
            sqlite3_finalize(createTableStatement)
        }
        // 3
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
    
    func insertChat(channel: CCPBaseChannel, message: CCPMessage) throws {
        let chat = Chat(
            messageId: message.getId() as NSString,
            channelType: (channel.isGroupChannel() ? "group" : "open") as NSString,
            channelId: channel.getId() as NSString,
            timestamp: Int32(message.getInsertedAt()),
            data: message.serialize() as! NSString)
        let insertSql = "INSERT OR REPLACE INTO Chat (messageId, channelType, channelId, timestamp, data) VALUES (?, ?, ?, ?, ?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        defer {
            sqlite3_finalize(insertStatement)
        }
        let messageId: NSString = chat.messageId
        let channelType: NSString = chat.channelType
        let channelId: NSString = chat.channelId
        let timestamp: Int32 = chat.timestamp
        let data: NSString = chat.data
        guard sqlite3_bind_text(insertStatement, 1, chat.messageId.utf8String, -1, nil) == SQLITE_OK  &&
            sqlite3_bind_text(insertStatement, 2, chat.channelType.utf8String, -1, nil) == SQLITE_OK  &&
            sqlite3_bind_text(insertStatement, 3, chat.channelId.utf8String, -1, nil) == SQLITE_OK  &&
            sqlite3_bind_int(insertStatement, 4, chat.timestamp) == SQLITE_OK  &&
            sqlite3_bind_text(insertStatement, 5, chat.data.utf8String, -1, nil) == SQLITE_OK else {
                throw SQLiteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        print("Successfully inserted row.")
    }
    
    func chat(channel: CCPBaseChannel) -> [CCPMessage]? {
        let channelType = (channel.isGroupChannel() ? "group" : "open")
        let channelId = channel.getId()
        let querySql = "SELECT * FROM Chat WHERE channelType = '\(channelType)' AND channelId = '\(channelId)' ORDER BY timestamp DESC LIMIT 30;"
        
        guard let queryStatement = try? prepareStatement(sql: querySql) else {
            return nil
        }
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        //            guard sqlite3_bind_text(queryStatement, 1, channelId, -1, nil) == SQLITE_OK  else {
        //                return nil
        //            }
        
        var m = [CCPMessage]()
        
        
        while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            //                let queryResultCol0 = sqlite3_column_text(queryStatement, 0)
            //                let messageId = String(cString: queryResultCol0!) as NSString
            //
            //                let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
            //                let channelType = String(cString: queryResultCol1!) as NSString
            //
            //                let queryResultCol2 = sqlite3_column_text(queryStatement, 2)
            //                let channelId = String(cString: queryResultCol2!) as NSString
            //
            //                let timestamp = sqlite3_column_int(queryStatement, 3)
            
            let queryResultCol4 = sqlite3_column_text(queryStatement, 4)
            let data = String(cString: queryResultCol4!) as NSString
            print("HERE::: \(data)")
            
            let cm = CCPMessage.createfromSerializedData(jsonString: data as! String)
            m.append(cm!)
            
        }
        
        return m
        
    }
}

struct Chat {
    let messageId: NSString
    let channelType: NSString
    let channelId: NSString
    let timestamp: Int32
    let data: NSString
}

protocol SQLTable {
    static var createStatement: String { get }
}

extension Chat: SQLTable {
    static var createStatement: String {
        return """
        CREATE TABLE IF NOT EXISTS Chat(
        messageId TEXT PRIMARY KEY NOT NULL,
        channelType TEXT NOT NULL,
        channelId TEXT NOT NULL,
        timestamp INT NOT NULL,
        data TEXT NOT NULL
        ); CREATE IF NOT EXISTS INDEX messageId_1 Chat(messageId);
        CREATE IF NOT EXISTS INDEX channelType_2 Chat(channelType);
        CREATE IF NOT EXISTS INDEX channelId_3 Chat(channelId);
        CREATE IF NOT EXISTS INDEX timestamp_4 Chat(timestamp);
        """
    }
}

