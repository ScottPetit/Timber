//
//  LogMessage.swift
//  Timber
//
//  Created by Scott Petit on 9/7/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

public struct LogMessage {
    
    public let message: String
    public let logLevel: LogLevel
    public let timestamp: Date
    public let file: String
    public let function: String
    public let lineNumber: Int
    
    public init(message: String, logLevel: LogLevel, timestamp: Date, file: String, function: String, lineNumber: Int) {
        self.message = message
        self.logLevel = logLevel
        self.timestamp = timestamp
        let stringFile = NSString(string: file)
        let lastPathComponent = NSString(string: stringFile.lastPathComponent)
        self.file = lastPathComponent.deletingPathExtension
        self.function = function
        self.lineNumber = lineNumber
    }
}

public class PersistableLogMessage: NSObject, NSCoding {
    
    var message: String
    var logLevel: LogLevel
    var timestamp: Date
    var file: String
    var function: String
    var lineNumber: Int
    
    init(logMessage: LogMessage) {
        self.message = logMessage.message
        self.logLevel = logMessage.logLevel
        self.timestamp = logMessage.timestamp
        self.file = logMessage.file
        self.function = logMessage.function
        self.lineNumber = logMessage.lineNumber
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(message, forKey: "message")
        aCoder.encode(logLevel.rawValue, forKey: "logLevel")
        aCoder.encode(timestamp, forKey: "timestamp")
        aCoder.encode(file, forKey: "file")
        aCoder.encode(function, forKey: "function")
        aCoder.encode(lineNumber, forKey: "lineNumber")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.message = aDecoder.decodeObject(forKey: "message") as! String
        let logLevelInt = aDecoder.decodeInteger(forKey: "logLevel")
        self.logLevel = LogLevel(rawValue: logLevelInt)!
        self.timestamp = aDecoder.decodeObject(forKey: "timestamp") as! Date
        self.file = aDecoder.decodeObject(forKey: "file") as! String
        self.function = aDecoder.decodeObject(forKey: "function") as! String
        self.lineNumber = aDecoder.decodeInteger(forKey: "lineNumber")
        super.init()
    }
    
    public func logMessage() -> LogMessage {
        return LogMessage(message: message, logLevel: logLevel, timestamp: timestamp, file: file, function: function, lineNumber: lineNumber)
    }
}
