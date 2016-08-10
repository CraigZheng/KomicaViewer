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
    // Selection updated notification.
    static let selectionUpdatedNotification = "Forums.selectionUpdatedNotification"
    
    private static let sharedInstance = Forums()
    private var selectedForum: KomicaForum?
    
    static var selectedForum: KomicaForum? {
        get {
            return sharedInstance.selectedForum
        }
        set {
            sharedInstance.selectedForum = newValue
            // Selection updated, send a notification for this.
            NSNotificationCenter.defaultCenter().postNotificationName(selectionUpdatedNotification, object: nil)
        }
    }
    
    static var defaultForums = KomicaForumFinder.sharedInstance.forums
    
}