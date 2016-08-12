//
//  HomeTableViewController.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import MWPhotoBrowser
import SDWebImage

class HomeTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol {
    
    // MARK: ThreadTableViewControllerProtocol
    var threads = [Thread]()
    func refreshWithPage(page: Int) {
        loadThreadsWithPage(page)
    }
    
    // MARK: TableViewControllerBulkUpdateProtocol
    var targetTableView: UITableView {
        return self.tableView
    }
    var bulkUpdateTimer: NSTimer?
    var pendingIndexPaths: [NSIndexPath] = [NSIndexPath]()
    
    private var selectedPhoto: MWPhoto?
    private var photoBrowser: MWPhotoBrowser?
    private var pageIndex = 0
    private let showThreadSegue = "showThread"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        tableView.registerNib(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Add handler for Forum selected notification.
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(HomeTableViewController.handleForumSelectedNotification(_:)),
                                                         name: Forums.selectionUpdatedNotification,
                                                         object: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ThreadTableViewCell.identifier, forIndexPath: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = threads[indexPath.row]
            // Home view does not show parasite view.
            cell.shouldShowParasitePost = false
            cell.layoutWithThread(thread, forTableViewController: self)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(showThreadSegue, sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
}

// MARK: Prepare for segue.
extension HomeTableViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let selectedCell = sender as? UITableViewCell,
            let destinationViewController = segue.destinationViewController as? ThreadTableViewController,
            let indexPath = tableView.indexPathForCell(selectedCell)
        {
            destinationViewController.selectedThread = threads[indexPath.row]
        }
    }
    
}

// MARK: UIActions.
extension HomeTableViewController: MWPhotoBrowserDelegate {
    
    @IBAction func unwindToHomeSegue(segue: UIStoryboardSegue) {
        // Unwind to home.
    }
    
    @IBAction func tapOnImageView(sender: AnyObject) {
        if let sender = sender as? UIView,
            let cell = sender.superCell(),
            let indexPath = tableView.indexPathForCell(cell),
            let imageURL = threads[indexPath.row].imageURL
        {
            selectedPhoto = MWPhoto(URL: imageURL)
            photoBrowser = MWPhotoBrowser(delegate: self)
            // Present
            navigationController?.pushViewController(photoBrowser!, animated:true)
        }
    }
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        return selectedPhoto == nil ? 0 : 1
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        return selectedPhoto ?? MWPhoto()
    }
    
}

// MARK: Forum selected notification handler.
extension HomeTableViewController {
    
    func handleForumSelectedNotification(notification: NSNotification) {
        title = forum?.name
        threads.removeAll()
        tableView.reloadData()
        refreshWithPage(0)
    }
    
}