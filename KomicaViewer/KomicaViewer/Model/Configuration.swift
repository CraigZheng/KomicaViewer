//
//  Configuration.swift
//  Exellency
//
//  Created by Craig Zheng on 12/01/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import Foundation

import AFNetworking

class Configuration: NSObject {
    // MARK: constants
    private let defaultConfiguration = "defaultConfiguration"
    private let remoteConfigurationURL = NSURL(string: "http://civ.atwebpages.com/KomicaViewer/kv_remote_configuration.php?bundleVersion=\(Configuration.bundleVersion)")! // 100% sure not optional.
    private var updateTimer: NSTimer?
    static let debugChangedNotification = "debugChangedNotification"
    static let updatedNotification = "Configuration.updatedNotification"
    static var bundleVersion: String {
        // Won't be nil.
        let bundleVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion")!
        let versionString = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString")!
        return "\(versionString)(\(bundleVersion))"
    }
    
    private let sessionManager = AFHTTPSessionManager.sessionManager()
    
    // MARK: public properties.
    var reportURL: NSURL?
    var addForumHelpURL: NSURL?
    var remoteActions = [[String: String]]()
    var announcement: String?
    var updatedWithServer = false
    
    var timeout: NSTimeInterval = 20
    var thumbnailWidth = 50.0
    var debug: Bool {
        get {
            if NSUserDefaults.standardUserDefaults().objectForKey("DEBUG") != nil {
                return NSUserDefaults.standardUserDefaults().boolForKey("DEBUG")
            }
            return false
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "DEBUG")
            NSUserDefaults.standardUserDefaults().synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(Configuration.debugChangedNotification, object: nil)
        }
    }

    // MARK: Util methods.
    
    // MARK: JSON parsing.
    
    func parseJSONData(jsonData: NSData)->Bool {
        var parseSuccessful = false
        if let jsonDictionary = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
            parseJSONDictionary(jsonDictionary)
            parseSuccessful = true
        }
        return parseSuccessful
    }
    
    func parseJSONDictionary(jsonDictionary: NSDictionary) {
        if let timeout = jsonDictionary["timeout"] as? NSNumber {
            self.timeout = NSTimeInterval(timeout.doubleValue)
        }
        if let reportURL = jsonDictionary["reportURL"] as? String {
            self.reportURL = NSURL(string: reportURL)
        }
        if let thumbnailWidth = jsonDictionary["thumbnailWidth"] as? NSNumber {
            self.thumbnailWidth = Double(thumbnailWidth.doubleValue)
        }
        if let announcement = jsonDictionary["announcement"] as? String {
            self.announcement = announcement
        }
        if let remoteActions = jsonDictionary["remoteActions"] as? [[String: String]] {
            self.remoteActions = remoteActions
        }
        if let addForumHelpURL = jsonDictionary["addForumHelpURL"] as? String {
            self.addForumHelpURL = NSURL(string: addForumHelpURL)
        } else {
            self.addForumHelpURL = nil
        }
    }
    
    // MARK: Update.
    
    func updateWithCompletion(completion: (()->())?) {
        DLog("Updating configuration.")
        sessionManager.dataTaskWithRequest(NSURLRequest(URL: remoteConfigurationURL)) { response, responseObject, error in
            DLog("Updating completed.")
            if error == nil, let responseObject = responseObject as? NSData {
                self.parseJSONData(responseObject)
                self.updatedWithServer = true
            }
            if let completion = completion {
                completion()
            }
            // Configuration updated notification.
            NSNotificationCenter.defaultCenter().postNotificationName(Configuration.updatedNotification, object: nil)
        }.resume()
    }
    
    // MARK: Init method.
    
    override init() {
        super.init()
        // Init with defaultConfiguration.json file.
        if let defaultJsonURL = NSBundle.mainBundle().URLForResource(defaultConfiguration, withExtension: "json"),
            defaultJsonData = NSData(contentsOfURL: defaultJsonURL)
        {
            parseJSONData(defaultJsonData)
        }
        
        // Schedule a timer to update once in a while.
        // This solution is copied from http://stackoverflow.com/questions/14924892/nstimer-with-anonymous-function-block
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(60 * 10,
                                                             target: NSBlockOperation(block: {
                                                                self.updateWithCompletion(nil)
                                                             }),
                                                             selector: #selector(NSOperation.main),
                                                             userInfo: nil,
                                                             repeats: true)
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification,
                                                                object: nil,
                                                                queue: NSOperationQueue.mainQueue()) { _ in
                                                                    if !self.updatedWithServer {
                                                                        // Update with remote configuration.
                                                                        // Update with remote configuration.
                                                                        self.updateWithCompletion({
                                                                            DLog("Remote notification updates.")
                                                                            if let announcement = self.announcement where !announcement.isEmpty {
                                                                                dispatch_async(dispatch_get_main_queue(), {
                                                                                    ProgressHUD.showMessage(announcement)
                                                                                })
                                                                            }
                                                                        })
                                                                    }
        }
    }

    // Singleton.
    static var singleton = Configuration()
}
