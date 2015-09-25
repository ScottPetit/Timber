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
    public let timestamp: NSDate
    public let file: String
    public let function: String
    public let lineNumber: Int
    
    init(message: String, logLevel: LogLevel, timestamp: NSDate, file: String, function: String, lineNumber: Int) {
        self.message = message
        self.logLevel = logLevel
        self.timestamp = timestamp
        let stringFile = NSString(string: file)
        let lastPathComponent = NSString(string: stringFile.lastPathComponent)
        self.file = lastPathComponent.stringByDeletingPathExtension
        self.function = function
        self.lineNumber = lineNumber
    }
}

public class PersistableLogMessage: NSObject, NSCoding {
    
    var message: String
    var logLevel: LogLevel
    var timestamp: NSDate
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
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(message, forKey: "message")
        aCoder.encodeInteger(logLevel.rawValue, forKey: "logLevel")
        aCoder.encodeObject(timestamp, forKey: "timestamp")
        aCoder.encodeObject(file, forKey: "file")
        aCoder.encodeObject(function, forKey: "function")
        aCoder.encodeInteger(lineNumber, forKey: "lineNumber")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.message = aDecoder.decodeObjectForKey("message") as! String
        let logLevelInt = aDecoder.decodeIntegerForKey("logLevel")
        self.logLevel = LogLevel(rawValue: logLevelInt)!
        self.timestamp = aDecoder.decodeObjectForKey("timestamp") as! NSDate
        self.file = aDecoder.decodeObjectForKey("file") as! String
        self.function = aDecoder.decodeObjectForKey("function") as! String
        self.lineNumber = aDecoder.decodeIntegerForKey("lineNumber")
        super.init()
    }
    
    public func logMessage() -> LogMessage {
        return LogMessage(message: message, logLevel: logLevel, timestamp: timestamp, file: file, function: function, lineNumber: lineNumber)
    }
}