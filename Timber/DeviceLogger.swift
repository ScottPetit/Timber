//
//  DeviceLogger.swift
//  Timber
//
//  Created by Scott Petit on 8/5/15.
//  Copyright © 2015 Scott Petit. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

private let DeviceLoggerUserDefaultsKey = "io.timber.device-logger.user-defaults-key"

public class DeviceLogger: NSObject, LoggerType {

    public static let sharedLogger = DeviceLogger()
    var messages = [LogMessage]()
    var toRecipients = [String]()
    private var window: UIWindow?
    
    override init() {
        super.init()
        addObservers()
        restorePersistedLogs()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func viewController() -> UIViewController {
        let deviceLogger = DeviceLoggerViewController(messages: messages.reverse(), toRecipients: toRecipients)
        deviceLogger.title = "TIMBER"
        let navigationController = UINavigationController(rootViewController: deviceLogger)

        return navigationController
    }
    
    /**
    Installs a 3 tap, 4 finger gesture recognizer in the given window.
    
    :param: window An optional window, most likely, UIApplication.sharedApplication().window to add the launch gesture for the device logger.
    */
    public func installGestureInWindow(window: UIWindow?) {
        guard let window = window else {
            return
        }
        
        self.window = window
        
        let gesture = UITapGestureRecognizer(target: self, action: Selector("handleGesture:"))
        gesture.numberOfTapsRequired = 3
        gesture.numberOfTouchesRequired = 4
        
        window.addGestureRecognizer(gesture)
    }
    
    func handleGesture(gesture: UIGestureRecognizer) {
        if let window = window {
            let rootViewController = window.rootViewController
            rootViewController?.presentViewController(viewController(), animated: true, completion: nil)
        }
    }
    
    func restorePersistedLogs() {
        if let persistedLogData = NSUserDefaults.standardUserDefaults().objectForKey(DeviceLoggerUserDefaultsKey) as? NSData {
            if let persistedLogs = NSKeyedUnarchiver.unarchiveObjectWithData(persistedLogData) as? [PersistableLogMessage] {
                self.messages = persistedLogs.map { $0.logMessage() }
            }
        }
    }
    
    func persistLogs() {
        let persistingMessages = self.messages.map { PersistableLogMessage(logMessage: $0) }
        let persistingMessagesData = NSKeyedArchiver.archivedDataWithRootObject(persistingMessages)
        NSUserDefaults.standardUserDefaults().setObject(persistingMessagesData, forKey: DeviceLoggerUserDefaultsKey)
    }
    
    //MARK: LoggerType
    
    public var messageFormatter: MessageFormatterType = MessageFormatter()
    
    public func logMessage(message: LogMessage) {
        if messages.count == 200 {
            messages.removeAtIndex(0)
        }
        
        messages.append(message)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.persistLogs()
        }
    }
    
    //MARK: Notifications
    
    private func addObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveMemoryWarningNotification:", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    func didReceiveMemoryWarningNotification(note: NSNotification) {
        messages.removeAll()
    }
}

class DeviceLoggerViewController: UIViewController {
    
    let tableView = UITableView()
    var toRecipients = [String]()
    var messages: [LogMessage]
    let messageFormatter = MessageFormatter()
    
    convenience init(messages: [LogMessage], toRecipients: [String]) {
        self.init(nibName: nil, bundle: nil)
        self.messages = messages
        self.toRecipients = toRecipients
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.messages = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.messages = []
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonPressed"), animated: true)
        
        if MFMailComposeViewController.canSendMail() {
            self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "shareButtonPressed"), animated: true)
        }
        
        setUpTableView()
    }
    
    func doneButtonPressed() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func shareButtonPressed() {
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        
        var log = ""
        for message in messages {
            log += messageFormatter.formatLogMessage(message)
            log += "<br>\n"
        }
        let data = log.dataUsingEncoding(NSUTF8StringEncoding)
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.setSubject("Logs")
        mailComposeViewController.setToRecipients(toRecipients)
        mailComposeViewController.mailComposeDelegate = self
        if let data = data {
            mailComposeViewController.addAttachmentData(data, mimeType: "text/plain", fileName: "Timber.log")
        }
        navigationController?.presentViewController(mailComposeViewController, animated: true, completion: nil)
    }
    
    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        let leadingConstraint = NSLayoutConstraint(item: tableView, attribute: .Leading, relatedBy: .Equal, toItem: tableView.superview, attribute: .Leading, multiplier: 1.0, constant: 0)
        let topConstraint = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: tableView.superview, attribute: .Top, multiplier: 1.0, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: tableView, attribute: .Trailing, relatedBy: .Equal, toItem: tableView.superview, attribute: .Trailing, multiplier: 1.0, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: tableView.superview, attribute: .Bottom, multiplier: 1.0, constant: 0)
        
        NSLayoutConstraint.activateConstraints([leadingConstraint, topConstraint, trailingConstraint, bottomConstraint])
        
        tableView.rowHeight = 100
        
        tableView.registerClass(DeviceLoggerTableViewCell.classForCoder(), forCellReuseIdentifier: DeviceLoggerTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
}

extension DeviceLoggerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(DeviceLoggerTableViewCell.reuseIdentifier, forIndexPath: indexPath) as? DeviceLoggerTableViewCell
        let logMessage = messages[indexPath.row]
        cell?.configureWithLogMessage(logMessage)
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let logMessage = messages[indexPath.row]
        let viewController = DeviceLoggerDetailViewController(message: logMessage)
        navigationController?.pushViewController(viewController, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

extension DeviceLoggerViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}

class DeviceLoggerTableViewCell: UITableViewCell {
    
    static var reuseIdentifier = "DeviceLoggerTableViewCell"
    var messageFormatter: MessageFormatterType = MessageFormatter()
    
    var logLevelContainerView: UIView?
    var logLevelLabel: UILabel?
    var messageLabel: UILabel?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setUpLogLevel()
        setUpMessageLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configureWithLogMessage(message: LogMessage) {
        logLevelLabel?.text = message.logLevel.toString()
        logLevelContainerView?.backgroundColor = colorForLogMessage(message)
        messageLabel?.text = messageFormatter.formatLogMessage(message)
    }
    
    func setUpLogLevel() {
        logLevelContainerView = UIView(frame: CGRectZero)
        logLevelContainerView?.translatesAutoresizingMaskIntoConstraints = false
        logLevelContainerView?.layer.cornerRadius = 4
        
        if let logLevelContainerView = logLevelContainerView {
            self.addSubview(logLevelContainerView)
            
            let centerYConstraint = NSLayoutConstraint(item: logLevelContainerView, attribute: .CenterY, relatedBy: .Equal, toItem: logLevelContainerView.superview, attribute: .CenterY, multiplier: 1.0, constant: 0)
            let leftConstraint = NSLayoutConstraint(item: logLevelContainerView, attribute: .Left, relatedBy: .Equal, toItem: logLevelContainerView.superview, attribute: .Left, multiplier: 1.0, constant: 8)
            let widthConstraint = NSLayoutConstraint(item: logLevelContainerView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 71)
            NSLayoutConstraint.activateConstraints([centerYConstraint, leftConstraint, widthConstraint])
        }
        
        logLevelLabel = UILabel(frame: CGRectZero)
        logLevelLabel?.translatesAutoresizingMaskIntoConstraints = false
        logLevelLabel?.font = UIFont(name: "AvenirNextCondensed-Bold", size: 14)
        logLevelLabel?.textColor = UIColor.whiteColor()
        logLevelLabel?.textAlignment = .Center
        
        if let logLevelLabel = logLevelLabel {
            logLevelContainerView?.addSubview(logLevelLabel)
            
            let topConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .Top, relatedBy: .Equal, toItem: logLevelLabel.superview, attribute: .Top, multiplier: 1.0, constant: 8)
            let leftConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .Left, relatedBy: .Equal, toItem: logLevelLabel.superview, attribute: .Left, multiplier: 1.0, constant: 8)
            let bottomConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .Bottom, relatedBy: .Equal, toItem: logLevelLabel.superview, attribute: .Bottom, multiplier: 1.0, constant: -8)
            let rightConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .Right, relatedBy: .Equal, toItem: logLevelLabel.superview, attribute: .Right, multiplier: 1.0, constant: -8)
            
            NSLayoutConstraint.activateConstraints([topConstraint, leftConstraint, bottomConstraint, rightConstraint])
        }
    }
    
    func setUpMessageLabel() {
        messageLabel = UILabel(frame: CGRectZero)
        messageLabel?.translatesAutoresizingMaskIntoConstraints = false
        messageLabel?.font = UIFont(name: "CourierNewPSMT", size: 18)
        messageLabel?.numberOfLines = 4
        messageLabel?.textColor = UIColor.darkGrayColor()
        
        if let messageLabel = messageLabel {
            self.addSubview(messageLabel)
            
            let topConstraint = NSLayoutConstraint(item: messageLabel, attribute: .Top, relatedBy: .Equal, toItem: messageLabel.superview, attribute: .Top, multiplier: 1.0, constant: 8)
            let leftConstraint = NSLayoutConstraint(item: messageLabel, attribute: .Left, relatedBy: .Equal, toItem: logLevelContainerView, attribute: .Right, multiplier: 1.0, constant: 8)
            let rightConstraint = NSLayoutConstraint(item: messageLabel, attribute: .Right, relatedBy: .Equal, toItem: messageLabel.superview, attribute: .Right, multiplier: 1.0, constant: -8)
            NSLayoutConstraint.activateConstraints([topConstraint, leftConstraint, rightConstraint])
        }
    }
    
    func colorForLogMessage(message: LogMessage) -> UIColor {
        let color: UIColor
        switch message.logLevel {
        case .None:
            color = UIColor(red: 152/255, green: 160/255, blue: 152/255, alpha: 1.0)
        case .Error:
            color = UIColor(red: 255/255, green: 91/255, blue: 97/255, alpha: 1.0)
        case .Warn:
            color = UIColor(red: 255/255, green: 179/255, blue: 1/255, alpha: 1.0)
        case .Info:
            color = UIColor(red: 152/255, green: 160/255, blue: 152/255, alpha: 1.0)
        case .Debug:
            color = UIColor(red: 1/255, green: 210/255, blue: 196/255, alpha: 1.0)
        case .Verbose:
            color = UIColor(red: 76/255, green: 224/255, blue: 104/255, alpha: 1.0)
        }
        return color
    }
}

class DeviceLoggerDetailViewController: UIViewController {
    
    var logMessage: LogMessage?
    var textView: UITextView?
    let messageFormatter: MessageFormatterType = MessageFormatter()
    
    convenience init(message: LogMessage) {
        self.init(nibName: nil, bundle: nil)
        self.logMessage = message
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        setUpTextView()
        
        if let message = logMessage {
            textView?.text = messageFormatter.formatLogMessage(message)
        }
    }
    
    private func setUpTextView() {
        textView = UITextView(frame: CGRectZero)
        textView?.backgroundColor = UIColor.whiteColor()
        textView?.translatesAutoresizingMaskIntoConstraints = false
        textView?.font = UIFont(name: "CourierNewPSMT", size: 18)
        textView?.textColor = UIColor.darkGrayColor()
        textView?.editable = false
        
        if let textView = textView {
            view.addSubview(textView)
            
            let topConstraint = NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .Equal, toItem: textView.superview, attribute: .Top, multiplier: 1.0, constant: 8)
            let leftConstraint = NSLayoutConstraint(item: textView, attribute: .Left, relatedBy: .Equal, toItem: textView.superview, attribute: .Left, multiplier: 1.0, constant: 8)
            let rightConstraint = NSLayoutConstraint(item: textView, attribute: .Right, relatedBy: .Equal, toItem: textView.superview, attribute: .Right, multiplier: 1.0, constant: -8)
            let bottomConstraint = NSLayoutConstraint(item: textView, attribute: .Bottom, relatedBy: .Equal, toItem: textView.superview, attribute: .Bottom, multiplier: 1.0, constant: -8)
            NSLayoutConstraint.activateConstraints([topConstraint, leftConstraint, rightConstraint, bottomConstraint])
        }
    }
    
}

