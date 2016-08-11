//
//  TableViewControllerBulkUpdateProtocol.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 11/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol TableViewControllerBulkUpdateProtocol: class {
    var targetTableView: UITableView { get }
    var bulkUpdateTimer: NSTimer? { get set }
    var pendingIndexPaths: [NSIndexPath] { get set }
    
    func addPendingIndexPaths(indexPath: NSIndexPath)
}

extension TableViewControllerBulkUpdateProtocol  where Self: UITableViewController {
    
    func addPendingIndexPaths(indexPath: NSIndexPath) {
        DLog("")
        pendingIndexPaths.append(indexPath)
        // If buildUpdateTimer is not currently active, schedule an update for 0.2 seconds later.
        if bulkUpdateTimer == nil || bulkUpdateTimer?.valid == false {
            bulkUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.2),
                                                                    target: NSBlockOperation(block: {
                                                                        self.commitUpdates()
                                                                    }),
                                                                    selector: #selector(NSBlockOperation.main),
                                                                    userInfo: nil,
                                                                    repeats: false)
        }
    }
    
    func commitUpdates() {
        DLog("")
        dispatch_async(dispatch_get_main_queue()) {
            // Commit the updates, then remove them from the pendingIndexPaths and invalidate the timer.
            self.targetTableView.reloadRowsAtIndexPaths(self.pendingIndexPaths, withRowAnimation: .Automatic)
            self.pendingIndexPaths.removeAll()
            self.bulkUpdateTimer?.invalidate()
        }
    }
}