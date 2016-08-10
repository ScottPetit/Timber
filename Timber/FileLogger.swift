//
//  FileLogger.swift
//  Timber
//
//  Created by Scott Petit on 9/7/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

import Foundation

public struct FileLogger: LoggerType {
    
    public init() {
        FileManager.purgeOldFiles()
        FileManager.purgeOldestFilesGreaterThanCount(5)
    }
    
    //MARK: Logger
    
    public var messageFormatter: MessageFormatterType = MessageFormatter()
    
    public func logMessage(_ message: LogMessage) {
        let currentData = FileManager.currentLogFileData()
        var mutableData = Data(currentData)
        
        var messageToLog = messageFormatter.formatLogMessage(message)
        messageToLog += "\n"
        
        if let dataToAppend = messageToLog.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            mutableData.append(dataToAppend)
        }
        
        if let filePath = FileManager.currentLogFilePath() {
            let fileUrl = URL(fileURLWithPath: filePath)
            try? mutableData.write(to: fileUrl, options: Data.WritingOptions())
        }
    }
    
}

struct FileManager {
    
    static let userDefaultsKey = "com.Timber.currentLogFile"
    static let maximumLogFileSize = 1024 * 1024 // 1 mb
    static let maximumFileExsitenceInterval: TimeInterval = 60 * 60 * 24 * 180 // 180 days
    
    static func currentLogFilePath() -> String? {
        if let path: AnyObject = UserDefaults.standard.object(forKey: userDefaultsKey) {
            return path as? String
        } else {
            return createNewLogFilePath()
        }
    }
    
    static func shouldCreateNewLogFileForData(_ data: Data) -> Bool {
        return data.count > maximumLogFileSize
    }
    
    @discardableResult static func createNewLogFilePath() -> String? {
        if let logsDirectory = defaultLogsDirectory() {
            let newLogFilePath = logsDirectory.appendingPathComponent(newLogFileName())
            UserDefaults.standard.set(newLogFilePath, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize()
            
            return newLogFilePath
        }
        
        return nil
    }
    
    static func newLogFileName() -> String {
        let appName = applicationName()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'_'HH'-'mm'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let formattedDate = dateFormatter.string(from: Date())
        
        let newLogFileName = "\(appName)_\(formattedDate).log"
        
        return newLogFileName
    }
    
    static func applicationName() -> String {
        let processName = ProcessInfo.processInfo.processName
        if processName.characters.count > 0 {
            return processName
        } else {
            return "<UnnamedApp>"
        }
    }
    
    static func defaultLogsDirectory() -> NSString? {
        // Update how we get file URLs per Apple Technical Note https://developer.apple.com/library/ios/technotes/tn2406/_index.html
        let cachesDirectoryPathURL = Foundation.FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last as URL!
        
        if (cachesDirectoryPathURL?.isFileURL)! {
            if let cachesDirectoryPath = cachesDirectoryPathURL?.path as NSString? {
                let logsDirectory = cachesDirectoryPath.appendingPathComponent("Timber")
                
                if !Foundation.FileManager.default.fileExists(atPath: logsDirectory) {
                    do {
                        try Foundation.FileManager.default.createDirectory(atPath: logsDirectory, withIntermediateDirectories: true, attributes: nil)
                    } catch _ {
                    }
                }
                
                return NSString(string: logsDirectory)
            }
        }
        
        return nil
    }
    
    static func currentLogFileData() -> Data {
        if let filePath = currentLogFilePath() {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                if shouldCreateNewLogFileForData(data) {
                    createNewLogFilePath()
                }
                
                return data
            }
        }
        
        return Data()
    }
    
    static func purgeOldFiles() {
        if let logsDirectory = defaultLogsDirectory() {
            TrashMan.takeOutFilesInDirectory(logsDirectory, withExtension: "log", notModifiedSince: Date(timeIntervalSinceNow: -maximumFileExsitenceInterval))
        }
    }
    
    static func purgeOldestFilesGreaterThanCount(_ count: Int) {
        if let logsDirectory = defaultLogsDirectory() {
            TrashMan.takeOutOldestFilesInDirectory(logsDirectory, greaterThanCount: count)
        }
    }
}

struct TrashMan {
    
    static func takeOutFilesInDirectory(_ directoryPath: NSString, notModifiedSince minimumModifiedDate: Date) {
        takeOutFilesInDirectory(directoryPath, withExtension: nil, notModifiedSince: minimumModifiedDate)
    }
    
    static func takeOutFilesInDirectory(_ directoryPath: NSString, withExtension fileExtension: String?, notModifiedSince minimumModifiedDate: Date) {
        let fileURL = URL(fileURLWithPath: directoryPath as String, isDirectory: true)
        let fileManager = Foundation.FileManager.default
        let contents: [AnyObject]?
        do {
            contents = try fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: [URLResourceKey.attributeModificationDateKey], options: .skipsHiddenFiles)
        } catch _ {
            contents = nil
        }
        
        if let files = contents as? [URL] {
            for file in files {
                var fileDate: AnyObject?
                
                let haveDate: Bool
                do {
                    try (file as NSURL).getResourceValue(&fileDate, forKey: URLResourceKey.attributeModificationDateKey)
                    haveDate = true
                } catch _ {
                    haveDate = false
                }
                if !haveDate {
                    continue
                }
                
                if fileDate?.timeIntervalSince1970 >= minimumModifiedDate.timeIntervalSince1970 {
                    continue
                }
                
                if fileExtension != nil {
                    if file.pathExtension != fileExtension! {
                        continue
                    }
                }
                
                do {
                    try fileManager.removeItem(at: file)
                } catch _ {
                }
            }
        }
    }
    
    static func takeOutOldestFilesInDirectory(_ directoryPath: NSString, greaterThanCount count: Int) {
        let directoryURL = URL(fileURLWithPath: directoryPath as String, isDirectory: true)
        let contents: [AnyObject]?
        do {
            contents = try Foundation.FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [URLResourceKey.creationDateKey], options: .skipsHiddenFiles)
        } catch _ {
            contents = nil
        }
        
        if let files = contents as? [URL] {
            if count >= files.count {
                return
            }
            
            let sortedFiles = files.sorted(by: { (firstFile: URL, secondFile: URL) -> Bool in
                var firstFileObject: AnyObject?
                
                let haveFirstDate: Bool
                do {
                    try (firstFile as NSURL).getResourceValue(&firstFileObject, forKey: URLResourceKey.creationDateKey)
                    haveFirstDate = true
                } catch {
                    haveFirstDate = false
                }
                if !haveFirstDate {
                    return false
                }
                
                var secondFileObject: AnyObject?
                
                let haveSecondDate: Bool
                do {
                    try (secondFile as NSURL).getResourceValue(&secondFileObject, forKey: URLResourceKey.creationDateKey)
                    haveSecondDate = true
                } catch {
                    haveSecondDate = false
                }
                if !haveSecondDate {
                    return true
                }
                
                let firstFileDate = firstFileObject as! Date
                let secondFileDate = secondFileObject as! Date
                
                let comparisonResult = firstFileDate.compare(secondFileDate)
                return comparisonResult == ComparisonResult.orderedDescending
            })
            
            for (index, fileURL) in sortedFiles.enumerated() {
                if index >= count {
                    do {
                        try Foundation.FileManager.default.removeItem(at: fileURL)
                    } catch {
                    }
                }
            }
        }
    }
    
}
