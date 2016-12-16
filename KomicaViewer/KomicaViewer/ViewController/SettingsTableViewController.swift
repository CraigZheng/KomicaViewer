//
//  SettingsTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 15/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import StoreKit

class SettingsTableViewController: UITableViewController {

    fileprivate let cellIdentifier = "cellIdentifier"
    fileprivate let remoteActionCellIdentifier = "remoteActionCellIdentifier"
    fileprivate let selectedIndexPathKey = "selectedIndexPathKey"
    fileprivate let iapRemoveAd = "com.craig.KomicaViewer.removeAdvertisement"
    fileprivate var lastSectionIndex: Int {
        return numberOfSections(in: tableView) - 1
    }
    fileprivate var iapProducts: [SKProduct] = []
    fileprivate enum Section: Int {
        case settings, remoteActions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let productIdentifiers: Set<ProductIdentifier> = [iapRemoveAd]
        IAPHelper.sharedInstance.requestProducts(productIdentifiers) { [weak self] (response, error) in
            if let response = response,
                !response.products.isEmpty {
                // Reload tableView with the newly downloaded product.
                self?.iapProducts.append(contentsOf: response.products)
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UI elements.
    
    @IBOutlet weak var showImageSwitch: UISwitch! {
        didSet {
            showImageSwitch.setOn(Configuration.singleton.showImage, animated: false)
        }
    }
    
    // MARK: - UI actions.
    
    @IBAction func showImageSwitchAction(sender: AnyObject) {
        Configuration.singleton.showImage = showImageSwitch.on
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
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
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        case .remoteActions:
            let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            cell.textLabel?.text = "App Version: " + Configuration.bundleVersion
            return cell
        }

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
        }
    }
    
}
