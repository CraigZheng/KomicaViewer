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
    
    @IBOutlet weak var _detailTextLabel: UILabel!
    @IBOutlet weak var _textLabel: UILabel!
    @IBOutlet weak var _imageView: UIImageView!
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
    
    func layoutWithThread(thread: Thread, forTableViewController tableViewController: TableViewControllerBulkUpdateProtocol) {
        var titleText = (thread.ID ?? "")
        if let UID = thread.UID {
            titleText += " " + UID
        }
        textLabel?.text = titleText
        detailTextLabel?.text = thread.content?.string
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
