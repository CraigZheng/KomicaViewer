//
//  ThreadTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import SDWebImage
import SVWebViewController
import GoogleMobileAds
import Firebase
import TTTAttributedLabel
import SwiftMessages

class ThreadTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol, SVWebViewProtocol, UIViewControllerMWPhotoBrowserProtocol {
    
    @IBOutlet weak var adBannerTableViewHeaderView: UIView!
    @IBOutlet weak var adBannerView: GADBannerView! {
        didSet {
            adBannerView.adUnitID = AdConfiguration.AdMobID.bannerID2
            adBannerView.rootViewController = self
            adBannerView.delegate = self
        }
    }
    @IBOutlet weak var adDescriptionLabel: UILabel!
    @IBOutlet weak var bookmarkButtonItem: UIBarButtonItem!
    
    var selectedThread: KomicaEngine.Thread! {
        didSet {
            title = selectedThread.title
        }
    }
    
    // MARK: UIViewControllerMWPhotoBrowserProtocol
    var photoURLs: [URL]?
    var thumbnailURLs: [URL]?
    var photoIndex: Int?
    
    // MARK: SVWebViewProtocol
    var svWebViewURL: URL?
    var svWebViewGuardDog: WebViewGuardDog?
    // MARK: private properties.
    fileprivate var _guardDog: WebViewGuardDog {
        let guardDog = WebViewGuardDog()
        guardDog.showWarningOnBlock = true
        guardDog.home = currentURL?.host
        return guardDog
    }
    
    fileprivate var isBookmarked: Bool {
        guard let forum = forum else { return false }
        let bookmark = Bookmark(forum: forum, thread: selectedThread)
        return BookmarkManager.shared.bookmarks.contains(bookmark)
    }
    
    enum SegueIdentifier: String {
        case parasitePosts
        case popupThread
    }
    
    // Get the threadID from the selectedThread.ID.
    fileprivate var threadID: Int? {
        if let stringArray = selectedThread.ID?.components(
            separatedBy: CharacterSet.decimalDigits.inverted) {
            let threadID = Int(stringArray.joined(separator: ""))
            return threadID
        }
        return 0
    }
    fileprivate var quotedThread: KomicaEngine.Thread?
    fileprivate var currentURL: URL? {
        if let threadID = threadID {
            return forum?.responseURLForThreadID(threadID)
        }
        return nil
    }
    // MARK: ThreadTableViewControllerProtocol
    var forum: KomicaForum?
    lazy var postCompletion: KomicaDownloaderHandler? = {
        [weak self](success, page, result) in
        guard let strongSelf = self else { return }
        if success, let t = result?.threads {
            if page == 0 {
                // If page is 0, reset the threads.
                strongSelf.threads = [strongSelf.selectedThread]
            }
            strongSelf.threads.append(contentsOf: t)
            // Necessary to reload for the data change.
            strongSelf.tableView.reloadData()
        } else {
            ProgressHUD.showMessage("Loading failed")
        }
    }
    lazy var threads: [KomicaEngine.Thread] = {
        return [self.selectedThread]
    }()
    
    // MARK: TableViewControllerBulkUpdateProtocol
    var targetTableView: UITableView {
        return self.tableView
    }
    var bulkUpdateTimer: Timer?
    var pendingIndexPaths: [IndexPath] = [IndexPath]()
    
    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Block user updated notification.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: BlockedUserManager.updatedNotification),
                                                                object: nil,
                                                                queue: OperationQueue.main) { [weak self] (_) in
                                                                    self?.tableView.reloadData()
        }
        // Configuration updated.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Configuration.updatedNotification),
                                                                object: nil,
                                                                queue: OperationQueue.main) { [weak self] (_) in
                                                                    self?.tableView.reloadData()
        }
        // Ad configuration update notification
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AdConfiguration.adConfigurationUpdatedNotification),
                                                                object: nil,
                                                                queue: OperationQueue.main) { [weak self] (_) in
                                                                    self?.attemptLoadRequest()
        }
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(ThreadTableViewController.refresh),
                                  for: UIControlEvents.valueChanged)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        tableView.register(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Load page.
        refreshWithPage(0)
        // Load ad.
        attemptLoadRequest()
        if let forum = forum,
            let forumName = forum.name {
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "SELECT THREAD" as NSObject,
                AnalyticsParameterItemID: "\(forumName) - \(threadID ?? 0)" as NSString,
                AnalyticsParameterItemName: "\(forumName) - \(threadID ?? 0)" as NSString])
        }
        updateBookmarkButton()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = threads[indexPath.row]
            cell.shouldShowImage = Configuration.singleton.showImage
            cell.layoutWithThread(thread, forTableViewController: self)
            cell.textContentLabel?.delegate = self
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        var estimatedHeight = CGFloat(44)
        if let threadContent = threads[indexPath.row].content {
            let estimatedTextSize = threadContent.string.boundingRect(with: CGSize(width: (view.frame).width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: nil, context: nil).size
            estimatedHeight += estimatedTextSize.height + 50
            // If thumbnail image is not nil, include the thumbnail image.
            if let thumbnailURL = threads[indexPath.row].thumbnailURL {
                if SDWebImageManager.shared().cachedImageExists(for: thumbnailURL) {
                    estimatedHeight += 140
                }
            }
        }
        return estimatedHeight
    }
    
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        // Do nothing for now.
    }
    
    // MARK: Segue events.
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier, !segueIdentifier.isEmpty else { return }
        switch SegueIdentifier(rawValue: segueIdentifier)! {
        case .parasitePosts:
            if let parasitePostTableViewController = segue.destination as? ParasitePostTableViewController,
                let superCell = (sender as? UIView)?.superCell(),
                let indexPath = tableView.indexPath(for: superCell),
                let parasitePosts = threads[indexPath.row].pushPost
            {
                parasitePostTableViewController.parasitePosts = parasitePosts
            }
        case .popupThread:
            guard let quotedContentViewController = segue.destination as? QuotedContentTableViewController else { return }
            quotedContentViewController.quotedThread = quotedThread
            quotedContentViewController.popoverPresentationController?.delegate = self;
            quotedContentViewController.popoverPresentationController?.sourceView = view;
            quotedContentViewController.popoverPresentationController?.sourceRect = view.bounds;
            // Quoted thread is now consumed.
            quotedThread = nil
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var should = true
        switch SegueIdentifier(rawValue: identifier)! {
        case .parasitePosts:
            if let superCell = (sender as? UIView)?.superCell(),
                let indexPath = tableView.indexPath(for: superCell),
                let parasitePosts = threads[indexPath.row].pushPost
            {
                should = parasitePosts.count > 0
            }
        case .popupThread:
            should = quotedThread != nil
        }
        return should
    }
    
    @IBAction func tappedBookmark(_ sender: UIBarButtonItem) {
        guard let forum = forum else { return }
        let bookmark = Bookmark(forum: forum, thread: selectedThread)
        if isBookmarked {
            BookmarkManager.shared.remove(bookmark)
        } else {
            BookmarkManager.shared.add(bookmark)
        }
        updateBookmarkButton()
    }
    
    fileprivate func updateBookmarkButton() {
        if isBookmarked {
            bookmarkButtonItem.image = UIImage(named: "filled-star")
        } else {
            bookmarkButtonItem.image = UIImage(named: "empty-star")
        }
    }
}

// MARK: UIActions.
extension ThreadTableViewController: UIAlertViewDelegate {
    
    @IBAction func tapOnParasitePostView(_ sender: UIButton) {
        // User tap on parasite post view, show all parasite posts.
        if shouldPerformSegue(withIdentifier: SegueIdentifier.parasitePosts.rawValue, sender: sender) {
            performSegue(withIdentifier: SegueIdentifier.parasitePosts.rawValue, sender: sender)
        }
    }
    
    @IBAction func tapOnImageView(_ sender: AnyObject) {
        if let sender = sender as? UIView,
            let cell = sender.superCell(),
            let indexPath = tableView.indexPath(for: cell)
        {
            if threads[indexPath.row].videoLinks?.isEmpty == false, let videoLink = threads[indexPath.row].videoLinks?.first
            {
                // When image is available, allow selecting either image or video.
                let openMediaAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if threads[indexPath.row].imageURL != nil {
                    openMediaAlertController.addAction(UIAlertAction(title: "Open Image", style: .default, handler: { (_) in
                        self.openImageWithIndex(indexPath.row)
                    }))
                }
                openMediaAlertController.addAction(UIAlertAction(title: "Video: \(videoLink)", style: .default, handler: { (_) in
                    self.openVideoWithLink(videoLink)
                }))
                openMediaAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                openMediaAlertController.popoverPresentationController?.sourceView = view
                openMediaAlertController.popoverPresentationController?.sourceRect = view.bounds
                present(openMediaAlertController, animated: true, completion: nil)
            } else {
                openImageWithIndex(indexPath.row)
            }
        }
    }
    
    fileprivate func openImageWithIndex(_ index: Int) {
        // Present
        photoURLs = imageThreads.map({ (thread) -> URL? in
            return thread.imageURL ?? thread.thumbnailURL
        }).flatMap({ $0 })
        thumbnailURLs = imageThreads.map({ (thread) -> URL? in
            return thread.thumbnailURL ?? thread.imageURL
        }).flatMap({ $0 })
        if let index = imageThreads.index(of: threads[index]) {
            photoIndex = index
        }
        presentPhotos()
    }
    
    fileprivate func openVideoWithLink(_ link: String) {
        if let videoURL = URL(string: link), UIApplication.shared.canOpenURL(videoURL)
        {
            UIApplication.shared.openURL(videoURL)
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "SELECT REMOTE URL" as NSObject,
                AnalyticsParameterItemID: "\(videoURL.absoluteString)" as NSString,
                AnalyticsParameterItemName: "\(videoURL.absoluteString)" as NSString])
        } else {
            ProgressHUD.showMessage("Cannot open: \(link)")
        }
    }
    
    @IBAction func openInSafariAction(_ sender: AnyObject) {
        let openURLAction = UIAlertAction(title: "Open in Browser", style: .default) { _ in
            // Set the target URL to the currentURL.
            self.svWebViewGuardDog = self._guardDog
            self.svWebViewURL = self.currentURL
            self.presentSVWebView()
        }
        let reportAction = UIAlertAction(title: "Report", style: .default) { _ in
            // Set the URL to report URL.
            self.svWebViewGuardDog = WebViewGuardDog()
            self.svWebViewGuardDog?.home = Configuration.singleton.reportURL?.host
            self.svWebViewGuardDog?.showWarningOnBlock = true
            self.svWebViewURL = Configuration.singleton.reportURL as URL?
            self.presentSVWebView()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        alertController.addAction(openURLAction)
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate var imageThreads: [KomicaEngine.Thread] {
        return self.threads.filter({ (thread) -> Bool in
            return thread.imageURL != nil || thread.thumbnailURL != nil
        })
    }
    
    // UIAlertViewDelegate
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            // Open in Safari.
            if let threadID = threadID,
                let currentPageURL = forum?.responseURLForThreadID(threadID), UIApplication.shared.canOpenURL(currentPageURL)
            {
                UIApplication.shared.openURL(currentPageURL)
            }
        }
    }
}

// MAKR: GADBannerViewDelegate
extension ThreadTableViewController: GADBannerViewDelegate {
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        DLog("")
        AdConfiguration.singleton.clickedAd()
    }
    
    func toggleAdBanner(_ show: Bool) {
        DispatchQueue.main.async {
            if (show) {
                self.adDescriptionLabel.text = AdConfiguration.singleton.adDescription
                self.adBannerView.isHidden = false
                self.adDescriptionLabel.isHidden = false
                self.adDescriptionLabel.setNeedsLayout()
                self.adDescriptionLabel.layoutIfNeeded()
                self.adBannerTableViewHeaderView.frame.size.height = 50
                self.adBannerTableViewHeaderView.frame.size.height += self.adDescriptionLabel.frame.height
            } else {
                self.adDescriptionLabel.text = nil
                self.adBannerView.isHidden = true
                self.adDescriptionLabel.isHidden = true
                self.adBannerTableViewHeaderView.frame.size.height = 0
            }
        }
    }
    
    func attemptLoadRequest() {
        if AdConfiguration.singleton.shouldDisplayAds {
            let request = GADRequest()
            #if DEBUG
                request.testDevices = [kGADSimulatorID, "4fa1b332e0290930b2ae511c65ff8947"]
            #endif
            adBannerView.load(request)
            toggleAdBanner(true)
        } else {
            toggleAdBanner(false)
        }
        tableView.reloadData()
    }
    
}

extension ThreadTableViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        } else if (url.absoluteString.hasPrefix(ThreadTableViewCell.quotedIdentifier)) {
            guard let quotedNumber = url.absoluteString.numericValue() else { return }
            guard let quotedThread = threads.first(where: { return $0.ID?.numericValue() == quotedNumber }) else {
                MessagePopup.showMessage(title: "Cannot find id:\(quotedNumber)",
                                         message: "Id:\(quotedNumber) cannot be found within this thread.",
                                         layout: .CardView,
                                         theme: .error,
                                         position: .top,
                                         buttonTitle: "OK",
                                         buttonActionHandler: { _ in
                                            SwiftMessages.hide()
                })
                return
            }
            self.quotedThread = quotedThread
            performSegue(withIdentifier: SegueIdentifier.popupThread.rawValue, sender: nil)
        }
    }
    
}

extension ThreadTableViewController {
    
    func refresh() {
        refreshWithPage(0)
    }
    
    func refreshWithPage(_ page: Int) {
        // For each thread ID, there is only 1 page.
        if let threadID = threadID {
            loadResponsesWithThreadID(threadID)
        }
    }

}

extension ThreadTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
