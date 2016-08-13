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
    func logMessage(_ message: LogMessage)
}

public enum LogLevel: Int, Comparable {
    case none = 0
    case error
    case warn
    case info
    case debug
    case verbose
    
    public func toString() -> String {
        switch self {
        case .none:
            return "None"
        case .error:
            return "ERROR"
        case .warn:
            return "WARNING"
        case .info:
            return "INFO"
        case .debug:
            return "DEBUG"
        case .verbose:
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
