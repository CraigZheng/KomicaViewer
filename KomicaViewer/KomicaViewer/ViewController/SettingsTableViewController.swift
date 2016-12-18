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
            DispatchQueue.main.async {
                if let response = response,
                    !response.products.isEmpty {
                    // Reload tableView with the newly downloaded product.
                    self?.iapProducts.append(contentsOf: response.products)
                    if let product = self?.iapProducts.first {
                        self?.removeAdCell.textLabel?.text = product.localizedTitle
                        self?.removeAdCell.detailTextLabel?.text = product.localizedPrice()
                    }
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - UI elements.
    
    @IBOutlet weak var showImageSwitch: UISwitch! {
        didSet {
            showImageSwitch.setOn(Configuration.singleton.showImage, animated: false)
        }
    }
    
    @IBOutlet weak var removeAdCell: UITableViewCell!
    @IBOutlet weak var restorePurchaseCell: UITableViewCell!
    // MARK: - UI actions.
    
    @IBAction func showImageSwitchAction(_ sender: AnyObject) {
        Configuration.singleton.showImage = showImageSwitch.isOn
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .settings:
            // When IAP product is empty, don't show the removeAdCell and restorePurchaseCell.
            if iapProducts.isEmpty || AdConfiguration.singleton.isAdRemovePurchased, tableView.indexPath(for: removeAdCell) == indexPath || tableView.indexPath(for: restorePurchaseCell) == indexPath {
                return 0
            }
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
        } else {
            if let cell = tableView.cellForRow(at: indexPath) {
                switch cell {
                case removeAdCell:
                    // Initiate purchasing.
                    if let product = self.iapProducts.first {
                        IAPHelper.sharedInstance.purchaseProduct(product.productIdentifier) { [weak self] (purchasedIdentifier, error) in
                            if let purchasedIdentifier = purchasedIdentifier, !purchasedIdentifier.isEmpty {
                                // Inform success.
                                AdConfiguration.singleton.isAdRemovePurchased = true
                                self?.tableView.reloadData()
                            } else if let error = error as? NSError, SKError.Code(rawValue: error.code) == SKError.Code.paymentCancelled {
                                // User cancelled the transaction, no need to display any error.
                            } else {
                                // Generic error.
                                
                            }
                        }
                    }
                    break
                case restorePurchaseCell:
                    break
                default:
                    break
                }
            }
        }
    }
    
}
