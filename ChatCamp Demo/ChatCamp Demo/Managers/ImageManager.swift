//
//  ImageManager.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 17/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation
import UIKit
import ChatCamp
import Alamofire

class ImageManager {
    class var shared: ImageManager {
        struct Singleton {
            static let instance = ImageManager()
        }
        
        return Singleton.instance
    }
}

// MARK:- Helpers
extension ImageManager {
    func uploadAttachment(imageData: Data, channelID: String, completionHandler: @escaping (Bool, String?, String?, String?) -> Void) {
        
        CCPGroupChannel.get(groupChannelId: channelID) { (groupChannel, error) in
            groupChannel?.sendAttachment(file: imageData, fileName: "\(Date().timeIntervalSince1970).jpeg", fileType: "image/jpeg", completionHandler: { (message, error) in
                print("final attachment response: \(message) with error: \(error)")
            })
        }
        
//        let url = "https://api.chatcamp.io/api/1.0/attachment_upload/"
//
//        Alamofire.upload(multipartFormData: { (multipartFormData) in
//
//            let userIDData = CCPClient.getCurrentUser().getId().data(using: .utf8)!
//            let appIDData = "6346990561630613504".data(using: .utf8)!
//            let channelTypeData = "group_channels".data(using: .utf8)!
//            let channelIDData = channelID.data(using: .utf8)!
//
//            multipartFormData.append(userIDData, withName: "user_id")
//            multipartFormData.append(appIDData, withName: "app_id")
//            multipartFormData.append(channelTypeData, withName: "channel_type")
//            multipartFormData.append(channelIDData, withName: "channel_id")
//
//            multipartFormData.append(imageData, withName: "attachment", fileName: "\(Date().timeIntervalSince1970)", mimeType: "image/jpeg")
//
//        }, to: url) { (encodingResult) in
//
//            switch encodingResult {
//            case .success(let upload, _, _):
//                upload.uploadProgress(queue: DispatchQueue.main, closure: { (progress) in
//
//                    let totalBytesWritten = progress.completedUnitCount
//                    let totalBytesToWrite = progress.totalUnitCount
//
//                    let percent = (Float(totalBytesWritten) / Float(totalBytesToWrite)) * 100
//                    print("uploaded: \(percent)")
//                })
//                upload.responseString { response in
//
//                    switch response.result {
//                    case .success(let value):
//
//                        print("image uploaded + \(response.result.debugDescription)")
//
//                        if let data = value.data(using: .utf8) {
//                            do {
//                                let data = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//
//                                if let jsonData = data,
//                                    let attachment = jsonData["attachment"] as? [String: String],
//                                    let imageURL = attachment["url"],
//                                    let imageType = attachment["type"],
//                                    let imageName = attachment["name"] {
//
//                                    completionHandler(true, imageURL, imageName, imageType)
//
//                                } else {
//                                    completionHandler(false, nil, nil, nil)
//                                }
//
//                            } catch {
//                                print(error.localizedDescription)
//                                completionHandler(false, nil, nil, nil)
//                            }
//                        }
//
//                    case .failure(let error):
//                        print("image didn't upload")
//                        print(response.response!.statusCode)
//                        print(error)
//                        completionHandler(false, nil, nil, nil)
//                    }
//
//                }
//            case .failure(let encodingError):
//                print(encodingError)
//                completionHandler(false, nil, nil, nil)
//            }
//        }
    }
}
