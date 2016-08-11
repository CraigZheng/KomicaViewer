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
    
    static var defaultForums = KomicaForumFinder.sharedInstance.forums
    static var remoteForums: [KomicaForum]?
    
    static func updateRemoteForums() {
        KomicaForumFinder.sharedInstance.loadRemoteForumsWithCompletion({ (success, forums, error) in
            if let forums = forums {
                remoteForums = forums
                // Remote forums updated, send a notification.
                NSNotificationCenter.defaultCenter().postNotificationName(forumsUpdatedNotification, object: nil)
            }
        })
    }
}