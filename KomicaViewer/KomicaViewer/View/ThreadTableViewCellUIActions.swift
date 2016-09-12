//
//  ThreadTableViewCellUIActions.swift
//  KomicaViewer
//
//  Created by Craig on 12/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

extension ThreadTableViewCell {
    
    func longPressAction() {
        DLog("")
        // If there's another alertController, don't do anything.
        if alertController == nil {
            if let userID = userID where BlockedUserManager.sharedManager.isUserIDBlocked(userID ?? "") {
                alertController = UIAlertController(title: "User blocked: \(userID)", message: "Would you like to unblock this user?", preferredStyle: .ActionSheet)
                alertController?.addAction(UIAlertAction(title: "Unblock", style: .Default, handler: { (_) in
                    self.alertController = nil
                    BlockedUserManager.sharedManager.unblockUserID(userID)
                }))
                alertController?.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (_) in
                    self.alertController = nil
                }))
                if let topViewController = UIApplication.topViewController,
                    let alertController = alertController
                {
                    alertController.popoverPresentationController?.sourceView = contentView
                    alertController.popoverPresentationController?.sourceRect = contentView.bounds
                    topViewController.presentViewController(alertController, animated: true, completion: nil)
                }
            } else {
                alertController = UIAlertController(title: "What would you want to do?", message: nil, preferredStyle: .ActionSheet)
                if let alertController = alertController {
                    let copyAction = UIAlertAction(title: "Copy Content", style: .Default) { (_) in
                        if let text = self.textView?.text {
                            UIPasteboard.generalPasteboard().string = text
                            ProgressHUD.showMessage("Content Copied")
                        }
                        // Set alertController to nil, so this cell is ready for another alertController.
                        self.alertController = nil
                    }
                    var blockUserAction: UIAlertAction?
                    if let userID = userID {
                        blockUserAction = UIAlertAction(title: "Block \(userID)", style: .Default, handler: { (_) in
                            self.alertController = nil
                            if !BlockedUserManager.sharedManager.isUserIDBlocked(userID) {
                                BlockedUserManager.sharedManager.blockUserID(userID)
                            }
                        })
                    }
                    let openAction = UIAlertAction(title: "Open in Browser", style: .Default) { _ in
                        self.alertController = nil
                        if !self.links.isEmpty {
                            // Secondary alert controller.
                            let alertController = UIAlertController(title: "Which URL?", message: nil, preferredStyle: .ActionSheet)
                            for link in self.links {
                                let linkAction = UIAlertAction(title: link.absoluteString, style: .Default) { _ in
                                    if UIApplication.sharedApplication().canOpenURL(link) {
                                        UIApplication.sharedApplication().openURL(link)
                                    }
                                }
                                alertController.addAction(linkAction)
                            }
                            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                            alertController.popoverPresentationController?.sourceView = self.contentView
                            alertController.popoverPresentationController?.sourceRect = self.contentView.bounds
                            if let topViewController = UIApplication.topViewController {
                                topViewController.presentViewController(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                    alertController.addAction(copyAction)
                    if let blockUserAction = blockUserAction {
                        alertController.addAction(blockUserAction)
                    }
                    if !links.isEmpty {
                        alertController.addAction(openAction)
                    }
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {_ in self.alertController = nil}))
                    alertController.popoverPresentationController?.sourceView = contentView
                    alertController.popoverPresentationController?.sourceRect = contentView.bounds
                    if let topViewController = UIApplication.topViewController {
                        topViewController.presentViewController(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
    }

}
