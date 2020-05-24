//
//  Configuration.swift
//  Exellency
//
//  Created by Craig Zheng on 12/01/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import Foundation

import AFNetworking
import SwiftMessages

class Configuration: NSObject {
    // MARK: constants
    fileprivate let defaultConfiguration = "defaultConfiguration"
    fileprivate let remoteConfigurationURL = URL(string: "http://civ.atwebpages.com/KomicaViewer/kv_remote_configuration.php?bundleVersion=\(Configuration.bundleVersion)")! // 100% sure not optional.
    fileprivate var updateTimer: Timer?
    @objc static let debugChangedNotification = "debugChangedNotification"
    @objc static let updatedNotification = "Configuration.updatedNotification"
    @objc static var bundleVersion: String {
        // Won't be nil.
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        return "\(versionString)(\(bundleVersion))"
    }
    
    fileprivate let sessionManager = AFHTTPSessionManager.sessionManager()
    
    // MARK: public properties.
    @objc var reportURL: URL?
    @objc var addForumHelpURL: URL?
    @objc var scanForumQRHelpURL: URL?
    @objc var remoteActions = [[String: String]]()
    @objc var announcement: String?
    @objc var updatedWithServer = false
    private(set) var eulaURL = URL(string: "https://www.eulatemplate.com/live.php?token=Y7Mb0qx4K863ZWrQOB2y8JDHpqU1hiEH")!
    var pendingAnnouncement: String?
    
    // MARK: user define settings.
    @objc var showImage: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "showImage")
            NotificationCenter.default.post(name: Notification.Name(rawValue: Configuration.updatedNotification), object: nil)
        }
        get {
            if UserDefaults.standard.object(forKey: "showImage") != nil {
                return UserDefaults.standard.bool(forKey: "showImage")
            } else {
                return true
            }
        }
    }
    var hasAcceptedEULA: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "acceptedEULA")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "acceptedEULA")
            NotificationCenter.default.post(name: Notification.Name(rawValue: Configuration.updatedNotification), object: nil)
        }
    }
    
    @objc var timeout: TimeInterval = 20
    @objc var thumbnailWidth = 50.0
    @objc var debug: Bool {
        get {
            if UserDefaults.standard.object(forKey: "DEBUG") != nil {
                return UserDefaults.standard.bool(forKey: "DEBUG")
            }
            return false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "DEBUG")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: Notification.Name(rawValue: Configuration.debugChangedNotification), object: nil)
        }
    }

    // MARK: Util methods.
    
    // MARK: JSON parsing.
    
    @objc func parseJSONData(_ jsonData: Data)->Bool {
        var parseSuccessful = false
        if let jsonDictionary = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? NSDictionary {
            parseJSONDictionary(jsonDictionary)
            parseSuccessful = true
        }
        return parseSuccessful
    }
    
    @objc func parseJSONDictionary(_ jsonDictionary: NSDictionary) {
        if let timeout = jsonDictionary["timeout"] as? NSNumber {
            self.timeout = TimeInterval(timeout.doubleValue)
        }
        if let reportURL = jsonDictionary["reportURL"] as? String, !reportURL.isEmpty {
            self.reportURL = URL(string: reportURL)
        }
        if let thumbnailWidth = jsonDictionary["thumbnailWidth"] as? NSNumber {
            self.thumbnailWidth = Double(thumbnailWidth.doubleValue)
        }
        if let announcement = jsonDictionary["announcement"] as? String, !announcement.isEmpty {
            self.announcement = announcement
        }
        if let remoteActions = jsonDictionary["remoteActions"] as? [[String: String]] {
            self.remoteActions = remoteActions
        }
        if let addForumHelpURL = jsonDictionary["addForumHelpURL"] as? String, !addForumHelpURL.isEmpty {
            self.addForumHelpURL = URL(string: addForumHelpURL)
        } else {
            self.addForumHelpURL = nil
        }
        if let scanForumQRHelpURL = jsonDictionary["scanForumQRHelpURL"] as? String, !scanForumQRHelpURL.isEmpty {
            self.scanForumQRHelpURL = URL(string: scanForumQRHelpURL)
        } else {
            self.scanForumQRHelpURL = nil
        }
        if let eulaPath = jsonDictionary["eulaURL"] as? String, let eulaURL = URL(string: eulaPath) {
            self.eulaURL = eulaURL
        }
    }
    
    // MARK: Update.
    
    @objc func updateWithCompletion(_ completion: (()->())?) {
        DLog("Updating configuration.")
        sessionManager.dataTask(with: URLRequest(url: remoteConfigurationURL), uploadProgress: nil, downloadProgress: nil) { response, responseObject, error in
            DLog("Updating completed.")
            if error == nil, let responseObject = responseObject as? Data {
                _ = self.parseJSONData(responseObject)
                self.updatedWithServer = true
            }
            if let completion = completion {
                completion()
            }
            // Configuration updated notification.
            NotificationCenter.default.post(name: Notification.Name(rawValue: Configuration.updatedNotification), object: nil)
        }.resume()
    }
    
    // MARK: Init method.
    
    override init() {
        super.init()
        // Init with defaultConfiguration.json file.
        if let defaultJsonURL = Bundle.main.url(forResource: defaultConfiguration, withExtension: "json"),
            let defaultJsonData = try? Data(contentsOf: defaultJsonURL)
        {
            _ = parseJSONData(defaultJsonData)
        }
        
        // Schedule a timer to update once in a while.
        // This solution is copied from http://stackoverflow.com/questions/14924892/nstimer-with-anonymous-function-block
        updateTimer = Timer.scheduledTimer(timeInterval: 60 * 10,
                                                             target: BlockOperation(block: {
                                                                self.updateWithCompletion(nil)
                                                             }),
                                                             selector: #selector(Operation.main),
                                                             userInfo: nil,
                                                             repeats: true)
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                                object: nil,
                                                                queue: OperationQueue.main) { _ in
                                                                    if !self.updatedWithServer {
                                                                        // Update with remote configuration.
                                                                        // Update with remote configuration.
                                                                        self.updateWithCompletion({
                                                                            DLog("Remote notification updates.")
                                                                            if let announcement = self.announcement, !announcement.isEmpty {
                                                                                self.pendingAnnouncement = announcement
                                                                            }
                                                                        })
                                                                    }
        }
    }

    // Singleton.
    @objc static var singleton = Configuration()
}
