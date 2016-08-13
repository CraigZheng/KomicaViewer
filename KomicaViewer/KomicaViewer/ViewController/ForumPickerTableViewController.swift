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
    private let remoteActionCellIdentifier = "remoteActionCellIdentifier"
    private struct Section {
        static let board = 0
        static let settings = 1
        static let count = 2
    }
    private struct SectionHeader {
        static let board = "Board"
        static let settings = "Settings"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
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
        return Section.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 0: the settings section.
        if section == Section.settings {
            return 1
        }
        return forums.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Section.settings {
            return CGFloat(Configuration.singleton.remoteActions.count * 44 + 20)
        } else {
            return UITableViewAutomaticDimension
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == Section.settings {
            let cell = tableView.dequeueReusableCellWithIdentifier(remoteActionCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = "App Version: " + Configuration.bundleVersion
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = forums[indexPath.row].name
            cell.detailTextLabel?.text = forums[indexPath.row].header
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.board {
            return SectionHeader.board
        } else {
            return SectionHeader.settings
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let forum = forums[indexPath.row]
        Forums.selectedForum = forum
        // Dismiss self.
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
