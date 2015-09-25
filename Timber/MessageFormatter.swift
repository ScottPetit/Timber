//
//  MessageFormatter.swift
//  Timber
//
//  Created by Scott Petit on 9/8/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

public protocol MessageFormatterType {
    func formatLogMessage(logMessage: LogMessage) -> String
}

public struct MessageFormatter: MessageFormatterType {
    
    private let calendarUnitFlags: NSCalendarUnit = [.Year, .Month, .Day, .Hour, .Minute, .Second, .Nanosecond]
    private let appName = FileManager.applicationName()
    
    public init() {
    }
    
    public func formatLogMessage(logMessage: LogMessage) -> String {
        let components = NSCalendar.autoupdatingCurrentCalendar().components(calendarUnitFlags, fromDate: logMessage.timestamp)
        
        let nanosecondString = "\(components.nanosecond)"
        let timestampString = NSString(format: "%04ld-%02ld-%02ld %02ld:%02ld:%02ld.%@", components.year,
            components.month,
            components.day,
            components.hour,
            components.minute,
            components.second,
            nanosecondString.substringToIndex(nanosecondString.startIndex.advancedBy(3)))
        let messageToLog = "\(logMessage.logLevel.toString()) \(timestampString) \(appName) [\(logMessage.file) '\(logMessage.function)'] \(logMessage.message)"
        
        return messageToLog
    }
    
}