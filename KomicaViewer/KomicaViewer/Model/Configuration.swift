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
    static let debugChangedNotification = "debugChangedNotification"
    static let updatedNotification = "Configuration.updatedNotification"
    static var bundleVersion: String {
        // Won't be nil.
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        return "\(versionString)(\(bundleVersion))"
    }
    
    fileprivate let sessionManager = AFHTTPSessionManager.sessionManager()
    
    // MARK: public properties.
    var reportURL: URL?
    var addForumHelpURL: URL?
    var scanForumQRHelpURL: URL?
    var remoteActions = [[String: String]]()
    var announcement: String?
    var updatedWithServer = false
    
    // MARK: user define settings.
    var showImage: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "showImage")
            UserDefaults.standard.synchronize()
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
    
    var timeout: TimeInterval = 20
    var thumbnailWidth = 50.0
    var debug: Bool {
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
    
    func parseJSONData(_ jsonData: Data)->Bool {
        var parseSuccessful = false
        if let jsonDictionary = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? NSDictionary {
            parseJSONDictionary(jsonDictionary)
            parseSuccessful = true
        }
        return parseSuccessful
    }
    
    func parseJSONDictionary(_ jsonDictionary: NSDictionary) {
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
    }
    
    // MARK: Update.
    
    func updateWithCompletion(_ completion: (()->())?) {
        DLog("Updating configuration.")
        sessionManager.dataTask(with: URLRequest(url: remoteConfigurationURL)) { response, responseObject, error in
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
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive,
                                                                object: nil,
                                                                queue: OperationQueue.main) { _ in
                                                                    if !self.updatedWithServer {
                                                                        // Update with remote configuration.
                                                                        // Update with remote configuration.
                                                                        self.updateWithCompletion({
                                                                            DLog("Remote notification updates.")
                                                                            if let announcement = self.announcement, !announcement.isEmpty {
                                                                                DispatchQueue.main.async(execute: {
                                                                                    MessagePopup.showMessage(title: "Announcement",
                                                                                                             message: announcement,
                                                                                                             layout: .cardView,
                                                                                                             theme: .info,
                                                                                                             position: .bottom,
                                                                                                             buttonTitle: "OK",
                                                                                                             buttonActionHandler: { _ in
                                                                                                                SwiftMessages.hide()
                                                                                    })
                                                                                })
                                                                            }
                                                                        })
                                                                    }
        }
    }

    // Singleton.
    static var singleton = Configuration()
}
