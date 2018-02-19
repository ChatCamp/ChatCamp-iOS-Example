//
//  Data+ChatCamp.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 17/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

extension Data {
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
