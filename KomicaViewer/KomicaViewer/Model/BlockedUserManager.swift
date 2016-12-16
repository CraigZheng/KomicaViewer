//
//  BlockedUserManager.swift
//  KomicaViewer
//
//  Created by Craig on 5/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class BlockedUserManager: NSObject {
    static let sharedManager = BlockedUserManager()
    static let updatedNotification = "BlockedUserUpdatedNotification"
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
    
    func blockUserID(_ id: String) {
        blockedUserIDs.append(id)
        // A bit of safty measure, when more than 9999, drop the first entity.
        if blockedUserIDs.count > 9999 {
            blockedUserIDs.removeFirst()
        }
        save()
        NotificationCenter.default.post(name: Notification.Name(rawValue: BlockedUserManager.updatedNotification), object: nil)
    }
    
    func unblockUserID(_ id: String) {
        blockedUserIDs.removeObject(id)
        save()
        NotificationCenter.default.post(name: Notification.Name(rawValue: BlockedUserManager.updatedNotification), object: nil)
    }
    
    func isUserIDBlocked(_ id: String) -> Bool {
        return blockedUserIDs.contains(id)
    }
}
