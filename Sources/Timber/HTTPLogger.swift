//
//  HTTPLogger.swift
//  Timber
//
//  Created by Scott Petit on 10/22/15.
//  Copyright © 2015 Scott Petit. All rights reserved.
//

import Foundation

public class HTTPLogger: LoggerType {

    let URL: Foundation.URL
    let method: String
    
    init(URL: Foundation.URL, method: String) {
        self.URL = URL
        self.method = method
    }
    
    //MARK: Logger
    
    public var messageFormatter: MessageFormatterType = MessageFormatter()
    
    public func logMessage(_ message: LogMessage) {
        let parameters = ["message" : message.message]

        var request = URLRequest(url: URL)
        request.httpMethod = method
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions())
            request.httpBody = data
        } catch {

        }
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let dataTask = session.dataTask(with: request)
        
        dataTask.resume()
    }
    
}
