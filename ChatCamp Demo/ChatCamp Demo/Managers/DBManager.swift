//
//  DBManager.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 31/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation
import SQLite3
import ChatCamp

enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

struct Chat {
    let messageId: NSString
    let channelType: NSString
    let channelId: NSString
    let timestamp: Int32
    let data: NSString
}

struct Channel {
    let groupChannel: NSString
}

class SQLiteDatabase {
    
    var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    fileprivate let dbPointer: OpaquePointer?
    
    fileprivate init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
        print("Successfully closed connection to database.")
    }
    
    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer? = nil
        // 1
        if sqlite3_open(path, &db) == SQLITE_OK {
            // 2
            return SQLiteDatabase(dbPointer: db)
        } else {
            // 3
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String.init(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
}

extension SQLiteDatabase {
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer? = nil
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        
        return statement
    }
    
    func createTable(table: SQLTable.Type) throws {
        // 1
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        // 2
        defer {
            sqlite3_finalize(createTableStatement)
        }
        // 3
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
    
    func insertChat(channel: CCPBaseChannel, message: CCPMessage) throws {
        let chat = Chat(
            messageId: message.getId() as NSString,
            channelType: (channel.isGroupChannel() ? "group" : "open") as NSString,
            channelId: channel.getId() as NSString,
            timestamp: Int32(message.getInsertedAt()),
            data: message.serialize() as! NSString)
        let insertSql = "INSERT OR REPLACE INTO Chat (messageId, channelType, channelId, timestamp, data) VALUES (?, ?, ?, ?, ?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        defer {
            sqlite3_finalize(insertStatement)
        }
        
        guard sqlite3_bind_text(insertStatement, 1, chat.messageId.utf8String, -1, nil) == SQLITE_OK  &&
            sqlite3_bind_text(insertStatement, 2, chat.channelType.utf8String, -1, nil) == SQLITE_OK  &&
            sqlite3_bind_text(insertStatement, 3, chat.channelId.utf8String, -1, nil) == SQLITE_OK  &&
            sqlite3_bind_int(insertStatement, 4, chat.timestamp) == SQLITE_OK  &&
            sqlite3_bind_text(insertStatement, 5, chat.data.utf8String, -1, nil) == SQLITE_OK else {
                throw SQLiteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        print("Successfully inserted row.")
    }
    
    func insertGroupChannels(channels: [CCPGroupChannel]) throws {
        let deleteSql = "DELETE FROM Channel"
        let deleteStatement = try prepareStatement(sql: deleteSql)
        guard sqlite3_step(deleteStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        sqlite3_finalize(deleteStatement)

        for channel in channels {
            let channel = Channel(groupChannel: channel.serialize() as! NSString)
            let insertSql = "INSERT OR REPLACE INTO Channel (groupChannel) VALUES (?);"
            let insertStatement = try prepareStatement(sql: insertSql)
            defer {
                sqlite3_finalize(insertStatement)
            }
            
            guard sqlite3_bind_text(insertStatement, 1, channel.groupChannel.utf8String, -1, nil) == SQLITE_OK else {
                throw SQLiteError.Bind(message: errorMessage)
            }
            
            guard sqlite3_step(insertStatement) == SQLITE_DONE else {
                throw SQLiteError.Step(message: errorMessage)
            }
            
            print("Successfully inserted channel in DB.")
        }
    }
    
    func getGroupChannels() -> [CCPGroupChannel]? {
        let querySql = "SELECT * FROM Channel"
        
        guard let queryStatement = try? prepareStatement(sql: querySql) else {
            return nil
        }
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        var groupChannels = [CCPGroupChannel]()
        
        while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            let queryResult = sqlite3_column_text(queryStatement, 0)
            let data = String(cString: queryResult!) as NSString

            let groupChannel = CCPGroupChannel.createfromSerializedData(jsonString: data as String)
            groupChannels.append(groupChannel!)
        }
        
        return groupChannels
    }
    
    func chat(channel: CCPBaseChannel) -> [CCPMessage]? {
        let channelType = (channel.isGroupChannel() ? "group" : "open")
        let channelId = channel.getId()
        let querySql = "SELECT * FROM Chat WHERE channelType = '\(channelType)' AND channelId = '\(channelId)' ORDER BY timestamp DESC LIMIT 30;"
        
        guard let queryStatement = try? prepareStatement(sql: querySql) else {
            return nil
        }
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        //            guard sqlite3_bind_text(queryStatement, 1, channelId, -1, nil) == SQLITE_OK  else {
        //                return nil
        //            }
        
        var m = [CCPMessage]()
        
        
        while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            //                let queryResultCol0 = sqlite3_column_text(queryStatement, 0)
            //                let messageId = String(cString: queryResultCol0!) as NSString
            //
            //                let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
            //                let channelType = String(cString: queryResultCol1!) as NSString
            //
            //                let queryResultCol2 = sqlite3_column_text(queryStatement, 2)
            //                let channelId = String(cString: queryResultCol2!) as NSString
            //
            //                let timestamp = sqlite3_column_int(queryStatement, 3)
            
            let queryResultCol4 = sqlite3_column_text(queryStatement, 4)
            let data = String(cString: queryResultCol4!) as NSString
            print("HERE::: \(data)")
            
            let cm = CCPMessage.createfromSerializedData(jsonString: data as String)
            m.append(cm!)
            
        }
        
        return m
        
    }
}

protocol SQLTable {
    static var createStatement: String { get }
}

extension Chat: SQLTable {
    static var createStatement: String {
        return """
        CREATE TABLE IF NOT EXISTS Chat(
        messageId TEXT PRIMARY KEY NOT NULL,
        channelType TEXT NOT NULL,
        channelId TEXT NOT NULL,
        timestamp INT NOT NULL,
        data TEXT NOT NULL
        ); CREATE IF NOT EXISTS INDEX messageId_1 Chat(messageId);
        CREATE IF NOT EXISTS INDEX channelType_2 Chat(channelType);
        CREATE IF NOT EXISTS INDEX channelId_3 Chat(channelId);
        CREATE IF NOT EXISTS INDEX timestamp_4 Chat(timestamp);
        """
    }
}

extension Channel: SQLTable {
    static var createStatement: String {
        return """
        CREATE TABLE IF NOT EXISTS Channel(
        groupChannel TEXT NOT NULL
        );
        """
    }
}
