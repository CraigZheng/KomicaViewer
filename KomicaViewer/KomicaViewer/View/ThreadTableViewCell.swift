//
//  ThreadTableViewswift
//  KomicaViewer
//
//  Created by Craig Zheng on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import SDWebImage

class ThreadTableViewCell: UITableViewCell {
    static let identifier = "threadCellIdentifier"

    var shouldShowParasitePost = true
    private var alertController: UIAlertController?
    @IBOutlet weak var _detailTextLabel: UILabel!
    @IBOutlet weak var _textLabel: UILabel?
    @IBOutlet weak var _imageView: UIImageView!
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var imageViewZeroHeight: NSLayoutConstraint?
    @IBOutlet weak var parasitePostTextLabel: UILabel?
    @IBOutlet weak var parasitePostCountLabel: UILabel?
    @IBOutlet weak var parasitePostViewZeroHeight: NSLayoutConstraint?
    @IBOutlet weak var dateLabel: UILabel?
    @IBOutlet weak var warningLabel: UILabel?
    
    // MARK: Override to return customisable UI elements.
    
    override var textLabel: UILabel? {
        get { return _textLabel }
        set { _textLabel = newValue}
    }
    
    override var detailTextLabel: UILabel? {
        get { return _detailTextLabel }
        set { _detailTextLabel = newValue }
    }
    
    override var imageView: UIImageView? {
        get { return _imageView }
        set { _imageView = newValue }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ThreadTableViewCell.longPressAction))
        contentView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    // MARK: Private.
    private var links: [NSURL] {
        var links = [NSURL]()
        if let linkDetector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue), let text = textView?.text {
            for match in linkDetector.matchesInString(text, options: [], range: NSMakeRange(0, text.characters.count)) {
                if match.resultType == NSTextCheckingType.Link, let url = match.URL {
                    links.append(url)
                }
            }
        }
        return links
    }
    
    private var userID: String?
    
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
    
    func layoutWithThread(thread: Thread, forTableViewController tableViewController: TableViewControllerBulkUpdateProtocol) {
        var thread = thread
        userID = thread.UID
        if BlockedUserManager.sharedManager.isUserIDBlocked(thread.UID ?? "") {
            thread = Thread()
            thread.content = NSAttributedString(string: "Content Blocked")
        }
        
        var titleText = (thread.ID ?? "")
        if let UID = thread.UID {
            titleText += " " + UID
        }
        textLabel?.text = titleText
        textView?.text = thread.content?.string
        if let imageURL = thread.thumbnailURL, let tableViewController = tableViewController as? UITableViewController
        {
            imageViewZeroHeight?.priority = 1
            if SDWebImageManager.sharedManager().cachedImageExistsForURL(imageURL) {
                let cachedImage = SDWebImageManager.sharedManager().imageCache.imageFromDiskCacheForKey(SDWebImageManager.sharedManager().cacheKeyForURL(imageURL))
                imageView?.image = cachedImage
            } else {
                imageView?.sd_setImageWithURL(imageURL, placeholderImage: nil, completed: { [weak self](image, error, cacheType, imageURL) in
                    guard let strongCell = self else { return }
                    // If its been downloaded from the web, reload this 
                    if image != nil && cacheType == SDImageCacheType.None {
                        dispatch_async(dispatch_get_main_queue(), {
                            if let indexPath = tableViewController.tableView.indexPathForCell(strongCell) {
                                (tableViewController as! TableViewControllerBulkUpdateProtocol).addPendingIndexPaths(indexPath)
                            }
                        })
                    }
                    })
            }
        } else {
            imageView?.image = nil
            imageViewZeroHeight?.priority = 999
        }
        // Parasite post.
        if shouldShowParasitePost, let parasitePosts = thread.pushPost,
            let firstParasitePost = parasitePosts.first
        {
            parasitePostTextLabel?.text = firstParasitePost
            parasitePostCountLabel?.text = parasitePosts.count - 1 > 0 ? "..." : ""
            parasitePostViewZeroHeight?.priority = 1
        } else {
            parasitePostTextLabel?.text = ""
            parasitePostCountLabel?.text = ""
            parasitePostViewZeroHeight?.priority = 999
        }
        dateLabel?.text = thread.postDateString ?? ""
        if !thread.warnings.isEmpty {
            warningLabel?.text = thread.warnings.joinWithSeparator("\n")
        } else {
            warningLabel?.text = ""
        }
    }
}
