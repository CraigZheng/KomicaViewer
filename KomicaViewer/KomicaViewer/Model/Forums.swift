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
    
    private static let sharedInstance = Forums()
    private static let customForumsKey = "customForumsKey"
    private var selectedForum: KomicaForum?
    
    static var selectedForum: KomicaForum? {
        get {
            return sharedInstance.selectedForum
        }
        set {
            if sharedInstance.selectedForum != newValue {
                sharedInstance.selectedForum = newValue
                // Selection updated, send a notification for this.
                NSNotificationCenter.defaultCenter().postNotificationName(selectionUpdatedNotification, object: nil)
            }
        }
    }
    
    static var defaultForumsGroup = KomicaForumFinder.sharedInstance.forumGroups
    static var remoteForumGroup: [KomicaForumGroup]?
    static let customForumGroup: KomicaForumGroup = {
        let group = KomicaForumGroup()
        group.name = "Custom Boards"
        group.forums = [KomicaForum]()
        if let forums = Forums.restoreCustomForums() {
            group.forums = forums
        }
        return group
    }()
    static func updateRemoteForums() {
        KomicaForumFinder.sharedInstance.loadRemoteForumsWithCompletion({ (success, groups, error) in
            if let groups = groups {
                remoteForumGroup = groups
                // Remote forums updated, send a notification.
                NSNotificationCenter.defaultCenter().postNotificationName(forumsUpdatedNotification, object: nil)
            }
        })
    }

    class func addCustomForum(forum: KomicaForum) {
        customForumGroup.forums?.append(forum)
        saveCustomForums()
    }
    
    private class func saveCustomForums() {
        if let customForums = Forums.customForumGroup.forums {
            var jsonStrings = [String]()
            customForums.forEach({forum in
                if let jsonString = forum.jsonEncode() {
                    jsonStrings.append(jsonString)
                }
            })
            if !jsonStrings.isEmpty {
                // Save to user default for now.
                NSUserDefaults.standardUserDefaults().setObject(jsonStrings, forKey: Forums.customForumsKey)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    
    private class func restoreCustomForums() -> [KomicaForum]? {
        if let jsonStrings = NSUserDefaults.standardUserDefaults().objectForKey(Forums.customForumsKey) as? [String] {
            var forums = [KomicaForum]()
            jsonStrings.forEach({jsonString in
                if let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
                    let rawDict = try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? Dictionary<String, AnyObject>,
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