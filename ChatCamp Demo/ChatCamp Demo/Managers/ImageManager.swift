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
    func uploadAttachment() {
        let path = Bundle.main.path(forResource: "image1", ofType: "png")!
        let url = "https://api.chatcamp.io/api/1.0/attachment_upload/"
        let img = UIImage(contentsOfFile: path)!
        let data: Data = UIImageJPEGRepresentation(img, 1)!
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            
            let userIDData = "1".data(using: .utf8)!
            let appIDData = "6359014142933725184".data(using: .utf8)!
            let channelTypeData = "group_channels".data(using: .utf8)!
            let channelIDData = "123".data(using: .utf8)!
            
            multipartFormData.append(userIDData, withName: "user_id")
            multipartFormData.append(appIDData, withName: "app_id")
            multipartFormData.append(channelTypeData, withName: "channel_type")
            multipartFormData.append(channelIDData, withName: "channel_id")
            
            multipartFormData.append(data, withName: "image1", mimeType: "image/png")
            
        }, to: url) { (encodingResult) in
            
            switch encodingResult {
            case .success(let upload, _, _):
                upload.uploadProgress(queue: DispatchQueue.main, closure: { (progress) in
                    
                    let totalBytesWritten = progress.completedUnitCount
                    let totalBytesToWrite = progress.totalUnitCount
                    
                    let percent = (Float(totalBytesWritten) / Float(totalBytesToWrite)) * 100
                    print("uploaded: \(percent)")
                })
                upload.validate()
                upload.responseJSON { response in

                    switch response.result {
                    case .success(_):

                        print("image uploaded")

                    case .failure(let error):
                        print(response.response?.statusCode)
                        print(error)
                    }

                }
            case .failure(let encodingError):
                print(encodingError)
            }
        }
    }
}
