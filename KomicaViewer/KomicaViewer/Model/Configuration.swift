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
    private let keyworkdKey = "[KEYWORD]"
    private let pageKey = "[PAGE]"
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

    private var _entityListURL: String?
    private var _entityDetailsURL: String?
    private var _entityPageURL: String?
    private var _metaDataURL: String?
    private var _imageKeyID: String?
    private var _searchIndexURL: String?
    private var _debugSearchIndexURL: String?
    private var _searchURL: String?
    private var _debugSearchURL: String?
    
    private let sessionManager = AFHTTPSessionManager.sessionManager()
    
    // MARK: public properties.
    let reportBlacklistURL = NSURL(string: "http://civ.atwebpages.com/exheti/exheti_report_blacklist.php")!
    let downloadBlacklistURL = NSURL(string: "http://civ.atwebpages.com/exheti/exheti_download_blacklist.php")!
    
    var remoteDebug = false
    var allowedCategory = [String]()
    var remoteActions = [[String: String]]()
    var warningKeyword = ""
//    var numberOfDownloaders: Int {
//        var number = 5
//        if AdConfiguration.singleton.shouldDisplayAds {
//            number = 2
//        }
//        return number
//    }
    var announcement: String?
    var updatedWithServer = false
    
    var entityListURL: String? {
        get {
            if let entityListURL = _entityListURL {
                return entityListURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            }
            return nil
        }
        set {
            _entityListURL = newValue
        }
    }
    var entityDetailsURL: String? {
        get {
            if let entityDetailsURL = _entityDetailsURL {
                return entityDetailsURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            }
            return nil
        }
        set {
            _entityDetailsURL = newValue
        }
    }
    var entityPageURL: String? {
        get {
            if let entityPageURL = _entityPageURL {
                return entityPageURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            }
            return nil
        }
        set {
            _entityPageURL = newValue
        }
    }
    var metaDataURL: String? {
        get {
            if let metaDataURL = _metaDataURL {
                return metaDataURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            }
            return nil
        }
        set {
            _metaDataURL = newValue
        }
    }
    var searchIndexURL: String? {
        get {
            if let searchIndexURL = _searchIndexURL {
                return searchIndexURL
            }
            return nil
        }
        set {
            _searchIndexURL = newValue
        }
    }
    var debugSearchIndexURL: String? {
        get {
            if let debugSearchIndexURL = _debugSearchIndexURL {
                return debugSearchIndexURL
            }
            return nil
        }
        set {
            _debugSearchIndexURL = newValue
        }
    }
    var searchURL: String? {
        get {
            if let searchURL = _searchURL {
                return searchURL
            }
            return nil
        }
        set {
            _searchURL = newValue
        }
    }
    var debugSearchURL: String? {
        get {
            if let debugSearchURL = _debugSearchURL {
                return debugSearchURL
            }
            return nil
        }
        set {
            _debugSearchURL = newValue
        }
    }
    var imageKeyID: String? {
        get {
            if let imageKeyID = _imageKeyID {
                return imageKeyID.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            }
            return nil
        }
        set {
            _imageKeyID = newValue
        }
    }
    var imagePerPage = 40
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
    
    func searchURL(keyword:String, page: Int)->NSURL? {
        // Search URL: http://g.e-hentai.org/?f_doujinshi=1&f_manga=1&f_artistcg=1&f_gamecg=1&f_western=1&f_non-h=1&f_imageset=1&f_cosplay=1&f_asianporn=1&f_misc=1&f_search=chinese&f_apply=Apply+Filter
        // Another: http://g.e-hentai.org/?f_doujinshi=1&f_manga=0&f_artistcg=0&f_gamecg=0&f_western=0&f_non-h=1&f_imageset=0&f_cosplay=0&f_asianporn=0&f_misc=0&f_search=chinese&f_apply=Apply+Filter
        
        var searchURLString: String
        // Default - unlikely to happen.
        // Non-h
        searchURLString = "http://g.e-hentai.org/?f_doujinshi=0&f_manga=0&f_artistcg=0&f_gamecg=0&f_western=0&f_non-h=1&f_imageset=0&f_cosplay=0&f_asianporn=0&f_misc=0&f_search=\(keyword)&f_apply=Apply+Filter"

        if Configuration.singleton.debug {
            if let debugSearchIndexURL = debugSearchIndexURL {
                searchURLString = debugSearchIndexURL.stringByReplacingOccurrencesOfString(keyworkdKey, withString: keyword)
            }
        } else {
            // Non-h only.
            if let searchIndexURL = searchIndexURL {
                searchURLString = searchIndexURL.stringByReplacingOccurrencesOfString(keyworkdKey, withString: keyword)
            }
        }
        // For page 2 and above.
        if page > 1 {
            // All.
            if Configuration.singleton.debug {
                if let debugSearchURL = debugSearchURL {
                    searchURLString = debugSearchURL.stringByReplacingOccurrencesOfString(keyworkdKey, withString: keyword)
                        .stringByReplacingOccurrencesOfString(pageKey, withString: "\(page - 1)")
                }
            } else {
                if let searchURL = searchURL {
                    searchURLString = searchURL.stringByReplacingOccurrencesOfString(keyworkdKey, withString: keyword)
                    .stringByReplacingOccurrencesOfString(pageKey, withString: "\(page - 1)")
                }
            }
        }
        return NSURL(string: searchURLString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
    }
    
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
        if let entityListURL = jsonDictionary["entityListURL"] as? String {
            self.entityListURL = entityListURL
        }
        if let entityDetailsURL = jsonDictionary["entityDetailsURL"] as? String {
            self.entityDetailsURL = entityDetailsURL
        }
        if let entityPageURL = jsonDictionary["entityPageURL"] as? String {
            self.entityPageURL = entityPageURL
        }
        if let searchIndexURL = jsonDictionary["searchIndexURL"] as? String {
            self.searchIndexURL = searchIndexURL
        }
        if let debugSearchIndexURL = jsonDictionary["debugSearchIndexURL"] as? String {
            self.debugSearchIndexURL = debugSearchIndexURL
        }
        if let searchURL = jsonDictionary["searchURL"] as? String {
            self.searchURL = searchURL
        }
        if let debugSearchURL = jsonDictionary["debugSearchURL"] as? String {
            self.debugSearchURL = debugSearchURL
        }
        if let metaDataURL = jsonDictionary["metaDataURL"] as? String {
            self.metaDataURL = metaDataURL
        }
        if let imageKeyID = jsonDictionary["imageKeyID"] as? String {
            self.imageKeyID = imageKeyID
        }
        if let imagePerPage = jsonDictionary["imagePerPage"] as? NSNumber {
            self.imagePerPage = Int(imagePerPage.intValue)
        }
        if let timeout = jsonDictionary["timeout"] as? NSNumber {
            self.timeout = NSTimeInterval(timeout.doubleValue)
        }
        if let thumbnailWidth = jsonDictionary["thumbnailWidth"] as? NSNumber {
            self.thumbnailWidth = Double(thumbnailWidth.doubleValue)
        }
        if let remoteDebug = jsonDictionary["remoteDebug"] as? NSNumber {
            self.remoteDebug = remoteDebug.boolValue
            self.debug = self.remoteDebug
        }
        if let allowedCategory = jsonDictionary["allowedCategory"] as? Array<String> {
            self.allowedCategory = allowedCategory
        }
        if let warningKeyword = jsonDictionary["warningKeyword"] as? String {
            self.warningKeyword = warningKeyword
        }
        if let announcement = jsonDictionary["announcement"] as? String {
            self.announcement = announcement
        }
        if let remoteActions = jsonDictionary["remoteActions"] as? [[String: String]] {
            self.remoteActions = remoteActions
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
