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
    
    var selectedThread: Thread! {
        didSet {
            title = selectedThread.title
        }
    }
    
    private var currentURL: NSURL? {
        if let threadID = threadID {
            return forum?.responseURLForThreadID(threadID)
        }
        return nil
    }
    
    // MARK: UIViewControllerMWPhotoBrowserProtocol
    var photoURLs: [NSURL]?
    var thumbnailURLs: [NSURL]?
    var photoIndex: Int?
    
    // MARK: SVWebViewProtocol
    var svWebViewURL: NSURL?
    var svWebViewGuardDog: WebViewGuardDog?
    // MARK: private properties.
    private let _guardDog = WebViewGuardDog()
    private let showParasitePostSegue = "showParasitePosts"
    // Get the threadID from the selectedThread.ID.
    private var threadID: Int? {
        if let stringArray = selectedThread.ID?.componentsSeparatedByCharactersInSet(
            NSCharacterSet.decimalDigitCharacterSet().invertedSet) {
            let threadID = Int(stringArray.joinWithSeparator(""))
            return threadID
        }
        return 0
    }
    // MARK: ThreadTableViewControllerProtocol
    lazy var postCompletion: KomicaDownloaderHandler? = {
        [weak self](success, page, result) in
        guard let strongSelf = self else { return }
        if success, let t = result?.threads {
            if page == 0 {
                // If page is 0, reset the threads.
                strongSelf.threads = [strongSelf.selectedThread]
            }
            strongSelf.threads.appendContentsOf(t)
            // Necessary to reload for the data change.
            strongSelf.tableView.reloadData()
        } else {
            ProgressHUD.showMessage("Loading failed")
        }
    }
    lazy var threads: [Thread] = {
        return [self.selectedThread]
    }()
    func refresh() {
        refreshWithPage(0)
    }
    func refreshWithPage(page: Int) {
        // For each thread ID, there is only 1 page.
        if let threadID = threadID {
            loadResponsesWithThreadID(threadID)
        }
    }

    // MARK: TableViewControllerBulkUpdateProtocol
    var targetTableView: UITableView {
        return self.tableView
    }
    var bulkUpdateTimer: NSTimer?
    var pendingIndexPaths: [NSIndexPath] = [NSIndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Block user updated notification.
        NSNotificationCenter.defaultCenter().addObserverForName(BlockedUserManager.updatedNotification,
                                                                object: nil,
                                                                queue: NSOperationQueue.mainQueue()) { (_) in
                                                                    self.tableView.reloadData()
        }
        // Ad configuration update notification
        NSNotificationCenter.defaultCenter().addObserverForName(AdConfiguration.adConfigurationUpdatedNotification,
                                                                object: nil,
                                                                queue: NSOperationQueue.mainQueue()) { (_) in
                                                                    self.attemptLoadRequest()
        }
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(ThreadTableViewController.refresh),
                                  forControlEvents: UIControlEvents.ValueChanged)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        tableView.registerNib(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Load page.
        refreshWithPage(0)
        // Load ad.
        attemptLoadRequest()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ThreadTableViewCell.identifier, forIndexPath: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = threads[indexPath.row]
            cell.shouldShowImage = Configuration.singleton.showImage
            cell.layoutWithThread(thread, forTableViewController: self)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var estimatedHeight = CGFloat(44)
        if let threadContent = threads[indexPath.row].content {
            let estimatedTextSize = threadContent.string.boundingRectWithSize(CGSizeMake(CGRectGetWidth(view.frame), CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin, attributes: nil, context: nil).size
            estimatedHeight += estimatedTextSize.height + 50
            // If thumbnail image is not nil, include the thumbnail image.
            if let thumbnailURL = threads[indexPath.row].thumbnailURL {
                if SDWebImageManager.sharedManager().cachedImageExistsForURL(thumbnailURL) {
                    let cachedImage = SDWebImageManager.sharedManager().imageCache.imageFromDiskCacheForKey(SDWebImageManager.sharedManager().cacheKeyForURL(thumbnailURL))
                    estimatedHeight += cachedImage.size.height
                }
            }
        }
        return estimatedHeight
    }
    
    override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        // Do nothing for now.
    }
    
    // MARK: Segue events.
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let parasitePostTableViewController = segue.destinationViewController as? ParasitePostTableViewController,
            let superCell = (sender as? UIView)?.superCell(),
            let indexPath = tableView.indexPathForCell(superCell),
            let parasitePosts = threads[indexPath.row].pushPost
        {
            parasitePostTableViewController.parasitePosts = parasitePosts
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        var should = true
        if identifier == showParasitePostSegue,
            let superCell = (sender as? UIView)?.superCell(),
            let indexPath = tableView.indexPathForCell(superCell),
            let parasitePosts = threads[indexPath.row].pushPost
        {
            should = parasitePosts.count > 0
        }
        return should
    }

}

// MARK: UIActions.
extension ThreadTableViewController: UIAlertViewDelegate {
    
    @IBAction func tapOnParasitePostView(sender: UIButton) {
        // User tap on parasite post view, show all parasite posts.
        if shouldPerformSegueWithIdentifier(showParasitePostSegue, sender: sender) {
            performSegueWithIdentifier(showParasitePostSegue, sender: sender)
        }
    }
    
    @IBAction func tapOnImageView(sender: AnyObject) {
        if let sender = sender as? UIView,
            let cell = sender.superCell(),
            let indexPath = tableView.indexPathForCell(cell)
        {
            if threads[indexPath.row].videoLinks?.isEmpty == false, let videoLink = threads[indexPath.row].videoLinks?.first
            {
                // When image is available, allow selecting either image or video.
                let openMediaAlertController = UIAlertController(title: "What would you want to do?", message: nil, preferredStyle: .ActionSheet)
                if threads[indexPath.row].imageURL != nil {
                    openMediaAlertController.addAction(UIAlertAction(title: "Open Image", style: .Default, handler: { (_) in
                        self.openImageWithIndex(indexPath.row)
                    }))
                }
                openMediaAlertController.addAction(UIAlertAction(title: "Video: \(videoLink)", style: .Default, handler: { (_) in
                    self.openVideoWithLink(videoLink)
                }))
                openMediaAlertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                openMediaAlertController.popoverPresentationController?.sourceView = view
                openMediaAlertController.popoverPresentationController?.sourceRect = view.bounds
                presentViewController(openMediaAlertController, animated: true, completion: nil)
            } else {
                openImageWithIndex(indexPath.row)
            }
        }
    }
    
    private func openImageWithIndex(index: Int) {
        // Present
        photoURLs = imageThreads.map({ (thread) -> NSURL in
            return thread.imageURL ?? NSURL()
        })
        thumbnailURLs = imageThreads.map({ (thread) -> NSURL in
            return thread.thumbnailURL ?? NSURL()
        })
        if let index = imageThreads.indexOf(threads[index]) {
            photoIndex = index
        }
        presentPhotos()
    }
    
    private func openVideoWithLink(link: String) {
        if let videoURL = NSURL(string: link) where UIApplication.sharedApplication().canOpenURL(videoURL)
        {
            UIApplication.sharedApplication().openURL(videoURL)
        } else {
            ProgressHUD.showMessage("Cannot open: \(link)")
        }
    }
    
    @IBAction func openInSafariAction(sender: AnyObject) {
        let openURLAction = UIAlertAction(title: "Open in Browser", style: .Default) { _ in
            // Set the target URL to the currentURL.
            self.svWebViewGuardDog = self._guardDog
            self.svWebViewURL = self.currentURL
            self.presentSVWebView()
        }
        let reportAction = UIAlertAction(title: "Report", style: .Default) { _ in
            // Set the URL to report URL.
            self.svWebViewGuardDog = WebViewGuardDog()
            self.svWebViewGuardDog?.home = Configuration.singleton.reportURL?.host
            self.svWebViewGuardDog?.showWarningOnBlock = true
            self.svWebViewURL = Configuration.singleton.reportURL
            self.presentSVWebView()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

        let alertController = UIAlertController(title: "What would you want to do?", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(openURLAction)
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private var imageThreads: [Thread] {
        return self.threads.filter({ (thread) -> Bool in
            return thread.imageURL != nil
        })
    }
    
    // UIAlertViewDelegate
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            // Open in Safari.
            if let threadID = threadID,
                let currentPageURL = forum?.responseURLForThreadID(threadID) where UIApplication.sharedApplication().canOpenURL(currentPageURL)
            {
                UIApplication.sharedApplication().openURL(currentPageURL)
            }
        }
    }
}

// MAKR: GADBannerViewDelegate
extension ThreadTableViewController: GADBannerViewDelegate {
    
    func adViewWillLeaveApplication(bannerView: GADBannerView!) {
        DLog("")
        AdConfiguration.singleton.clickedAd()
    }
    
    func toggleAdBanner(show: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            if (show) {
                self.adDescriptionLabel.text = AdConfiguration.singleton.adDescription
                self.adBannerView.hidden = false
                self.adDescriptionLabel.hidden = false
                self.adDescriptionLabel.setNeedsLayout()
                self.adDescriptionLabel.layoutIfNeeded()
                self.adBannerTableViewHeaderView.frame.size.height = 50
                self.adBannerTableViewHeaderView.frame.size.height += CGRectGetHeight(self.adDescriptionLabel.frame)
            } else {
                self.adDescriptionLabel.text = nil
                self.adBannerView.hidden = true
                self.adDescriptionLabel.hidden = true
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
            adBannerView.loadRequest(request)
            toggleAdBanner(true)
        } else {
            toggleAdBanner(false)
        }
        tableView.reloadData()
    }
    
}
