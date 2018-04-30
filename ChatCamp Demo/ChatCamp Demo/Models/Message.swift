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
//        super.init()
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
            } else if ccpMessage.getAttachment()?.getType().range(of: "video") != nil {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                    let newObj = avurlAsset as! AVURLAsset
                    self.data = MessageData.video(file: newObj.url, thumbnail: #imageLiteral(resourceName: "chat_image_placeholder"))
                })
                DispatchQueue.global().async {
                    if let attachement = ccpMessage.getAttachment(), let dataURL = URL(string: attachement.getUrl()) {
                        let documentUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
                        let destinationFileUrl = documentUrl.appendingPathComponent(attachement.getName())
                        let sessionConfig = URLSessionConfiguration.default
                            let session = URLSession(configuration: sessionConfig)
                            let request = URLRequest(url: dataURL)
                            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                                if let tempLocalUrl = tempLocalUrl, error == nil {
                                    // Success
                                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                                        print("Successfully downloaded. Status code: \(statusCode)")
                                    }

                                        do {
                                            try FileManager.default.removeItem(at: destinationFileUrl)
                                            try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                                            PHPhotoLibrary.shared().performChanges({
                                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationFileUrl)
                                            }) { completed, error in
                                                if completed {
                                                    print("Video is saved!")
                                                    let fetchOptions = PHFetchOptions()
                                                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                                    
                                                    // After uploading we fetch the PHAsset for most recent video and then get its current location url
                                                    
                                                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                                                    PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                                                        let newObj = avurlAsset as! AVURLAsset
                                                        print(newObj.url)
                                                        DispatchQueue.main.async {

                                                            self.data = MessageData.video(file: newObj.url, thumbnail: ImageManager.getThumbnailFrom(path: newObj.url)!)
                                                            self.delegate?.messageDidUpdateWithImage(message: self)
                                                        }
                                                    })
                                                }
                                            }
                                        } catch (let writeError) {
                                            print("Error creating a file \(destinationFileUrl) : \(writeError)")
                                        }
                                    
                                    } else {
                                        print("Error took place while downloading a file. Error description: %@", error?.localizedDescription);
                                    }
                            }
                            task.resume()
                    }
                }
            }
            else {
                data = MessageData.text(ccpMessage.getAttachment()!.getUrl())
            }
        } else if ccpMessage.getType() == "text" && ccpMessage.getCustomType() == "action_link" {
//            let customAction = ccpMessage.getCustomType()
            let metadata = ccpMessage.getMetadata()
            
//            let metadata1: [String: Any] = ["product":[
//                "ImageURL": ["http://streaklabs.in/UserImages/FitBit.jpg"],
//                "Name": "Fitbit",
//                "Code": "SP0129",
//                "ShortDescription": "Fitbit logs your health data",
//                "ShippingCost": 20
//                ]]
            
//            let product: [String: Any] = metadata1["product"] as! [String: Any]
//            let link = (product["ImageURL"] as! [String])[0]
//            let title = product["Name"] as! String
//            let code = "Code: \((product["Code"] as! String))"
//            let shortDescription = product["ShortDescription"] as! String
//            let shippingCost = "₹ \(product["ShippingCost"] as! Int) shipping cost"

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

