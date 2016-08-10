//
//  HomeTableViewController.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import SDWebImage

class HomeTableViewController: UITableViewController {
    
    private let listDownloader = KomicaDownloader()
    private var selectedForum: KomicaForum? {
        return Forums.selectedForum
    }
    private var pageIndex = 0
    private var threads = [Thread]()

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
        let thread = threads[indexPath.row]
        cell.textLabel?.text = (thread.ID ?? "") + " by " + (thread.UID ?? "")
        cell.detailTextLabel?.text = thread.content?.string
        if let imageURL = thread.thumbnailURL {
            cell.imageView?.sd_setImageWithURL(imageURL, placeholderImage: nil, completed: { [weak cell](image, error, cacheType, imageURL) in
                guard let strongCell = cell else { return }
                // If its been downloaded from the web, reload this cell.
                if image != nil && cacheType == SDImageCacheType.None {
                    dispatch_async(dispatch_get_main_queue(), {
                        if let indexPaths = tableView.indexPathForCell(strongCell) {
                            tableView.reloadRowsAtIndexPaths([indexPaths], withRowAnimation: .Automatic)
                        }
                    })
                }
                })
        }
        return cell
    }
    
}

// MARK: UIActions.
extension HomeTableViewController {
    
    @IBAction func unwindToHomeSegue(segue: UIStoryboardSegue) {
        // Unwind to home.
    }
    
    @IBAction func tapOnImageView(sender: AnyObject) {
        DLog("\(sender)")
    }
    
}

// MARK: Forum selected notification handler.
extension HomeTableViewController {
    
    func handleForumSelectedNotification(notification: NSNotification) {
        title = selectedForum?.name
        threads.removeAll()
        tableView.reloadData()
        loadThreadsWithPage(0)
    }
    
    func loadThreadsWithPage(page: Int) {
        if let selectedForum = selectedForum {
            listDownloader.downloadListForRequest(KomicaDownloaderRequest(url: selectedForum.listURLForPage(page), parser: selectedForum.parserType, completion: { (success, result) in
                // Process the downloaded threads, and reload the tableView.
                if success, let downloadedThreads = result?.threads {
                    self.threads.appendContentsOf(downloadedThreads)
                }
                self.tableView.reloadData()
            }))
        }
    }
    
}