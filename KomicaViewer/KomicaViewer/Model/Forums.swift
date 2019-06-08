//
//  SelectedForum.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import Foundation

import KomicaEngine

class Forums {
    // Forum notifications.
    static let selectionUpdatedNotification = "Forums.selectionUpdatedNotification"
    static let forumsUpdatedNotification = "Forums.forumsUpdatedNotification"
    
    fileprivate static let sharedInstance = Forums()
    fileprivate static let customForumsKey = "customForumsKey"
    fileprivate static let futabaUpdateURL = URL(string: "http://civ.atwebpages.com/KomicaViewer/2chan_remote_forums.html")!
    fileprivate var selectedForum: KomicaForum?
    
    static var selectedForum: KomicaForum? {
        get {
            return sharedInstance.selectedForum
        }
        set {
            if sharedInstance.selectedForum != newValue {
                sharedInstance.selectedForum = newValue
                // Selection updated, send a notification for this.
                NotificationCenter.default.post(name: Notification.Name(rawValue: selectionUpdatedNotification), object: nil)
            }
        }
    }
    
    static var defaultForumsGroups = KomicaForumFinder.sharedInstance.forumGroups
    static var remoteForumGroups: [KomicaForumGroup]?
    static let customForumGroup: KomicaForumGroup = {
        let group = KomicaForumGroup()
        group.name = "Custom Boards"
        group.forums = [KomicaForum]()
        if let forums = Forums.restoreCustomForums() {
            group.forums = forums
        }
        return group
    }()
    static var futabaForumGroup: [KomicaForumGroup]?
    
    static func updateRemoteForums() {
        KomicaForumFinder.sharedInstance.loadRemoteForumsWithCompletion({ (success, groups, error) in
            if let groups = groups {
                remoteForumGroups = groups
                // Remote forums updated, send a notification.
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: forumsUpdatedNotification), object: nil)
            }
        })
    }
    
    static func updateRemoteFutabaForums() {
        URLSession(configuration: .default).dataTask(with: futabaUpdateURL) { data, response, error in
            guard let data = data else {
                return
            }
            let forums = (ObjectiveGumbo.parseDocument(with: data, encoding: String.Encoding.shiftJIS.rawValue).elements(with: OGTag.A) as? [OGElement])?.compactMap { element -> KomicaForum? in
                guard let attributes = element.attributes as? [String: String],
                    let linkAttribute = attributes.filter({ $0.0 == "href" }).first,
                    linkAttribute.value.contains("futaba.htm") else {
                        return nil
                }
                let link = linkAttribute.value.replacingOccurrences(of: "//", with: "http://")
                let jsonDictionary: [String: AnyObject] = ["name": element.text() as NSString,
                                                           "startingIndex": 0 as NSNumber,
                                                           "indexURL": link as NSString,
                                                           "listURL": link.replacingOccurrences(of: "futaba", with: "<PAGE>") as NSString,
                                                           "responseURL": link.replacingOccurrences(of: "futaba", with: "res/<ID>") as NSString,
                                                           "parserType": 5 as NSNumber]
                return KomicaForum(jsonDict: jsonDictionary)
            }
            let forumGroup = KomicaForumGroup()
            forumGroup.name = "2 chan"
            forumGroup.forums = forums
            futabaForumGroup = [forumGroup]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: forumsUpdatedNotification), object: nil)
        }.resume()
    }

    class func addCustomForum(_ forum: KomicaForum) {
        customForumGroup.forums?.append(forum)
        saveCustomForums()
    }
    
    class func saveCustomForums() {
        if let customForums = Forums.customForumGroup.forums {
            var jsonStrings = [String]()
            customForums.forEach({forum in
                if let jsonString = forum.jsonEncode() {
                    jsonStrings.append(jsonString)
                }
            })
            if !jsonStrings.isEmpty {
                // Save to user default for now.
                UserDefaults.standard.set(jsonStrings, forKey: Forums.customForumsKey)
                UserDefaults.standard.synchronize()
            } else {
                // Remove everything.
                UserDefaults.standard.removeObject(forKey: Forums.customForumsKey)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    fileprivate class func restoreCustomForums() -> [KomicaForum]? {
        if let jsonStrings = UserDefaults.standard.object(forKey: Forums.customForumsKey) as? [String] {
            var forums = [KomicaForum]()
            jsonStrings.forEach({jsonString in
                if let jsonData = jsonString.data(using: String.Encoding.utf8),
                    let rawDict = ((try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? Dictionary<String, AnyObject>) as Dictionary<String, AnyObject>??),
                    let jsonDict = rawDict
                {
                    let forum = KomicaForum(jsonDict: jsonDict)
                    forums.append(forum)
                }
            })
            return forums
        }
        return nil
    }
}
