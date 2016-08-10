//
//  MessageFormatter.swift
//  Timber
//
//  Created by Scott Petit on 9/8/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

public protocol MessageFormatterType {
    func formatLogMessage(_ logMessage: LogMessage) -> String
}

public struct MessageFormatter: MessageFormatterType {
    
    private let calendarComponents: Set<Calendar.Component> = [.year, .month, .weekday, .hour, .minute, .second, .nanosecond]
    private let appName = FileManager.applicationName()
    
    public init() {
    }
    
    public func formatLogMessage(_ logMessage: LogMessage) -> String {
        let components = Calendar.autoupdatingCurrent.dateComponents(calendarComponents, from: logMessage.timestamp)
        
        let nanosecondString = "\(components.nanosecond)"
        let timestampString = NSString(format: "%04ld-%02ld-%02ld %02ld:%02ld:%02ld.%@", components.year!,
            components.month!,
            components.day!,
            components.hour!,
            components.minute!,
            components.second!,
            nanosecondString.substring(to: nanosecondString.characters.index(nanosecondString.startIndex, offsetBy: 3)))
        let messageToLog = "\(logMessage.logLevel.toString()) \(timestampString) \(appName) [\(logMessage.file) '\(logMessage.function)'] \(logMessage.message)"
        
        return messageToLog
    }
    
}
