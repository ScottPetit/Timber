//
//  HTTPLogger.swift
//  Timber
//
//  Created by Scott Petit on 10/22/15.
//  Copyright © 2015 Scott Petit. All rights reserved.
//

public class HTTPLogger: LoggerType {

    let URL: NSURL
    let method: String
    
    init(URL: NSURL, method: String) {
        self.URL = URL
        self.method = method
    }
    
    //MARK: Logger
    
    public var messageFormatter: MessageFormatterType = MessageFormatter()
    
    public func logMessage(message: LogMessage) {
        let parameters = ["message" : message.message]
        
        let URLRequest = NSMutableURLRequest(URL: URL)
        URLRequest.HTTPMethod = method
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions())
            URLRequest.HTTPBody = data
        } catch {
            
        }
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let dataTask = session.dataTaskWithRequest(URLRequest)
        
        dataTask.resume()
    }
    
}
