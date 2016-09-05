//
//  BlockedUserManager.swift
//  KomicaViewer
//
//  Created by Craig on 5/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class BlockedUserManager: NSObject {
    static let sharedmanager = BlockedUserManager()
    private let BlockedUserIDKey = "BlockedUserIDKey"
    
    private var blockedUserIDs = [String]()
    
    private func save() {
        NSUserDefaults.standardUserDefaults().setObject(blockedUserIDs, forKey: BlockedUserIDKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func restore() {
        if let restoredObjects = NSUserDefaults.standardUserDefaults().objectForKey(BlockedUserIDKey) as? [String] {
            blockedUserIDs = restoredObjects
        }
    }
    
    override init() {
        super.init()
        restore()
    }
    
    func blockUserID(id: String) {
        blockedUserIDs.append(id)
        save()
    }
    
    func unblockUserID(id: String) {
        blockedUserIDs.removeObject(id)
        save()
    }
    
    func isUserIDBlocked(id: String) -> Bool {
        return blockedUserIDs.contains(id)
    }
}
