//
//  Timber.swift
//  Timber
//
//  Created by Scott Petit on 9/7/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

//MARK: Global

public func LogError(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .Error, timestamp: NSDate(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogError(error: NSError?, file: String = #file, function: String = #function, line: Int = #line) {
    if let error = error {
        let logMessage = LogMessage(message: error.description, logLevel: .Error, timestamp: NSDate(), file: file, function: function, lineNumber: line)
        Timber.sharedTimber.log(logMessage)
    }
}

public func LogWarn(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .Warn, timestamp: NSDate(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogInfo(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .Info, timestamp: NSDate(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogDebug(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .Debug, timestamp: NSDate(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func LogVerbose(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let logMessage = LogMessage(message: message, logLevel: .Verbose, timestamp: NSDate(), file: file, function: function, lineNumber: line)
    Timber.sharedTimber.log(logMessage)
}

public func Log(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogInfo(message, file: file, function: function, line: line)
}

public func Trace(file: String = #file, function: String = #function, line: Int = #line) {
    LogInfo("", file: file, function: function, line: line)
}

public func LogBasic(message: String) {
    
}

public class Timber {

    static let sharedTimber = Timber()
    private var loggers = [LoggerType]()
    private var logLevel = LogLevel.Verbose
    
    private init() {
        
    }
    
    //MARK: Public
    
    public class func setLogLevel(level: LogLevel) {
        Timber.sharedTimber.logLevel = level
    }
    
    public class func addLogger(logger: LoggerType) {
        Timber.sharedTimber.addLogger(logger)
    }
    
    //MARK: Private
    
    private func addLogger(logger: LoggerType) {
        loggers.append(logger)
    }
    
    private func log(logMessage: LogMessage) {
        if logMessage.logLevel > Timber.sharedTimber.logLevel {
            return
        }
        
        for logger in self.loggers {
            logger.logMessage(logMessage)
        }
    }
}
