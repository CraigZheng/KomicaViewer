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
            let yesterDay = Date().addingTimeInterval(-(24 * 3600))
            let lastWeek = Date().addingTimeInterval(-(7 * 24 * 3600))
            let lastMonth = Date().addingTimeInterval(-(30 * 7 * 24 * 3600))
            var dayClicks = 0
            var weekClicks = 0
            var monthClicks = 0
            // Calculate the clicks for each time period.
            for clickedDate in historyOfClicks.reversed() {
                if clickedDate.compare(yesterDay) == .orderedDescending {
                    dayClicks += 1
                    weekClicks += 1
                    monthClicks += 1
                } else if clickedDate.compare(lastWeek) == .orderedDescending {
                    weekClicks += 1
                    monthClicks += 1
                } else if clickedDate.compare(lastMonth) == .orderedDescending {
                    monthClicks += 1
                }
            }
            if dayClicks >= dailyAdClickLimit || weekClicks >= weeklyAdClickLimit || monthClicks >= monthlyAdClickLimit {
                should = false
            }
        }
        return should
    }
    var historyOfClicks = [Date]()
    static let singleton = AdConfiguration()
    static let adConfigurationUpdatedNotification = "adConfigurationUpdatedNotification"
    
    struct AdMobID {
        static let bannerID1 = "ca-app-pub-2081665256237089/9633270459"
        static let bannerID2 = "ca-app-pub-2081665256237089/1411999652"
    }
    
    // Private properties.
    fileprivate let defaultConfiguration = "defaultAdConfiguration"
    fileprivate let historyKey = "AdConfiguration.historyOfClicks"
    fileprivate let defaultSession = URLSession(configuration: .default)
    fileprivate let remoteConfigurationURL = URL(string: "http://civ.atwebpages.com/KomicaViewer/kv_remote_ad_configuration.php")!
    fileprivate struct DictionaryKey {
        static let enableAd = "enableAd"
        static let dailyAdClickLimit = "dailyAdClickLimit"
        static let weeklyAdClickLimit = "weeklyAdClickLimit"
        static let monthlyAdClickLimit = "monthlyAdClickLimit"
        static let adDescription = "adDescription"
    }
    
    override init() {
        super.init()
        // Init with defaultConfiguration.json file.
        if let defaultJsonURL = Bundle.main.url(forResource: defaultConfiguration, withExtension: "json"),
            let defaultJsonData = try? Data(contentsOf: defaultJsonURL)
        {
            parseJSONData(defaultJsonData)
        }
        // Restore historyOfClicks array.
        if let historyOfClicks = UserDefaults.standard.array(forKey: historyKey) as? [Date] {
            self.historyOfClicks = historyOfClicks
        }
        // Update with remote configuration.
        updateAdConfiguration({
            NotificationCenter.default.post(name: Notification.Name(rawValue: AdConfiguration.adConfigurationUpdatedNotification),
                object: nil)
        })
    }
    
    func updateAdConfiguration(_ completion: (()->())?) {
        DLog("")
        defaultSession.dataTask(with: URLRequest(url: remoteConfigurationURL), completionHandler: { (responseObject, response, error) in
            if let responseObject = responseObject {
                self.parseJSONData(responseObject)
            }
            DLog("")
            completion?()
        }) .resume()
    }
    
    func clickedAd() {
        historyOfClicks.append(Date())
        // Save history.
        UserDefaults.standard.set(historyOfClicks, forKey: historyKey)
        UserDefaults.standard.synchronize()
        // History updated.
        NotificationCenter.default.post(name: Notification.Name(rawValue: AdConfiguration.adConfigurationUpdatedNotification),
                                                                  object: nil)
    }
    
    // MARK: Private methods.
    fileprivate func parseJSONData(_ jsonData: Data) {
        if let rawDict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: AnyObject],
            let jsonDict = rawDict {
            if let enableAd = jsonDict[DictionaryKey.enableAd] as? NSNumber {
                self.enableAd = enableAd.boolValue
            }
            if let dailyAdClickLimit = jsonDict[DictionaryKey.dailyAdClickLimit] as? NSNumber {
                self.dailyAdClickLimit = dailyAdClickLimit.intValue
            }
            if let weeklyAdClickLimit = jsonDict[DictionaryKey.weeklyAdClickLimit] as? NSNumber {
                self.weeklyAdClickLimit = weeklyAdClickLimit.intValue
            }
            if let monthlyAdClickLimit = jsonDict[DictionaryKey.monthlyAdClickLimit] as? NSNumber {
                self.monthlyAdClickLimit = monthlyAdClickLimit.intValue
            }
            if let adDescription = jsonDict[DictionaryKey.adDescription] as? String {
                self.adDescription = adDescription
            }
        }
    }
}
