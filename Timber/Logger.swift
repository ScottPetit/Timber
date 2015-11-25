//
//  Logger.swift
//  Timber
//
//  Created by Scott Petit on 9/7/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

public protocol LoggerType {
    var messageFormatter: MessageFormatterType { get }
    func logMessage(message: LogMessage)
}

public enum LogLevel: Int, Comparable {
    case None = 0
    case Error
    case Warn
    case Info
    case Debug
    case Verbose
    
    func toString() -> String {
        switch self {
        case .None:
            return "None"
        case .Error:
            return "ERROR"
        case .Warn:
            return "WARNING"
        case .Info:
            return "INFO"
        case .Debug:
            return "DEBUG"
        case .Verbose:
            return "VERBOSE"
        }
    }
}

public func ==(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func <=(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}

public func >=(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}

public func >(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue > rhs.rawValue
}

public func <(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
