//
//  ForumPickerTableViewController.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

class ForumPickerTableViewController: UITableViewController {
    var forums = Forums.remoteForums ?? Forums.defaultForums

    private let cellIdentifier = "cellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserverForName(Forums.forumsUpdatedNotification,
                                                                object: nil,
                                                                queue: NSOperationQueue.mainQueue()) { (_) in
                                                                    // If remote forums is available, reload remote forums.
                                                                    if let remoteForums = Forums.remoteForums where remoteForums.count > 0 {
                                                                        self.forums = remoteForums
                                                                        self.tableView.reloadData()
                                                                        DLog("Remote Forums Updated.")
                                                                    }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forums.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = forums[indexPath.row].name
        cell.detailTextLabel?.text = forums[indexPath.row].header
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let forum = forums[indexPath.row]
        Forums.selectedForum = forum
        // Dismiss self.
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
