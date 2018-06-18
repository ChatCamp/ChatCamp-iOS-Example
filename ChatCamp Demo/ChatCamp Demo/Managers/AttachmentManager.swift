//
//  AttachmentManager.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 17/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation
import UIKit
import ChatCamp
import Alamofire
import Photos

class AttachmentManager {
    class var shared: AttachmentManager {
        struct Singleton {
            static let instance = AttachmentManager()
        }
        
        return Singleton.instance
    }
}

// MARK:- Helpers
extension AttachmentManager {
    
    func uploadAttachment(data: Data, channel: CCPBaseChannel, fileName: String, fileType: String, completionHandler: @escaping (CCPMessage?, Error?) -> Void) {
        if channel.isGroupChannel() {
            CCPGroupChannel.get(groupChannelId: channel.getId()) { (groupChannel, error) in
                groupChannel?.sendAttachment(file: data, fileName: fileName, fileType: fileType, completionHandler: { (message, error) in
                    print("final attachment response: \(message) with error: \(error)")
                    completionHandler(message, error)
                })
            }
        } else if channel.isOpenChannel() {
            CCPOpenChannel.get(openChannelId: channel.getId()) { (groupChannel, error) in
                groupChannel?.sendAttachment(file: data, fileName: fileName, fileType: fileType, completionHandler: { (message, error) in
                    print("final attachment response: \(message) with error: \(error)")
                    completionHandler(message, error)
                })
            }
        } else {
            // Do nothing for now.
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
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    func compressImage(image:UIImage) -> Data? {
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
}
