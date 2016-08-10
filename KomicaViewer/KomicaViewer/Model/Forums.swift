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
    private static let sharedInstance = Forums()
    private var selectedForum: KomicaForum?
    
    static var selectedForum: KomicaForum? {
        get {
            return sharedInstance.selectedForum
        }
        set {
            sharedInstance.selectedForum = newValue
        }
    }
    
    static var defaultForums = KomicaForumFinder.sharedInstance.forums
    
}