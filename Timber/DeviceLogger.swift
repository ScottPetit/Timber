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

    public static let shared = DeviceLogger()
    public var toRecipients = [String]()
    var messages = [LogMessage]()
    private var window: UIWindow?
    
    override init() {
        super.init()
        addObservers()
        restorePersistedLogs()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func loggerViewController() -> UIViewController {
        let deviceLogger = DeviceLoggerViewController(messages: messages.reversed(), toRecipients: toRecipients)
        deviceLogger.title = "TIMBER"
        let navigationController = UINavigationController(rootViewController: deviceLogger)
        return navigationController
    }
    
    public func messageViewController() -> UIViewController {
        var log = ""
        for message in messages.reversed() {
            log += messageFormatter.formatLogMessage(message)
            log += "<br>\n"
        }
        let data = log.data(using: String.Encoding.utf8)
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.setSubject("Logs")
        mailComposeViewController.setToRecipients(toRecipients)
        mailComposeViewController.mailComposeDelegate = self
        if let data = data {
            mailComposeViewController.addAttachmentData(data, mimeType: "text/plain", fileName: "Timber.log")
        }
        return mailComposeViewController
    }
    
    /**
    Installs a 3 tap, 4 finger gesture recognizer in the given window.
    
    :param: window An optional window, most likely, UIApplication.sharedApplication().window to add the launch gesture for the device logger.
    */
    public func installGestureInWindow(_ window: UIWindow?) {
        guard let window = window else {
            return
        }
        
        self.window = window
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(DeviceLogger.handleGesture(_:)))
        gesture.numberOfTapsRequired = 3
        gesture.numberOfTouchesRequired = 4
        
        window.addGestureRecognizer(gesture)
    }
    
    @objc func handleGesture(_ gesture: UIGestureRecognizer) {
        if let window = window {
            let rootViewController = window.rootViewController
            rootViewController?.present(loggerViewController(), animated: true, completion: nil)
        }
    }
    
    func restorePersistedLogs() {
        if let persistedLogData = UserDefaults.standard.object(forKey: DeviceLoggerUserDefaultsKey) as? Data {
            if let persistedLogs = NSKeyedUnarchiver.unarchiveObject(with: persistedLogData) as? [PersistableLogMessage] {
                self.messages = persistedLogs.map { $0.logMessage() }
            }
        }
    }
    
    func persistLogs() {
        let persistingMessages = self.messages.map { PersistableLogMessage(logMessage: $0) }
        let persistingMessagesData = NSKeyedArchiver.archivedData(withRootObject: persistingMessages)
        UserDefaults.standard.set(persistingMessagesData, forKey: DeviceLoggerUserDefaultsKey)
    }
    
    //MARK: LoggerType
    
    public var messageFormatter: MessageFormatterType = MessageFormatter()
    
    public func logMessage(_ message: LogMessage) {
        if messages.count == 200 {
            messages.remove(at: 0)
        }
        
        messages.append(message)
    }
    
    //MARK: Notifications
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(DeviceLogger.didReceiveMemoryWarningNotification(_:)), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(DeviceLogger.applicationDidEnterBackgroundNotification(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc func didReceiveMemoryWarningNotification(_ note: Notification) {
        messages.removeAll()
    }
    
    @objc func applicationDidEnterBackgroundNotification(_ note: Notification) {
        persistLogs()
    }
}

extension DeviceLogger: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.messages = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.messages = []
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(DeviceLoggerViewController.doneButtonPressed)), animated: true)
        
        if MFMailComposeViewController.canSendMail() {
            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(DeviceLoggerViewController.shareButtonPressed)), animated: true)
        }
    }
    
    @objc func doneButtonPressed() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func shareButtonPressed() {
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        
        var log = ""
        for message in messages {
            log += messageFormatter.formatLogMessage(message)
            log += "<br>\n"
        }
        let data = log.data(using: String.Encoding.utf8)
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.setSubject("Logs")
        mailComposeViewController.setToRecipients(toRecipients)
        mailComposeViewController.mailComposeDelegate = self
        if let data = data {
            mailComposeViewController.addAttachmentData(data, mimeType: "text/plain", fileName: "Timber.log")
        }
        navigationController?.present(mailComposeViewController, animated: true, completion: nil)
    }
    
    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        let leadingConstraint = NSLayoutConstraint(item: tableView, attribute: .leading, relatedBy: .equal, toItem: tableView.superview, attribute: .leading, multiplier: 1.0, constant: 0)
        let topConstraint = NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: tableView.superview, attribute: .top, multiplier: 1.0, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: tableView, attribute: .trailing, relatedBy: .equal, toItem: tableView.superview, attribute: .trailing, multiplier: 1.0, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: tableView.superview, attribute: .bottom, multiplier: 1.0, constant: 0)
        
        NSLayoutConstraint.activate([leadingConstraint, topConstraint, trailingConstraint, bottomConstraint])
        
        tableView.rowHeight = 100
        
        tableView.register(DeviceLoggerTableViewCell.classForCoder(), forCellReuseIdentifier: DeviceLoggerTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
}

extension DeviceLoggerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceLoggerTableViewCell.reuseIdentifier, for: indexPath) as? DeviceLoggerTableViewCell
        let logMessage = messages[(indexPath as NSIndexPath).row]
        cell?.configureWithLogMessage(logMessage)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let logMessage = messages[(indexPath as NSIndexPath).row]
        let viewController = DeviceLoggerDetailViewController(message: logMessage)
        navigationController?.pushViewController(viewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DeviceLoggerViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
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
    
    func configureWithLogMessage(_ message: LogMessage) {
        logLevelLabel?.text = message.logLevel.toString()
        logLevelContainerView?.backgroundColor = colorForLogMessage(message)
        messageLabel?.text = messageFormatter.formatLogMessage(message)
    }
    
    func setUpLogLevel() {
        logLevelContainerView = UIView(frame: CGRect.zero)
        logLevelContainerView?.translatesAutoresizingMaskIntoConstraints = false
        logLevelContainerView?.layer.cornerRadius = 4
        
        if let logLevelContainerView = logLevelContainerView {
            self.addSubview(logLevelContainerView)
            
            let centerYConstraint = NSLayoutConstraint(item: logLevelContainerView, attribute: .centerY, relatedBy: .equal, toItem: logLevelContainerView.superview, attribute: .centerY, multiplier: 1.0, constant: 0)
            let leftConstraint = NSLayoutConstraint(item: logLevelContainerView, attribute: .left, relatedBy: .equal, toItem: logLevelContainerView.superview, attribute: .left, multiplier: 1.0, constant: 8)
            let widthConstraint = NSLayoutConstraint(item: logLevelContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 71)
            NSLayoutConstraint.activate([centerYConstraint, leftConstraint, widthConstraint])
        }
        
        logLevelLabel = UILabel(frame: CGRect.zero)
        logLevelLabel?.translatesAutoresizingMaskIntoConstraints = false
        logLevelLabel?.font = UIFont(name: "AvenirNextCondensed-Bold", size: 14)
        logLevelLabel?.textColor = UIColor.white
        logLevelLabel?.textAlignment = .center
        
        if let logLevelLabel = logLevelLabel {
            logLevelContainerView?.addSubview(logLevelLabel)
            
            let topConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .top, relatedBy: .equal, toItem: logLevelLabel.superview, attribute: .top, multiplier: 1.0, constant: 8)
            let leftConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .left, relatedBy: .equal, toItem: logLevelLabel.superview, attribute: .left, multiplier: 1.0, constant: 8)
            let bottomConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .bottom, relatedBy: .equal, toItem: logLevelLabel.superview, attribute: .bottom, multiplier: 1.0, constant: -8)
            let rightConstraint = NSLayoutConstraint(item: logLevelLabel, attribute: .right, relatedBy: .equal, toItem: logLevelLabel.superview, attribute: .right, multiplier: 1.0, constant: -8)
            
            NSLayoutConstraint.activate([topConstraint, leftConstraint, bottomConstraint, rightConstraint])
        }
    }
    
    func setUpMessageLabel() {
        messageLabel = UILabel(frame: CGRect.zero)
        messageLabel?.translatesAutoresizingMaskIntoConstraints = false
        messageLabel?.font = UIFont(name: "CourierNewPSMT", size: 18)
        messageLabel?.numberOfLines = 4
        messageLabel?.textColor = UIColor.darkGray
        
        if let messageLabel = messageLabel {
            self.addSubview(messageLabel)
            
            let topConstraint = NSLayoutConstraint(item: messageLabel, attribute: .top, relatedBy: .equal, toItem: messageLabel.superview, attribute: .top, multiplier: 1.0, constant: 8)
            let leftConstraint = NSLayoutConstraint(item: messageLabel, attribute: .left, relatedBy: .equal, toItem: logLevelContainerView, attribute: .right, multiplier: 1.0, constant: 8)
            let rightConstraint = NSLayoutConstraint(item: messageLabel, attribute: .right, relatedBy: .equal, toItem: messageLabel.superview, attribute: .right, multiplier: 1.0, constant: -8)
            NSLayoutConstraint.activate([topConstraint, leftConstraint, rightConstraint])
        }
    }
    
    func colorForLogMessage(_ message: LogMessage) -> UIColor {
        let color: UIColor
        switch message.logLevel {
        case .none:
            color = UIColor(red: 152/255, green: 160/255, blue: 152/255, alpha: 1.0)
        case .error:
            color = UIColor(red: 255/255, green: 91/255, blue: 97/255, alpha: 1.0)
        case .warn:
            color = UIColor(red: 255/255, green: 179/255, blue: 1/255, alpha: 1.0)
        case .info:
            color = UIColor(red: 152/255, green: 160/255, blue: 152/255, alpha: 1.0)
        case .debug:
            color = UIColor(red: 1/255, green: 210/255, blue: 196/255, alpha: 1.0)
        case .verbose:
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        setUpTextView()
        
        if let message = logMessage {
            textView?.text = messageFormatter.formatLogMessage(message)
        }
    }
    
    private func setUpTextView() {
        textView = UITextView(frame: CGRect.zero)
        textView?.backgroundColor = UIColor.white
        textView?.translatesAutoresizingMaskIntoConstraints = false
        textView?.font = UIFont(name: "CourierNewPSMT", size: 18)
        textView?.textColor = UIColor.darkGray
        textView?.isEditable = false
        
        if let textView = textView {
            view.addSubview(textView)
            
            let topConstraint = NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .equal, toItem: textView.superview, attribute: .top, multiplier: 1.0, constant: 8)
            let leftConstraint = NSLayoutConstraint(item: textView, attribute: .left, relatedBy: .equal, toItem: textView.superview, attribute: .left, multiplier: 1.0, constant: 8)
            let rightConstraint = NSLayoutConstraint(item: textView, attribute: .right, relatedBy: .equal, toItem: textView.superview, attribute: .right, multiplier: 1.0, constant: -8)
            let bottomConstraint = NSLayoutConstraint(item: textView, attribute: .bottom, relatedBy: .equal, toItem: textView.superview, attribute: .bottom, multiplier: 1.0, constant: -8)
            NSLayoutConstraint.activate([topConstraint, leftConstraint, rightConstraint, bottomConstraint])
        }
    }
    
}

