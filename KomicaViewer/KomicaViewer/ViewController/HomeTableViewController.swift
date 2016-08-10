//
//  HomeTableViewController.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

class HomeTableViewController: UITableViewController {
    
    private let listDownloader = KomicaDownloader()
    private var selectedForum: KomicaForum? {
        return Forums.selectedForum
    }
    private var pageIndex = 0
    private var threads = [Thread]()

    override func viewDidLoad() {
        super.viewDidLoad()
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
    
}

// MARK: UIActions.
extension HomeTableViewController {
    
    @IBAction func unwindToHomeSegue(segue: UIStoryboardSegue) {
        // Unwind to home.
    }
    
}

// MARK: Forum selected notification handler.
extension HomeTableViewController {
    
    func handleForumSelectedNotification(notification: NSNotification) {
        title = selectedForum?.name
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