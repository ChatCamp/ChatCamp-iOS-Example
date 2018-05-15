//
//  Message.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation
import ChatCamp
import Photos

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
        sender = Sender(id: ccpMessage.getUser().getId(), displayName: ccpMessage.getUser().getDisplayName()!)
        messageId = ccpMessage.getId()
        sentDate = Date(timeIntervalSince1970: TimeInterval(exactly: ccpMessage.getInsertedAt())!)
        
        let errorMessageAttributes: [NSAttributedStringKey: Any] = [
            NSFontAttributeName as NSString: UIFont.italicSystemFont(ofSize: 12),
            ]
        let attributedString = NSMutableAttributedString(string: "can't display the message", attributes: errorMessageAttributes as [String : Any])
        
        data = MessageData.attributedText(attributedString)
        
        super.init()
        
        if ccpMessage.getType() == "text" && ccpMessage.getCustomType() != "action_link" {
            data = MessageData.text(ccpMessage.getText())
        } else if ccpMessage.getType() == "attachment" {
            if ccpMessage.getAttachment()!.isImage() {
                data = MessageData.photo(#imageLiteral(resourceName: "chat_image_placeholder"))
                
                DispatchQueue.global().async {
                    if let attachement = ccpMessage.getAttachment(), let dataURL = URL(string: attachement.getUrl()), let imageData = try? Data(contentsOf: dataURL) {
                        DispatchQueue.main.async {
                            self.data = MessageData.photo(UIImage(data: imageData) ?? #imageLiteral(resourceName: "chat_image_placeholder"))
                            self.delegate?.messageDidUpdateWithImage(message: self)
                        }
                    }
                }
            } else if ccpMessage.getAttachment()?.isVideo() ?? false {
                DispatchQueue.global().async {
                    if let attachement = ccpMessage.getAttachment(), let dataURL = URL(string: attachement.getUrl()) {
                        self.data = MessageData.video(file: dataURL, thumbnail: #imageLiteral(resourceName: "chat_image_placeholder"))
                        let documentUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
                        let destinationFileUrl = documentUrl.appendingPathComponent(attachement.getName())
                        if FileManager.default.fileExists(atPath: destinationFileUrl.path) {
                            DispatchQueue.main.async {
                                self.data = MessageData.video(file: destinationFileUrl, thumbnail: ImageManager.getThumbnailFrom(path: destinationFileUrl)!)
                                self.delegate?.messageDidUpdateWithImage(message: self)
                            }
                        } else {
                            let sessionConfig = URLSessionConfiguration.default
                            let session = URLSession(configuration: sessionConfig)
                            let request = URLRequest(url: dataURL)
                            session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                                if let tempLocalUrl = tempLocalUrl, error == nil {
                                    do {
                                        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                                        DispatchQueue.main.async {
                                            self.data = MessageData.video(file: destinationFileUrl, thumbnail: ImageManager.getThumbnailFrom(path: destinationFileUrl)!)
                                            self.delegate?.messageDidUpdateWithImage(message: self)
                                        }
                                        PHPhotoLibrary.shared().performChanges({
                                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationFileUrl)
                                        }) { completed, error in
                                            if completed {
                                                print("Video is saved!")
                                            }
                                        }
                                    } catch (let writeError) {
                                        print("Error creating a file \(destinationFileUrl) : \(writeError)")
                                    }
                                } else {
                                    print("Error took place while downloading a file. Error description: %@", error?.localizedDescription);
                                }
                            }.resume()
                        }
                    }
                }
            }
            else if ccpMessage.getAttachment()?.isDocument() ?? false {
                if let attachement = ccpMessage.getAttachment(), let dataURL = URL(string: attachement.getUrl()) {
                    self.data = MessageData.document(dataURL)
                        let documentUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
                        let destinationFileUrl = documentUrl.appendingPathComponent(attachement.getName())
                        if FileManager.default.fileExists(atPath: destinationFileUrl.path) {
                            self.data = MessageData.document(destinationFileUrl)
                        } else {
                            let sessionConfig = URLSessionConfiguration.default
                            let session = URLSession(configuration: sessionConfig)
                            let request = URLRequest(url: dataURL)
                            DispatchQueue.global().async {
                                session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                                    if let tempLocalUrl = tempLocalUrl, error == nil {
                                        do {
                                            try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                                            DispatchQueue.main.async {
                                                self.data = MessageData.document(destinationFileUrl)
                                            }
                                        } catch (let writeError) {
                                            print("Error creating a file \(destinationFileUrl) : \(writeError)")
                                        }
                                    } else {
                                        print("Error took place while downloading a file. Error description: %@", error?.localizedDescription);
                                    }
                                }.resume()
                            }
                        }
                }
            }
            else {
                data = MessageData.text(ccpMessage.getAttachment()!.getUrl())
            }
        } else if ccpMessage.getType() == "text" && ccpMessage.getCustomType() == "action_link" {
            let metadata = ccpMessage.getMetadata()
            var imageURL = "http://streaklabs.in/UserImages/FitBit.jpg"
            var name = ""
            var code = ""
            var shortDescription = ""
            var shippingCost = 0
            
            let product = metadata["product"]
            if let productValue = product {
                var json: [String: Any]!
                if let jData = productValue.data(using: .utf8) {
                    do {
                        json = try JSONSerialization.jsonObject(with: jData) as? [String: Any]
                        if let url = (json?["ImageURL"] as? String) {
                            var urlString = url.replacingOccurrences(of: "\"", with: "")
                            urlString.removeFirst()
                            urlString.removeLast()
                            imageURL = urlString
                        }
                        name = json?["Name"] as? String ?? "Fitbit"
                        code = json?["Code"] as? String ?? "SP0129"
                        shortDescription = json?["ShortDescription"] as? String ?? "Fitbit logs your health data"
                        shippingCost = json?["ShippingCost"] as? Int ?? 20
                    } catch {
                        print("in error::")
                        print(error.localizedDescription)
                    }
                }
            }
            
            var messageDataDictionary: [String: Any] = [
                "ImageURL": imageURL,
                "Name": name,
                "Code": code,
                "ShortDescription": shortDescription,
                "ShippingCost": shippingCost,
                "Image": #imageLiteral(resourceName: "chat_image_placeholder")
            ]
            
            data = MessageData.custom(messageDataDictionary)
            
            URLSession.shared.dataTask(with: URL(string: imageURL)!) { data, response, error in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let image = UIImage(data: data)
                    else { return }
                DispatchQueue.main.async {
                    messageDataDictionary["Image"] = image
                    self.data = MessageData.custom(messageDataDictionary)
                    self.delegate?.messageDidUpdateWithImage(message: self)
                }
            }.resume()
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

