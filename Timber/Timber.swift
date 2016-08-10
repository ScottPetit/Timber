//
//  Timber.swift
//  Timber
//
//  Created by Scott Petit on 9/7/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

//MARK: Global

public func LogError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .error, timestamp: Date(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogError(_ error: NSError?, file: String = #file, function: String = #function, line: Int = #line) {
    if let error = error {
        let logMessage = LogMessage(message: error.description, logLevel: .error, timestamp: Date(), file: file, function: function, lineNumber: line)
        Timber.sharedTimber.log(logMessage)
    }
}

public func LogWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .warn, timestamp: Date(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .info, timestamp: Date(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .debug, timestamp: Date(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogVerbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .verbose, timestamp: Date(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func Log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogInfo(message, file: file, function: function, line: line)
}

public func Trace(_ file: String = #file, function: String = #function, line: Int = #line) {
    LogInfo("", file: file, function: function, line: line)
}

public func LogBasic(_ message: String) {
    
}

public class Timber {

    static let sharedTimber = Timber()
    private var loggers = [LoggerType]()
    private var logLevel = LogLevel.verbose
    
    private init() {
        
    }
    
    //MARK: Public
    
    public class func setLogLevel(_ level: LogLevel) {
        Timber.sharedTimber.logLevel = level
    }
    
    public class func addLogger(_ logger: LoggerType) {
        Timber.sharedTimber.addLogger(logger)
    }
    
    //MARK: Private
    
    private func addLogger(_ logger: LoggerType) {
        loggers.append(logger)
    }
    
    private func log(_ logMessage: LogMessage) {
        if logMessage.logLevel > Timber.sharedTimber.logLevel {
            return
        }
        
        for logger in self.loggers {
            logger.logMessage(logMessage)
        }
    }
}
