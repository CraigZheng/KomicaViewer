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
    var forumGroups = Forums.remoteForumGroups ?? Forums.defaultForumsGroups

    private let cellIdentifier = "cellIdentifier"
    private let remoteActionCellIdentifier = "remoteActionCellIdentifier"
    private var lastSectionIndex: Int {
        return numberOfSectionsInTableView(tableView) - 1
    }
    private var shouldShowCustomForums: Bool {
        let should = Forums.customForumGroup.forums?.isEmpty != nil ?? false
        return should
    }
    private func forumsForSection(section: Int) -> [KomicaForum]? {
        let forums = section == 0 ? Forums.customForumGroup.forums : forumGroups[section - 1].forums
        return forums
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
        NSNotificationCenter.defaultCenter().addObserverForName(Forums.forumsUpdatedNotification,
                                                                object: nil,
                                                                queue: NSOperationQueue.mainQueue()) { (_) in
                                                                    // If remote forums is available, reload remote forums.
                                                                    if let remoteForumGroups = Forums.remoteForumGroups where remoteForumGroups.count > 0 {
                                                                        self.forumGroups = remoteForumGroups
                                                                        self.tableView.reloadData()
                                                                        DLog("Remote Forums Updated.")
                                                                    }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // +1 for the remote actions section, +1 for the custom forums section.
        let sections = forumGroups.count + 2
        return sections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Last section is the settings section.
        if section == lastSectionIndex {
            return 1
        }
        return forumsForSection(section)?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && editingStyle == .Delete {
            Forums.customForumGroup.forums?.removeAtIndex(indexPath.row)
            Forums.saveCustomForums()
            tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == lastSectionIndex {
            return CGFloat(Configuration.singleton.remoteActions.count * 44 + 20)
        } else {
            return UITableViewAutomaticDimension
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == lastSectionIndex {
            let cell = tableView.dequeueReusableCellWithIdentifier(remoteActionCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = "App Version: " + Configuration.bundleVersion
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
            // If section == 0 and custom forums not empty, show the customForumGroup.
            let forums = forumsForSection(indexPath.section)
            if let forums = forums where !forums.isEmpty {
                cell.textLabel?.text = forums[indexPath.row].name
                if let indexURLString = forums[indexPath.row].indexURL,
                    let indexURL = NSURL(string: indexURLString)
                {
                    cell.detailTextLabel?.text = indexURL.host ?? ""
                } else {
                    cell.detailTextLabel?.text = ""
                }
            }
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return (Forums.customForumGroup.forums?.isEmpty != nil ?? false) ? "" : "Custom Boards"
        } else if section == lastSectionIndex {
            return "Settings"
        } else if section - 1 < forumGroups.count {
            return forumGroups[section - 1].name
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Remote action section.
        if indexPath.section == lastSectionIndex,
            let urlString = Configuration.singleton.remoteActions[indexPath.row].values.first,
            let url = NSURL(string: urlString)
        {
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
            }
        } else if let forums = forumsForSection(indexPath.section) where indexPath.row < forums.count
        {
            Forums.selectedForum = forums[indexPath.row]
        }
        // Dismiss self.
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
