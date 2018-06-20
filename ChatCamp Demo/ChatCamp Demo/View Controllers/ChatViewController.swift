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
import MobileCoreServices
import AVFoundation

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
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    let progressView = UIProgressView()
    
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
    
    fileprivate func setupNavigationItems() {
        if channel.getParticipantsCount() == 2 && channel.isDistinct() {
            navigationController?.navigationBar.items?.first?.title = ""
            CCPGroupChannel.get(groupChannelId: channel.getId()) {(groupChannel, error) in
                if let gC = groupChannel {
                    self.allParticipants = gC.getParticipants()
                    for participant in gC.getParticipants() {
                        if participant.getId() != self.sender.id {
                            self.participant = participant
                            self.title = nil
                            self.navigationItem.leftItemsSupplementBackButton = true
                            let userNameBarButtonItem = UIBarButtonItem(title: participant.getDisplayName(), style: .plain, target: self, action: #selector(self.userProfileTapped))
                            let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 35, height: 35))
                            let profileButton = UIButton()
                            profileButton.frame = CGRect(0, 0, 35, 35)
                            if let avatarUrl = participant.getAvatarUrl() {
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
                                let profileImageBarButtonItem = UIBarButtonItem(customView: profileButton)
                                self.navigationItem.leftBarButtonItems = [profileImageBarButtonItem, userNameBarButtonItem]
                            } else {
                                imageView.setImageForName(string: participant.getDisplayName() ?? "?", circular: true, textAttributes: nil)
                                let profileImageBarButtonItem = UIBarButtonItem(customView: imageView)
                                self.navigationItem.leftBarButtonItems = [profileImageBarButtonItem, userNameBarButtonItem]
                            }
                        } else {
                            continue
                        }
                    }
                }
            }
        } else {
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

extension ChatViewController {
    func updateUploadProgress(with progress: Float) {
        DispatchQueue.main.async {
            self.progressView.progress = progress
        }
    }
    
    func addProgressView() {
        progressView.progress = 0.0
        progressView.progressTintColor = UIColor(red: 48/255, green: 58/255, blue: 165/255, alpha: 1.0)
        progressView.frame = view.bounds
        messageInputBar.topStackView.addArrangedSubview(progressView)
        messageInputBar.topStackView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        messageInputBar.topStackViewPadding.bottom = 6
        messageInputBar.backgroundColor = messageInputBar.backgroundView.backgroundColor
    }
    
    func removeProgressView() {
        messageInputBar.topStackView.arrangedSubviews.first?.removeFromSuperview()
        messageInputBar.topStackViewPadding = .zero
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
                self.messagesCollectionView.scrollToBottom(animated: true)
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
                        self.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
            }
        }
    }
    
    fileprivate func setupMessageInputBar() {
        messageInputBar.sendButton.setTitle(nil, for: .normal)
        messageInputBar.sendButton.setImage(#imageLiteral(resourceName: "chat_send_button"), for: .normal)
        
        let attachmentButton = InputBarButtonItem(frame: CGRect(x: 40, y: 0, width: 30, height: 30))
        attachmentButton.setImage(#imageLiteral(resourceName: "attachment"), for: .normal)
        
        attachmentButton.onTouchUpInside { [unowned self] attachmentButton in
            self.presentAlertController()
        }
        
        let audioButton = InputBarButtonItem(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        audioButton.setImage(#imageLiteral(resourceName: "microphone"), for: .normal)
        
        audioButton.onTouchUpInside { [unowned self] audioButton in
            self.handleAudioMessageAction(audioButton: audioButton)
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 80, animated: false)
        messageInputBar.leftStackView.addSubview(attachmentButton)
        messageInputBar.leftStackView.addSubview(audioButton)
    }
    
    fileprivate func presentAlertController() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let videoCameraAction = UIAlertAction(title: "Video Camera", style: .default) { (action) in
            self.handleVideoCameraAction()
        }
        
        let photoCameraAction = UIAlertAction(title: "Photo Camera", style: .default) { (action) in
            self.handlePhotoCameraAction()
        }
        
        let photoLibraryAction = UIAlertAction(title: "Photo & Video Library", style: .default) { (action) in
            self.handleLibraryAction()
        }
        
        let documentAction = UIAlertAction(title: "Document", style: .default) { (action) in
            self.handleDocumentAction()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(videoCameraAction)
        alertController.addAction(photoCameraAction)
        alertController.addAction(photoLibraryAction)
        alertController.addAction(documentAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func handleDocumentAction() {
        let documentTypes = [kUTTypeItem as String]
        let documentController = UIDocumentMenuViewController(documentTypes: documentTypes, in: .import)
        documentController.delegate = self
        self.present(documentController, animated: true, completion: nil)
    }
    
    fileprivate func handleLibraryAction() {
        let photoGalleryViewController = DKImagePickerController()
        photoGalleryViewController.singleSelect = true
        photoGalleryViewController.sourceType = .photo
        photoGalleryViewController.showsCancelButton = true
        
        photoGalleryViewController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            self.addProgressView()
            if assets.first?.type == .photo {
                // Asset is photo type
                guard let pickedAsset = assets.first?.originalAsset else { return }
                let requestOptions = PHImageRequestOptions()
                requestOptions.deliveryMode = .fastFormat
                requestOptions.resizeMode = .fast
                requestOptions.version = .original
                PHImageManager.default().requestImageData(for: pickedAsset, options: requestOptions, resultHandler: { [unowned self] (data, string, orientation, info) in
                    if var originalData = data {
                        let image = UIImage(data: originalData)
                        originalData = AttachmentManager.shared.compressImage(image: image!)!
                        AttachmentManager.shared.uploadAttachment(data: originalData, channel: self.channel, fileName: "\(Date().timeIntervalSince1970).jpeg", fileType: "image/jpeg", uploadProgressHandler: { progress in
                            self.updateUploadProgress(with: progress)
                        }) { (_, _) in
                            self.removeProgressView()
                        }

                    } else {
                        DispatchQueue.main.async {
                            self.showAlert(title: "Unable to get image", message: "An error occurred while getting the image.", actionText: "Ok")
                            self.removeProgressView()
                        }
                    }
                })
            } else {
                // Asset is video type
                guard let pickedAsset = assets.first?.originalAsset else { return }
                let requestOptions = PHVideoRequestOptions()
                requestOptions.deliveryMode = .fastFormat
                requestOptions.version = .original
                PHImageManager.default().requestAVAsset(forVideo: pickedAsset, options: requestOptions, resultHandler: { (asset, audioMix, info) in
                    let asset = asset as? AVURLAsset
                    let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mov")
                    AttachmentManager.shared.compressVideo(inputURL: (asset?.url)!, outputURL: compressedURL) { (exportSession) in
                        guard let session = exportSession else {
                            self.removeProgressView()
                            return
                        }
                        if session.status == .completed {
                            do {
                                let compressedData = try Data(contentsOf: compressedURL)
                                AttachmentManager.shared.uploadAttachment(data: compressedData, channel: self.channel, fileName: "\(Date().timeIntervalSince1970).mov", fileType: "video/mov", uploadProgressHandler: { progress in
                                    self.updateUploadProgress(with: progress)
                                }) { (_, _) in
                                    self.removeProgressView()
                                }
                            } catch  {
                                print("exception catch at block - while uploading video")
                                self.removeProgressView()
                            }
                        }
                    }
                })
            }
        }

        self.present(photoGalleryViewController, animated: true, completion: nil)
    }

    func handlePhotoCameraAction() {
        let photoGalleryViewController = DKImagePickerController()
        photoGalleryViewController.singleSelect = true
        photoGalleryViewController.sourceType = .camera
        photoGalleryViewController.showsCancelButton = true
        
        photoGalleryViewController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            self.addProgressView()
            guard let pickedAsset = assets.first?.originalAsset else { return }
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .fastFormat
            requestOptions.resizeMode = .fast
            requestOptions.version = .original
            PHImageManager.default().requestImageData(for: pickedAsset, options: requestOptions, resultHandler: { [unowned self] (data, string, orientation, info) in
                if var originalData = data {
                    let image = UIImage(data: originalData)
                    originalData = AttachmentManager.shared.compressImage(image: image!)!
                    AttachmentManager.shared.uploadAttachment(data: originalData, channel: self.channel, fileName: "\(Date().timeIntervalSince1970).jpeg", fileType: "image/jpeg", uploadProgressHandler: { progress in
                        self.updateUploadProgress(with: progress)
                    }) { (_, _) in
                        self.removeProgressView()
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Unable to get image", message: "An error occurred while getting the image.", actionText: "Ok")
                        self.removeProgressView()
                    }
                }
            })
        }
        
        self.present(photoGalleryViewController, animated: true, completion: nil)
    }
    
    func handleVideoCameraAction() {
        let cameraViewController = UIViewController.cameraViewController()
        cameraViewController.videoProcessed = { url in
            self.addProgressView()
            let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mov")
            AttachmentManager.shared.compressVideo(inputURL: url, outputURL: compressedURL) { (exportSession) in
                guard let session = exportSession else {
                    self.removeProgressView()
                    return
                }
                if session.status == .completed {
                    do {
                        let compressedData = try Data(contentsOf: compressedURL)
                        AttachmentManager.shared.uploadAttachment(data: compressedData, channel: self.channel, fileName: "\(Date().timeIntervalSince1970).mov", fileType: "video/mov", uploadProgressHandler: { progress in
                            self.updateUploadProgress(with: progress)
                        }) { (_, _) in
                            self.removeProgressView()
                        }
                    } catch  {
                        print("exception catch at block - while uploading video")
                        self.removeProgressView()
                    }
                }
            }
        }
        present(cameraViewController, animated: true, completion: nil)
    }
    
    func handleAudioMessageAction(audioButton: InputBarButtonItem) {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        if self.audioRecorder == nil {
                            self.startRecording(audioButton: audioButton)
                        } else {
                            self.finishRecording(success: true)
                            audioButton.setImage(#imageLiteral(resourceName: "microphone"), for: .normal)
                        }
                    } else {
                        // failed to record!
                        // TODO: Show an alert here
                    }
                }
            }
        } catch {
            // Show an alert here
        }
    }
    
    func startRecording(audioButton: InputBarButtonItem) {
        let audioFilename = getDocumentsDirectory().appendingPathComponent(UUID().uuidString + ".m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            audioButton.setImage(#imageLiteral(resourceName: "stop_recording"), for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
    }
}

// MARK: AVAudioRecorderDelegate
extension ChatViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        } else {
            do {
                let audioData = try Data(contentsOf: recorder.url)
                self.addProgressView()
                AttachmentManager.shared.uploadAttachment(data: audioData, channel: self.channel, fileName: recorder.url.lastPathComponent, fileType: "audio" + "/" + "\(recorder.url.pathExtension)", uploadProgressHandler: { progress in
                    self.updateUploadProgress(with: progress)
                }) { (_, _) in
                    self.addProgressView()
                }
            }
            catch  {
                print("exception catch at block - while uploading audio message")
                self.addProgressView()
            }
        }
    }
}

// MARK: UIDocumentMenuDelegate, UIDocumentPickerDelegate
extension ChatViewController: UIDocumentMenuDelegate, UIDocumentPickerDelegate {
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        do {
            let documentData = try Data(contentsOf: url)
            self.addProgressView()
            AttachmentManager.shared.uploadAttachment(data: documentData, channel: self.channel, fileName: url.lastPathComponent, fileType: "application" + "/" + "\(url.pathExtension)", uploadProgressHandler: { progress in
                self.updateUploadProgress(with: progress)
            }) { (_, _) in
                self.addProgressView()
            }
        } catch  {
            print("exception catch at block - while uploading document attachment")
            self.addProgressView()
        }
        
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func documentMenuWasCancelled(_ documentMenu: UIDocumentMenuViewController) {
        documentMenu.dismiss(animated: true, completion: nil)
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
        case .video(let videoURL, _):
            let videoViewController = VideoViewController(videoURL: videoURL)
            self.present(videoViewController, animated: true, completion: nil)
        case .photo(let image):
            let imagePreviewViewController = UIViewController.imagePreviewViewController()
            imagePreviewViewController.image = image
            navigationController?.pushViewController(imagePreviewViewController, animated: true)
        case .document(let url):
            let documentInteractionController = UIDocumentInteractionController(url: url)
            documentInteractionController.delegate = self
            documentInteractionController.presentPreview(animated: true)
        case .audio(let audioUrl):
            if let audioView = (cell.messageContainerView.subviews.first) as? AudioView {
                audioView.playAudio(audioUrl)
            }
        default:
            break
        }
    }
}

extension ChatViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
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
        case .audio(let url):
            let configurationClosure = { (containerView: UIImageView) in
                containerView.layer.cornerRadius = 4
                containerView.layer.masksToBounds = true
                containerView.layer.borderWidth = 1
                containerView.layer.borderColor = UIColor.lightGray.cgColor

                let audioView = AudioView().loadFromNib() as! AudioView
                audioView.audioFileURL = url
                containerView.addSubview(audioView)
                audioView.fillSuperview()
            }
            return .audio(configurationClosure)
        default:
            return .bubble
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        if message.messageId == "TYPING_INDICATOR" {
            if let participant = self.channel.getTypingParticipants().first {
                if let avatarUrl = participant.getAvatarUrl() {
                    avatarView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
                } else {
                    avatarView.setImageForName(string: participant.getDisplayName() ?? "?", circular: true, textAttributes: nil)
                }
            }
            
        }
        else {
            let ccpMessage = self.messages[indexPath.section]
            if let avatarUrl = ccpMessage.getUser().getAvatarUrl() {
                avatarView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
            } else {
                avatarView.setImageForName(string: CCPClient.getCurrentUser().getDisplayName() ?? "?", circular: true, textAttributes: nil)
            }
        }
    }
}

