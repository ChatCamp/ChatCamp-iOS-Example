//
//  Message.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation
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
            data = MessageData.photo(#imageLiteral(resourceName: "chat_image_placeholder"))
            
            DispatchQueue.global().async {
                let imageData = try? Data(contentsOf: URL(string: ccpMessage.getAttachment()!.getUrl())!)
                
                DispatchQueue.main.async {
                    self.data = MessageData.photo(UIImage(data: imageData!)!)
                    self.delegate?.messageDidUpdateWithImage(message: self)
                }
            }
        } else if ccpMessage.getType() == "text" && ccpMessage.getCustomType() == "action_link" {
//            let customAction = ccpMessage.getCustomType()
            let metadata = ccpMessage.getMetadata()
            
            let metadata1: [String: Any] = ["product":[
                "ImageURL": ["http://streaklabs.in/UserImages/FitBit.jpg"],
                "Name": "Fitbit",
                "Code": "SP0129",
                "ShortDescription": "Fitbit logs your health data",
                "ShippingCost": 20
                ]]
            
            let product: [String: Any] = metadata1["product"] as! [String: Any]
            
            let link = (product["ImageURL"] as! [String])[0]
            let title = product["Name"] as! String
            let code = "Code: \((product["Code"] as! String))"
            let shortDescription = product["ShortDescription"] as! String
            let shippingCost = "₹ \(product["ShippingCost"] as! Int) shipping cost"
            
            var messageDataDictionary: [String: Any] = [
                "ImageURL": link,
                "Name": title,
                "Code": code,
                "ShortDescription": shortDescription,
                "ShippingCost": shippingCost,
                "Image": #imageLiteral(resourceName: "chat_image_placeholder")
            ]
            
            data = MessageData.custom(messageDataDictionary)
            
            URLSession.shared.dataTask(with: URL(string: link)!) { data, response, error in
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

