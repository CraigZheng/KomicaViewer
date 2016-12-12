//
//  HomeTableViewController.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import SDWebImage
import SVPullToRefresh
import SVWebViewController
import GoogleMobileAds

class HomeTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol, SVWebViewProtocol, UIViewControllerMWPhotoBrowserProtocol {
    
    @IBOutlet weak var adBannerTableViewHeaderView: UIView!
    @IBOutlet weak var adBannerView: GADBannerView! {
        didSet {
            adBannerView.adUnitID = AdConfiguration.AdMobID.bannerID1
            adBannerView.rootViewController = self
            adBannerView.delegate = self
        }
    }
    @IBOutlet weak var adDescriptionLabel: UILabel!
    
    // MARK: UIViewControllerMWPhotoBrowserProtocol
    var photoURLs: [NSURL]?
    var thumbnailURLs: [NSURL]?
    var photoIndex: Int?
    
    // MARK: ThreadTableViewControllerProtocol
    var threads = [Thread]()
    func refresh() {
        refreshWithPage(forum?.startingIndex ?? 0)
    }
    func refreshWithPage(page: Int) {
        DLog(" - \(page)")
        loadThreadsWithPage(page)
    }
    lazy var postCompletion: KomicaDownloaderHandler? = { (success, page, result) in
        var suffix = "th"
        switch String(page).characters.last! {
        case Character("0"): suffix = "st"
        case Character("1"): suffix = "nd"
        case Character("2"): suffix = "rd"
        default: suffix = "th"
        }
        if success {
            // Update the current page.
            self.pageIndex = page
            ProgressHUD.showMessage("\(page + 1 - (self.forum?.startingIndex ?? 0))\(suffix) page loaded.")
        } else {
            if Forums.selectedForum == nil {
                ProgressHUD.showMessage("Please select a board")
            } else {
                ProgressHUD.showMessage("\(page + 1 - (self.forum?.startingIndex ?? 0))\(suffix) page failed to load.")
            }
        }
        // If the originalContentInset is nil, record it, otherwise apply it to the tableView.
        // This is due to a bug that is introduced by SVPullToRefresh library. In order to fix this bug, I need to manually adjust the content inset.
        if let originalContentInset = self.originalContentInset {
            self.tableView.contentInset = originalContentInset
        } else {
            self.originalContentInset = self.tableView.contentInset
        }
    }
    
    // MARK: TableViewControllerBulkUpdateProtocol
    var targetTableView: UITableView {
        return self.tableView
    }
    var bulkUpdateTimer: NSTimer?
    var pendingIndexPaths: [NSIndexPath] = [NSIndexPath]()
    
    private var currentURL: NSURL? {
        return forum?.listURLForPage(pageIndex)
    }
    // MARK: SVWebViewProtocol
    var svWebViewURL: NSURL? {
        set {}
        get {
            return currentURL
        }
    }
    var svWebViewGuardDog: WebViewGuardDog? {
        set {}
        get {
            _guardDog.home = currentURL?.host
            _guardDog.showWarningOnBlock = true
            return _guardDog
        }
    }
    
    private let _guardDog = WebViewGuardDog()
    private var originalContentInset: UIEdgeInsets?
    private var pageIndex = 0
    private let showThreadSegue = "showThread"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(HomeTableViewController.refresh),
                                  forControlEvents: UIControlEvents.ValueChanged)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        tableView.registerNib(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Add handler for Forum selected notification.
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(HomeTableViewController.handleForumSelectedNotification(_:)),
                                                         name: Forums.selectionUpdatedNotification,
                                                         object: nil)
        // Add handler for blocked user updated notification.
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
        tableView.addPullToRefreshWithActionHandler({
            self.refreshWithPage(self.pageIndex + 1)
        }, position: .Bottom)
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ThreadTableViewCell.identifier, forIndexPath: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = threads[indexPath.row]
            // Home view does not show parasite view.
            cell.shouldShowParasitePost = false
            cell.layoutWithThread(thread, forTableViewController: self)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var estimatedHeight = CGFloat(44)
        if let threadContent = threads[indexPath.row].content {
            let estimatedTextSize = threadContent.string.boundingRectWithSize(CGSizeMake(CGRectGetWidth(view.frame), CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin, attributes: nil, context: nil).size
            estimatedHeight += estimatedTextSize.height + ((threads[indexPath.row].title?.isEmpty ?? true) ? 50 : 82)
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(showThreadSegue, sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
}

// MARK: Prepare for segue.
extension HomeTableViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let selectedCell = sender as? UITableViewCell,
            let destinationViewController = segue.destinationViewController as? ThreadTableViewController,
            let indexPath = tableView.indexPathForCell(selectedCell)
        {
            destinationViewController.selectedThread = threads[indexPath.row]
        }
    }
    
}

// MARK: UIActions.
extension HomeTableViewController {
    
    @IBAction func openInSafariAction(sender: AnyObject) {
        // Open in browser.
        presentSVWebView()
    }

    @IBAction func unwindToHomeSegue(segue: UIStoryboardSegue) {
        // Unwind to home.
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
        photoURLs = [threads[index].imageURL ?? NSURL()]
        // Home table view controller has only 1 photo URL.
        photoIndex = 0
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
    
}

// MARK: Forum selected notification handler.
extension HomeTableViewController {
    
    func handleForumSelectedNotification(notification: NSNotification) {
        title = forum?.name
        threads.removeAll()
        tableView.reloadData()
        refreshWithPage(forum?.startingIndex ?? 0)
    }
    
}

// MAKR: GADBannerViewDelegate
extension HomeTableViewController: GADBannerViewDelegate {
    
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
