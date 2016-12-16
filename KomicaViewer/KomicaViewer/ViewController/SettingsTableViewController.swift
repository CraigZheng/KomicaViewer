//
//  SettingsTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 15/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    fileprivate let cellIdentifier = "cellIdentifier"
    fileprivate let remoteActionCellIdentifier = "remoteActionCellIdentifier"
    fileprivate let selectedIndexPathKey = "selectedIndexPathKey"
    fileprivate var lastSectionIndex: Int {
        return numberOfSections(in: tableView) - 1
    }
    fileprivate enum Section: Int {
        case settings, remoteActions
    }
    
    // MARK: - UI elements.
    
    @IBOutlet weak var showImageSwitch: UISwitch! {
        didSet {
            showImageSwitch.setOn(Configuration.singleton.showImage, animated: false)
        }
    }
    
    // MARK: - UI actions.
    
    @IBAction func showImageSwitchAction(_ sender: AnyObject) {
        Configuration.singleton.showImage = showImageSwitch.isOn
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .settings:
            return UITableViewAutomaticDimension
        case .remoteActions:
            return CGFloat(Configuration.singleton.remoteActions.count * 44) + 20
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .settings:
            // TODO: settings.
            return super.tableView(tableView, cellForRowAt: indexPath)
        case .remoteActions:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            cell.textLabel?.text = "App Version: " + Configuration.bundleVersion
            return cell
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Remote action section.
        if indexPath.section == lastSectionIndex,
            let urlString = Configuration.singleton.remoteActions[indexPath.row].values.first,
            let url = URL(string: urlString)
        {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
}
