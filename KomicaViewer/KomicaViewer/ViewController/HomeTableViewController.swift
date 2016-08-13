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
import SVPullToRefresh

class HomeTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol {
    
    // MARK: ThreadTableViewControllerProtocol
    var threads = [Thread]()
    func refresh() {
        refreshWithPage(0)
    }
    func refreshWithPage(page: Int) {
        DLog(" - \(page)")
        loadThreadsWithPage(page)
    }
    lazy var postCompletion: KomicaDownloaderHandler? = { (success, page, result) in
        // Update the current page.
        self.pageIndex = page
        ProgressHUD.showMessage("Loaded the \(page + 1) page")
        // If the originalContentInset is nil, record it, otherwise apply it to the tableView.
        // This is due to a bug that is introduced by SVPullToRefresh library. In order to fix this bug, I need to manually adjust the content inset.
        if let originalContentInset = self.originalContentInset {
            self.tableView.contentInset = originalContentInset
        } else {
            self.originalContentInset = self.tableView.contentInset
        }
    }
    
    // MARK: TableViewControllerBulkUpdateProtocol
    var targetTableView: UITableView {
        return self.tableView
    }
    var bulkUpdateTimer: NSTimer?
    var pendingIndexPaths: [NSIndexPath] = [NSIndexPath]()
    
    private var selectedPhoto: MWPhoto?
    private var originalContentInset: UIEdgeInsets?
    private var photoBrowser: MWPhotoBrowser {
        let photoBrowser = MWPhotoBrowser(delegate: self)
        photoBrowser.displayNavArrows = true; // Whether to display left and right nav arrows on toolbar (defaults to false)
        photoBrowser.displaySelectionButtons = false; // Whether selection buttons are shown on each image (defaults to false)
        photoBrowser.zoomPhotosToFill = false; // Images that almost fill the screen will be initially zoomed to fill (defaults to true)
        photoBrowser.alwaysShowControls = false; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to false)
        photoBrowser.enableGrid = true; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to true)
        photoBrowser.startOnGrid = false; // Whether to start on the grid of thumbnails instead of the first photo (defaults to false)
        photoBrowser.delayToHideElements = UInt(8);
        photoBrowser.enableSwipeToDismiss = false; // dont dismiss
        photoBrowser.displayActionButton = true;
        photoBrowser.hidesBottomBarWhenPushed = true;
        return photoBrowser
    }
    private var pageIndex = 0
    private let showThreadSegue = "showThread"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(HomeTableViewController.refresh),
                                  forControlEvents: UIControlEvents.ValueChanged)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        tableView.registerNib(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Add handler for Forum selected notification.
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(HomeTableViewController.handleForumSelectedNotification(_:)),
                                                         name: Forums.selectionUpdatedNotification,
                                                         object: nil)
        tableView.addPullToRefreshWithActionHandler({
            self.refreshWithPage(self.pageIndex + 1)
        }, position: .Bottom)
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
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var estimatedHeight = CGFloat(44)
        if let threadContent = threads[indexPath.row].content {
            let estimatedTextSize = threadContent.string.boundingRectWithSize(CGSizeMake(CGRectGetWidth(view.frame), CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin, attributes: nil, context: nil).size
            estimatedHeight += estimatedTextSize.height + 80
            estimatedHeight += threads[indexPath.row].thumbnailURL == nil ? 0 : 100
        }
        return estimatedHeight
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
            // Present
            navigationController?.pushViewController(photoBrowser, animated:true)
        }
    }
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser) -> UInt {
        return selectedPhoto == nil ? 0 : 1
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser, photoAtIndex index: UInt) -> MWPhotoProtocol! {
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