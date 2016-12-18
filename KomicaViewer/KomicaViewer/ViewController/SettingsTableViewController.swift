//
//  SettingsTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 15/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import StoreKit
import SwiftMessages

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
    @IBOutlet weak var noAdvertisementCell: UITableViewCell!
    // MARK: - UI actions.
    
    @IBAction func showImageSwitchAction(_ sender: AnyObject) {
        Configuration.singleton.showImage = showImageSwitch.isOn
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .settings:
            // When IAP product is empty or the product is already purchased, don't show the removeAdCell and restorePurchaseCell.
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            switch cell {
            case restorePurchaseCell, removeAdCell:
                return iapProducts.isEmpty || AdConfiguration.singleton.isAdRemovePurchased ? 0 : UITableViewAutomaticDimension
            case noAdvertisementCell:
                return AdConfiguration.singleton.isAdRemovePurchased ? UITableViewAutomaticDimension : 0
            default:
                return UITableViewAutomaticDimension
            }
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
                        showLoading()
                        IAPHelper.sharedInstance.purchaseProduct(product.productIdentifier) { [weak self] (purchasedIdentifier, error) in
                            if let purchasedIdentifier = purchasedIdentifier, !purchasedIdentifier.isEmpty {
                                // Inform success.
                                AdConfiguration.singleton.isAdRemovePurchased = true
                                self?.tableView.reloadData()
                                MessagePopup.showMessage(title: "Payment Made",
                                                         message: "You've acquired this item: \(product.localizedTitle)",
                                                         layout: .CardView,
                                                         theme: .success,
                                                         position: .bottom,
                                                         buttonTitle: "OK",
                                                         buttonActionHandler: { _ in
                                                            SwiftMessages.hide()
                                })
                            } else {
                                self?.handle(error)
                            }
                            self?.hideLoading()
                        }
                    }
                    break
                case restorePurchaseCell:
                    // Restore purchase.
                    if let product = self.iapProducts.first {
                        showLoading()
                        IAPHelper.sharedInstance.restorePurchases({ [weak self] (productIdentifiers, error) in
                            self?.hideLoading()
                            if productIdentifiers.contains(product.productIdentifier) {
                                // Restoration successful.
                                AdConfiguration.singleton.isAdRemovePurchased = true
                                self?.tableView.reloadData()
                                MessagePopup.showMessage(title: "Restoration Successful",
                                                         message: "You've acquired this item: \(product.localizedTitle)",
                                    layout: .CardView,
                                    theme: .success,
                                    position: .bottom,
                                    buttonTitle: "OK",
                                    buttonActionHandler: { _ in
                                        SwiftMessages.hide()
                                })
                            } else if let error = error {
                                self?.handle(error)
                            } else {
                                // Network transaction was successful, but no purchase is recorded.
                                MessagePopup.showMessage(title: "Failed To Restore",
                                                         message: "There is no previous payment made by this account, please verify your account and try again.",
                                                         layout: .CardView,
                                                         theme: .error,
                                                         position: .bottom,
                                                         buttonTitle: "OK",
                                                         buttonActionHandler: { _ in
                                                            SwiftMessages.hide()
                                })
                            }
                        })
                    }
                    break
                default:
                    break
                }
            }
        }
    }
    
    
    private func handle(_ error: Error?) {
        if let error = error as? NSError, let errorCode = SKError.Code(rawValue: error.code) {
            // If user cancels the transaction, no need to display any error.
            var message: String?
            switch errorCode {
            case .paymentCancelled:
                message = nil
            default:
                message = error.localizedFailureReason ?? error.localizedDescription
            }
            if let message = message, !message.isEmpty {
                MessagePopup.showMessage(title: "Failed To Purchase",
                                         message: "Cannot make a payment due to the following reason: \n\(message)",
                    layout: .CardView,
                    theme: .error,
                    position: .bottom,
                    buttonTitle: "OK",
                    buttonActionHandler: { _ in
                        SwiftMessages.hide()
                })
            }
        } else {
            // Generic error.
            MessagePopup.showMessage(title: "Failed To Connect",
                                     message: "The connection to the server seems to be broken, please try again later.",
                                     layout: .CardView,
                                     theme: .error,
                                     position: .bottom,
                                     buttonTitle: "OK",
                                     buttonActionHandler: { _ in
                                        SwiftMessages.hide()
            })
        }
    }
}
