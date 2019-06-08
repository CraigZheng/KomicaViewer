//
//  BlockedUserManager.swift
//  KomicaViewer
//
//  Created by Craig on 5/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class BlockedUserManager: NSObject {
    @objc static let sharedManager = BlockedUserManager()
    @objc static let updatedNotification = "BlockedUserUpdatedNotification"
    fileprivate let BlockedUserIDKey = "BlockedUserIDKey"
    
    fileprivate var blockedUserIDs = [String]()
    
    fileprivate func save() {
        UserDefaults.standard.set(blockedUserIDs, forKey: BlockedUserIDKey)
        UserDefaults.standard.synchronize()
    }
    
    fileprivate func restore() {
        if let restoredObjects = UserDefaults.standard.object(forKey: BlockedUserIDKey) as? [String] {
            blockedUserIDs = restoredObjects
        }
    }
    
    override init() {
        super.init()
        restore()
    }
    
    @objc func blockUserID(_ id: String) {
        blockedUserIDs.append(id)
        // A bit of safty measure, when more than 9999, drop the first entity.
        if blockedUserIDs.count > 9999 {
            blockedUserIDs.removeFirst()
        }
        save()
        NotificationCenter.default.post(name: Notification.Name(rawValue: BlockedUserManager.updatedNotification), object: nil)
    }
    
    @objc func unblockUserID(_ id: String) {
        blockedUserIDs.removeObject(id)
        save()
        NotificationCenter.default.post(name: Notification.Name(rawValue: BlockedUserManager.updatedNotification), object: nil)
    }
    
    @objc func isUserIDBlocked(_ id: String) -> Bool {
        return blockedUserIDs.contains(id)
    }
}
