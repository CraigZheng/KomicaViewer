//
//  ThreadTableViewCellUIActions.swift
//  KomicaViewer
//
//  Created by Craig on 12/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import Firebase

extension ThreadTableViewCell {
    
    @objc func longPressAction() {
        DLog("")
        // If there's another alertController, don't do anything.
        if alertController == nil {
            if let userID = userID, BlockedUserManager.sharedManager.isUserIDBlocked(userID) {
                alertController = UIAlertController(title: "User blocked: \(userID)", message: "Would you like to unblock this user?", preferredStyle: .actionSheet)
                alertController?.addAction(UIAlertAction(title: "Unblock", style: .default, handler: { (_) in
                    self.alertController = nil
                    BlockedUserManager.sharedManager.unblockUserID(userID)
                }))
                alertController?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    self.alertController = nil
                }))
                if let topViewController = UIApplication.topViewController,
                    let alertController = alertController
                {
                    alertController.popoverPresentationController?.sourceView = contentView
                    alertController.popoverPresentationController?.sourceRect = contentView.bounds
                    topViewController.present(alertController, animated: true, completion: nil)
                }
            } else {
                alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if let alertController = alertController {
                    let copyIDAction = UIAlertAction(title: "Copy ID: \(userID ?? "")", style: .default) { (_) in
                        if let text = self.textLabel?.text {
                            UIPasteboard.general.string = text
                            ProgressHUD.showMessage("ID Copied")
                        }
                        // Set alertController to nil, so this cell is ready for another alertController.
                        self.alertController = nil
                    }
                    let copyContentAction = UIAlertAction(title: "Copy Content", style: .default) { (_) in
                        if let text = self.textContentLabel?.text as? String {
                            UIPasteboard.general.string = text
                            ProgressHUD.showMessage("Content Copied")
                        }
                        // Set alertController to nil, so this cell is ready for another alertController.
                        self.alertController = nil
                    }
                    var blockUserAction: UIAlertAction?
                    if let userID = userID {
                        blockUserAction = UIAlertAction(title: "Block \(userID)", style: .default, handler: { (_) in
                            self.alertController = nil
                            if !BlockedUserManager.sharedManager.isUserIDBlocked(userID) {
                                BlockedUserManager.sharedManager.blockUserID(userID)
                            }
                        })
                    }
                    let openAction = UIAlertAction(title: "Open Links", style: .default) { _ in
                        self.alertController = nil
                        if !self.links.isEmpty {
                            // Secondary alert controller.
                            let alertController = UIAlertController(title: "Which Link?", message: nil, preferredStyle: .actionSheet)
                            for link in self.links {
                                let linkAction = UIAlertAction(title: link.absoluteString, style: .default) { _ in
                                    if UIApplication.shared.canOpenURL(link as URL) {
                                        UIApplication.shared.openURL(link as URL)
                                        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                                            AnalyticsParameterContentType: "SELECT REMOTE URL" as NSObject,
                                            AnalyticsParameterItemID: "\(link.absoluteString)" as NSString,
                                            AnalyticsParameterItemName: "\(link.absoluteString)" as NSString])
                                    }
                                }
                                alertController.addAction(linkAction)
                            }
                            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            alertController.popoverPresentationController?.sourceView = self.contentView
                            alertController.popoverPresentationController?.sourceRect = self.contentView.bounds
                            if let topViewController = UIApplication.topViewController {
                                topViewController.present(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                    alertController.addAction(copyIDAction)
                    alertController.addAction(copyContentAction)
                    if let blockUserAction = blockUserAction {
                        alertController.addAction(blockUserAction)
                    }
                    if !links.isEmpty {
                        alertController.addAction(openAction)
                    }
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in self.alertController = nil}))
                    alertController.popoverPresentationController?.sourceView = contentView
                    alertController.popoverPresentationController?.sourceRect = contentView.bounds
                    if let topViewController = UIApplication.topViewController {
                        topViewController.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
