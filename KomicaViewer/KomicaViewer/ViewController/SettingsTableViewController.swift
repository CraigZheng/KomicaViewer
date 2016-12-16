//
//  SettingsTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 15/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    private let cellIdentifier = "cellIdentifier"
    private let remoteActionCellIdentifier = "remoteActionCellIdentifier"
    private let selectedIndexPathKey = "selectedIndexPathKey"
    private var lastSectionIndex: Int {
        return numberOfSectionsInTableView(tableView) - 1
    }
    private enum Section: Int {
        case settings, remoteActions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .settings:
            return 0
        case .remoteActions:
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch Section(rawValue: section)! {
        case .settings:
            return UITableViewAutomaticDimension
        case .remoteActions:
            return CGFloat(Configuration.singleton.remoteActions.count * 44) + 20
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .settings:
            // TODO: settings.
            return UITableViewCell()
        case .remoteActions:
            let cell = tableView.dequeueReusableCellWithIdentifier(remoteActionCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = "App Version: " + Configuration.bundleVersion
            return cell
        }

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Remote action section.
        if indexPath.section == .remoteActions,
            let urlString = Configuration.singleton.remoteActions[indexPath.row].values.first,
            let url = NSURL(string: urlString)
        {
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
    }
    
}
