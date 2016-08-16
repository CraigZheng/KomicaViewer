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
    
    static func updateRemoteForums() {
        KomicaForumFinder.sharedInstance.loadRemoteForumsWithCompletion({ (success, groups, error) in
            if let groups = groups {
                remoteForumGroup = groups
                // Remote forums updated, send a notification.
                NSNotificationCenter.defaultCenter().postNotificationName(forumsUpdatedNotification, object: nil)
            }
        })
    }
}