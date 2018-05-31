//
//  LastMessage.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 31/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

class LastMessage {
    static func getDisplayableMessage(timeInterval: Double) -> String {
        let lastMessageDate = Date(timeIntervalSince1970: timeInterval)
        let timeDifference = Date().timeIntervalSince(lastMessageDate)
        
        let duration = Int(timeDifference) / 60
        
        if duration >= 0 && duration < 1 {
            return "Just now"
        } else if duration >= 1 && duration < 60 {
            return "\(duration) mins ago"
        } else if duration >= 60 && duration < 60*24 {
            let hour = duration / 60
            if hour == 1 {
                return "an Hour Ago"
            } else {
                return "Hours Ago"
            }
        } else if duration >= 60*24 && duration < 60*24*30 {
            let days = duration / (60*24)
            if days == 1 {
                return "a Day Ago"
            } else {
                return "Days Ago"
            }
        } else if duration >= 60*24*30 &&  duration < 60*24*365 {
            let months = duration / (60*24*30)
            if months == 1 {
                return "a Month Ago"
            } else {
                return "Months Ago"
            }
        } else {
            let years = duration / (60*24*365)
            if years == 1 {
                return "an Year Ago"
            } else {
                return "Years Ago"
            }
        }
    }
}
