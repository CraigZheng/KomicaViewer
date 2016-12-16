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
    var bulkUpdateTimer: Timer? { get set }
    var pendingIndexPaths: [IndexPath] { get set }
    
    func addPendingIndexPaths(_ indexPath: IndexPath)
}

extension TableViewControllerBulkUpdateProtocol  where Self: UITableViewController {
    
    func addPendingIndexPaths(_ indexPath: IndexPath) {
        DLog("")
        pendingIndexPaths.append(indexPath)
        // If buildUpdateTimer is not currently active, schedule an update for 0.2 seconds later.
        if bulkUpdateTimer == nil || bulkUpdateTimer?.isValid == false {
            bulkUpdateTimer = Timer.scheduledTimer(timeInterval: TimeInterval(0.2),
                                                                    target: BlockOperation(block: {
                                                                        self.commitUpdates()
                                                                    }),
                                                                    selector: #selector(BlockOperation.main),
                                                                    userInfo: nil,
                                                                    repeats: false)
        }
    }
    
    func commitUpdates() {
        DLog("")
        DispatchQueue.main.async {
            // Commit the updates, then remove them from the pendingIndexPaths and invalidate the timer.
            self.targetTableView.reloadRows(at: self.pendingIndexPaths, with: .automatic)
            self.pendingIndexPaths.removeAll()
            self.bulkUpdateTimer?.invalidate()
        }
    }
}
