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
    private struct TextColour {
        static let standard = UIColor(red: 182/255.0, green: 78/255.0, blue: 4/255.0, alpha: 1.0)
        static let warning = UIColor(red: 237/255.0, green: 8/255.0, blue: 25/255.0, alpha: 1.0)
        static let blocked = UIColor.lightGrayColor()
    }
    private let defaultFont = UIFont.systemFontOfSize(17)
    
    var shouldShowParasitePost = true
    var alertController: UIAlertController?
    var userID: String?
    var links: [NSURL] {
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
    @IBOutlet weak var imageFormatLabel: UILabel!
    @IBOutlet weak var mediaLinkLabel: UILabel!
    
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
        
    func layoutWithThread(thread: Thread, forTableViewController tableViewController: TableViewControllerBulkUpdateProtocol) {
        // Make a copy of the incoming thread.
        var thread = thread
        userID = thread.UID
        if BlockedUserManager.sharedManager.isUserIDBlocked(thread.UID ?? "") {
            thread = Thread()
            thread.UID = userID
            // Set the text colour of attributed string to blocked colour.
            thread.content = NSAttributedString(string: "Content Blocked\nTap and hold to unblock", attributes: [NSForegroundColorAttributeName: TextColour.blocked])
        }
        
        var titleText = (thread.ID ?? "")
        if let UID = thread.UID {
            titleText += " " + UID
        }
        textLabel?.text = titleText
        //
        if let attributedString = thread.content,
            let mutableAttributedString = thread.content?.mutableCopy() as? NSMutableAttributedString {
            // Set the default font and colour.
            mutableAttributedString.addAttributes([NSFontAttributeName: defaultFont, NSForegroundColorAttributeName: TextColour.standard],
                                           range: NSMakeRange(0, mutableAttributedString.length))
            // Add the font colour attributes back to the attributed string.
            attributedString.enumerateAttribute(NSForegroundColorAttributeName,
                                                inRange: NSMakeRange(0, attributedString.length),
                                                options: [], usingBlock: { (attributeValue, range, stop) in
                                                    if let attribute = attributeValue as? UIColor {
                                                        mutableAttributedString.addAttribute(NSForegroundColorAttributeName, value: attribute, range: range)
                                                    }
            })
            textView?.attributedText = mutableAttributedString
        }
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
            // Show imageFormatLabel, and set the text to the pathExtension.
            if let imageURLString = thread.imageURL?.absoluteString {
                imageFormatLabel.hidden = false
                imageFormatLabel.text = (imageURLString as NSString).pathExtension.uppercaseString
            }
        } else {
            imageView?.image = nil
            imageViewZeroHeight?.priority = 999
            imageFormatLabel.hidden = true
        }
        // When videoLinks is not empty, show mediaLinkLabel.
        mediaLinkLabel.hidden = !(thread.videoLinks?.isEmpty == false)
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
