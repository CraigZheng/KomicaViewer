//
//  ThreadTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import SDWebImage
import MWPhotoBrowser

class ThreadTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol {
    
    var selectedThread: Thread! {
        didSet {
            title = selectedThread.title
        }
    }
    
    private let showParasitePostSegue = "showParasitePosts"
    private var selectedPhoto: MWPhoto?
    private var photoBrowser: MWPhotoBrowser {
        let photoBrowser = MWPhotoBrowser(delegate: self)
        photoBrowser.zoomPhotosToFill = true
        return photoBrowser
    }
    
    // MARK: ThreadTableViewControllerProtocol
    var completion: KomicaDownloaderHandler? {
        return { (success, page, result) in
            if success, let t = result?.threads {
                if page == 0 {
                    // If page is 0, reset the threads.
                    self.threads = [self.selectedThread]
                }
                self.threads.appendContentsOf(t)
            }
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    lazy var threads: [Thread] = {
        return [self.selectedThread]
    }()
    func refresh() {
        refreshWithPage(0)
    }
    func refreshWithPage(page: Int) {
        // For each thread ID, there is only 1 page.
        let stringArray = selectedThread.ID!.componentsSeparatedByCharactersInSet(
            NSCharacterSet.decimalDigitCharacterSet().invertedSet)
        if let threadID = Int(stringArray.joinWithSeparator("")) {
            loadResponsesWithThreadID(threadID)
        }
    }

    // MARK: TableViewControllerBulkUpdateProtocol
    var targetTableView: UITableView {
        return self.tableView
    }
    var bulkUpdateTimer: NSTimer?
    var pendingIndexPaths: [NSIndexPath] = [NSIndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(ThreadTableViewController.refresh),
                                  forControlEvents: UIControlEvents.ValueChanged)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        tableView.registerNib(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Load page.
        refreshWithPage(0)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ThreadTableViewCell.identifier, forIndexPath: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = threads[indexPath.row]
            cell.layoutWithThread(thread, forTableViewController: self)
        }
        return cell
    }
    
    // MARK: Segue events.
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let parasitePostTableViewController = segue.destinationViewController as? ParasitePostTableViewController,
            let superCell = (sender as? UIView)?.superCell(),
            let indexPath = tableView.indexPathForCell(superCell),
            let parasitePosts = threads[indexPath.row].pushPost
        {
            parasitePostTableViewController.parasitePosts = parasitePosts
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        var should = true
        if identifier == showParasitePostSegue,
            let superCell = (sender as? UIView)?.superCell(),
            let indexPath = tableView.indexPathForCell(superCell),
            let parasitePosts = threads[indexPath.row].pushPost
        {
            should = parasitePosts.count > 0
        }
        return should
    }

}

// MARK: UIActions.
extension ThreadTableViewController: MWPhotoBrowserDelegate {
    
    @IBAction func tapOnParasitePostView(sender: UIButton) {
        // User tap on parasite post view, show all parasite posts.
        if shouldPerformSegueWithIdentifier(showParasitePostSegue, sender: sender) {
            performSegueWithIdentifier(showParasitePostSegue, sender: sender)
        }
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
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        return selectedPhoto == nil ? 0 : 1
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        return selectedPhoto ?? MWPhoto()
    }
    
}