//
//  ConsoleLogger.swift
//  Timber
//
//  Created by Scott Petit on 9/7/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

public struct ConsoleLogger: LoggerType {
    
    let logLevel: LogLevel
    
    public init(logLevel: LogLevel = .verbose) {
        self.logLevel = logLevel
    }
    
    //MARK: LoggerType
    
    public var messageFormatter: MessageFormatterType = MessageFormatter()
    
    public func logMessage(_ message: LogMessage) {
        guard message.logLevel <= logLevel else { return }
        
        let messageToLog = messageFormatter.formatLogMessage(message)
        
        print(messageToLog)
    }
    
}
