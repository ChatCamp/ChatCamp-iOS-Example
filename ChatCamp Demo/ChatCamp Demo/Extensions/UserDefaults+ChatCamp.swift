//
//  UserDefaults+ChatCamp.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum Keys: String {
        case userIDKey = "userIDKey"
        case usernameKey = "usernameKey"
        case deviceTokenKey = "deviceTokenKey"
    }
    
    func userID() -> String? {
        return string(forKey: Keys.userIDKey.rawValue)
    }
    
    func setUserID(userID: String?) {
        set(userID, forKey: Keys.userIDKey.rawValue)
    }
    
    func username() -> String? {
        return string(forKey: Keys.usernameKey.rawValue)
    }
    
    func setUsername(username: String?) {
        set(username, forKey: Keys.usernameKey.rawValue)
    }
    
    func deviceToken() -> String? {
        return string(forKey: Keys.deviceTokenKey.rawValue)
    }
    
    func setDeviceToken(deviceToken: String?) {
        set(deviceToken, forKey: Keys.deviceTokenKey.rawValue)
    }
}
