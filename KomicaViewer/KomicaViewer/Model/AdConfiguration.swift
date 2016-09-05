//
//  AdConfiguration.swift
//  Exellency
//
//  Created by Craig Zheng on 6/08/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import UIKit

class AdConfiguration: NSObject {
    var enableAd = true
    var dailyAdClickLimit = 3
    var weeklyAdClickLimit = 9
    var monthlyAdClickLimit = 18
    var adDescription: String?
    var shouldDisplayAds: Bool {
        var should = enableAd
        if should {
            // If user has clicked the ads many times, return false.
            let yesterDay = NSDate().dateByAddingTimeInterval(-(24 * 3600))
            let lastWeek = NSDate().dateByAddingTimeInterval(-(7 * 24 * 3600))
            let lastMonth = NSDate().dateByAddingTimeInterval(-(30 * 7 * 24 * 3600))
            var dayClicks = 0
            var weekClicks = 0
            var monthClicks = 0
            // Calculate the clicks for each time period.
            for clickedDate in historyOfClicks.reverse() {
                if clickedDate.compare(yesterDay) == .OrderedDescending {
                    dayClicks += 1
                    weekClicks += 1
                    monthClicks += 1
                } else if clickedDate.compare(lastWeek) == .OrderedDescending {
                    weekClicks += 1
                    monthClicks += 1
                } else if clickedDate.compare(lastMonth) == .OrderedDescending {
                    monthClicks += 1
                }
            }
            if dayClicks >= dailyAdClickLimit || weekClicks >= weeklyAdClickLimit || monthClicks >= monthlyAdClickLimit {
                should = false
            }
        }
        return should
    }
    var historyOfClicks = [NSDate]()
    static let singleton = AdConfiguration()
    static let adConfigurationUpdatedNotification = "adConfigurationUpdatedNotification"
    
    struct AdMobID {
        static let bannerID1 = "ca-app-pub-2081665256237089/9633270459"
        static let bannerID2 = "ca-app-pub-2081665256237089/1411999652"
    }
    
    // Private properties.
    private let defaultConfiguration = "defaultAdConfiguration"
    private let historyKey = "AdConfiguration.historyOfClicks"
    private let defaultSession = NSURLSession(configuration: .defaultSessionConfiguration())
    private let remoteConfigurationURL = NSURL(string: "http://civ.atwebpages.com/KomicaViewer/kv_remote_ad_configuration.php")!
    private struct DictionaryKey {
        static let enableAd = "enableAd"
        static let dailyAdClickLimit = "dailyAdClickLimit"
        static let weeklyAdClickLimit = "weeklyAdClickLimit"
        static let monthlyAdClickLimit = "monthlyAdClickLimit"
        static let adDescription = "adDescription"
    }
    
    override init() {
        super.init()
        // Init with defaultConfiguration.json file.
        if let defaultJsonURL = NSBundle.mainBundle().URLForResource(defaultConfiguration, withExtension: "json"),
            defaultJsonData = NSData(contentsOfURL: defaultJsonURL)
        {
            parseJSONData(defaultJsonData)
        }
        // Restore historyOfClicks array.
        if let historyOfClicks = NSUserDefaults.standardUserDefaults().arrayForKey(historyKey) as? [NSDate] {
            self.historyOfClicks = historyOfClicks
        }
        // Update with remote configuration.
        updateAdConfiguration({
            NSNotificationCenter.defaultCenter().postNotificationName(AdConfiguration.adConfigurationUpdatedNotification,
                object: nil)
        })
    }
    
    func updateAdConfiguration(completion: (()->())?) {
        defaultSession.dataTaskWithRequest(NSURLRequest(URL: remoteConfigurationURL)) { (responseObject, response, error) in
            if let responseObject = responseObject {
                self.parseJSONData(responseObject)
            }
            completion?()
        }.resume()
    }
    
    func clickedAd() {
        historyOfClicks.append(NSDate())
        // Save history.
        NSUserDefaults.standardUserDefaults().setObject(historyOfClicks, forKey: historyKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        // History updated.
        NSNotificationCenter.defaultCenter().postNotificationName(AdConfiguration.adConfigurationUpdatedNotification,
                                                                  object: nil)
    }
    
    // MARK: Private methods.
    private func parseJSONData(jsonData: NSData) {
        if let rawDict = try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers) as? [String: AnyObject],
            let jsonDict = rawDict {
            if let enableAd = jsonDict[DictionaryKey.enableAd] as? NSNumber {
                self.enableAd = enableAd.boolValue
            }
            if let dailyAdClickLimit = jsonDict[DictionaryKey.dailyAdClickLimit] as? NSNumber {
                self.dailyAdClickLimit = dailyAdClickLimit.integerValue
            }
            if let weeklyAdClickLimit = jsonDict[DictionaryKey.weeklyAdClickLimit] as? NSNumber {
                self.weeklyAdClickLimit = weeklyAdClickLimit.integerValue
            }
            if let monthlyAdClickLimit = jsonDict[DictionaryKey.monthlyAdClickLimit] as? NSNumber {
                self.monthlyAdClickLimit = monthlyAdClickLimit.integerValue
            }
            if let adDescription = jsonDict[DictionaryKey.adDescription] as? String {
                self.adDescription = adDescription
            }
        }
    }
}
