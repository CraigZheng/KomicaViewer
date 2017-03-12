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
    fileprivate struct TextColour {
        static let standard = UIColor(red: 182/255.0, green: 78/255.0, blue: 4/255.0, alpha: 1.0)
        static let warning = UIColor(red: 237/255.0, green: 8/255.0, blue: 25/255.0, alpha: 1.0)
        static let blocked = UIColor.lightGray
    }
    fileprivate let defaultFont = UIFont.systemFont(ofSize: 17)
    fileprivate var quotedNumbers = [Int]()
    fileprivate var quotedNumberButtons = [UIButton]()
    
    var shouldShowParasitePost = true
    var shouldShowImage = true
    var alertController: UIAlertController?
    var userID: String?
    var links: [URL] {
        var links = [URL]()
        if let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue), let text = textView?.text {
            for match in linkDetector.matches(in: text, options: [], range: NSMakeRange(0, text.characters.count)) {
                if match.resultType == NSTextCheckingResult.CheckingType.link, let url = match.url {
                    links.append(url)
                }
            }
        }
        return links
    }
    var delegate: ThreadTableViewCellRespondable?
    
    @IBOutlet weak var _detailTextLabel: UILabel!
    @IBOutlet weak var _textLabel: UILabel?
    @IBOutlet weak var _imageView: UIImageView!
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint?
    @IBOutlet weak var parasitePostTextLabel: UILabel?
    @IBOutlet weak var parasitePostCountLabel: UILabel?
    @IBOutlet weak var parasitePostViewZeroHeight: NSLayoutConstraint?
    @IBOutlet weak var titleLabel: UILabel!
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if delegate != nil {
            quotedNumberButtons.forEach { (button) in
                button.removeFromSuperview()
            }
            quotedNumberButtons.removeAll()
            quotedNumbers.forEach { (quotedNumber) in
                let quotedString = String(quotedNumber)
                if let textView = textView,
                    let range = (textView.attributedText.string as NSString?)?.range(of: quotedString),
                    (range.location + range.length) <= textView.attributedText.string.characters.count,
                    let rangeRect = textView.rectOfRange(range)
                {
                    let convertedRect = contentView.convert(rangeRect, from: textView)
                    let quotedButton = UIButton(frame: convertedRect)
                    quotedButton.tag = quotedNumber
                    quotedButton.backgroundColor = UIColor.blue.withAlphaComponent(0.05)
                    quotedButton.addTarget(self, action: #selector(ThreadTableViewCell.pressedQuotedNumberButton(button:)), for: .touchUpInside)
                    contentView.addSubview(quotedButton)
                    quotedNumberButtons.append(quotedButton)
                }
            }
        }
    }
    
    func layoutWithThread(_ thread: KomicaEngine.Thread, forTableViewController tableViewController: TableViewControllerBulkUpdateProtocol) {
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
                                                in: NSMakeRange(0, attributedString.length),
                                                options: [], using: { (attributeValue, range, stop) in
                                                    if let attribute = attributeValue as? UIColor {
                                                        mutableAttributedString.addAttribute(NSForegroundColorAttributeName, value: attribute, range: range)
                                                    }
            })
            textView?.attributedText = mutableAttributedString
        }
        // Set title, and hide it when title is empty.
        self.titleLabel.text = thread.title
        if self.titleLabel.text?.isEmpty ?? true {
            NSLayoutConstraint.deactivate(self.titleLabel.constraints)
        } else {
            NSLayoutConstraint.activate(self.titleLabel.constraints)
        }
        if let imageURL = thread.thumbnailURL, let tableViewController = tableViewController as? UITableViewController, shouldShowImage
        {
            imageViewHeight?.constant = 140
            if SDWebImageManager.shared().cachedImageExists(for: imageURL) {
                let cachedImage = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: SDWebImageManager.shared().cacheKey(for: imageURL))
                imageView?.image = cachedImage
            } else {
                imageView?.sd_setImage(with: imageURL, placeholderImage: nil, options: SDWebImageOptions.retryFailed, completed: { [weak self](image, error, cacheType, imageURL) in
                    guard let strongCell = self else { return }
                    // If its been downloaded from the web, reload this 
                    if image != nil && cacheType == SDImageCacheType.none {
                        DispatchQueue.main.async {
                            if let indexPath = tableViewController.tableView.indexPath(for: strongCell) {
                                (tableViewController as! TableViewControllerBulkUpdateProtocol).addPendingIndexPaths(indexPath)
                            }
                        }
                    }
                    })
            }
            // Show imageFormatLabel, and set the text to the pathExtension.
            if let imageURLString = thread.imageURL?.absoluteString {
                imageFormatLabel.isHidden = false
                imageFormatLabel.text = (imageURLString as NSString).pathExtension.uppercased()
            }
        } else {
            imageView?.image = nil
            imageViewHeight?.constant = 0
            imageFormatLabel.isHidden = true
        }
        // When videoLinks is not empty, show mediaLinkLabel.
        mediaLinkLabel.isHidden = !(thread.videoLinks?.isEmpty == false)
        // When video link is not empty, but there's no preview image, then give it a default play button image.
        if !(thread.videoLinks?.isEmpty ?? true), imageView?.image == nil {
            imageView?.image = UIImage(named: "youtube-play-button.png")
            imageViewHeight?.constant = 100
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
            warningLabel?.text = thread.warnings.joined(separator: "\n")
        } else {
            warningLabel?.text = ""
        }
        // Quoted numbers.
        quotedNumbers = thread.quotedNumbers
    }
}

fileprivate extension UITextView {
    
    func rectOfRange(_ range: NSRange) -> CGRect? {
        if let start = self.position(from: beginningOfDocument, offset: range.location),
            let end = self.position(from: start, offset: range.length),
            let textRange = textRange(from: start, to: end)
        {
            return firstRect(for: textRange)
        }
        return nil
    }
    
}
