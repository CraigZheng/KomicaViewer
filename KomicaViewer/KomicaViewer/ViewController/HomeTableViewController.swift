//
//  HomeTableViewController.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import MWPhotoBrowser
import SDWebImage
import SVPullToRefresh
import SVWebViewController
import GoogleMobileAds

class HomeTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol, SVWebViewProtocol {
    
    @IBOutlet weak var adBannerTableViewHeaderView: UIView!
    @IBOutlet weak var adBannerView: GADBannerView! {
        didSet {
            adBannerView.adUnitID = AdConfiguration.AdMobID.bannerID1
            adBannerView.rootViewController = self
            adBannerView.delegate = self
        }
    }
    @IBOutlet weak var adDescriptionLabel: UILabel!
    
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
    private var selectedPhoto: MWPhoto?
    private var originalContentInset: UIEdgeInsets?
    private var photoBrowser: MWPhotoBrowser {
        let photoBrowser = MWPhotoBrowser(delegate: self)
        photoBrowser.displayNavArrows = true; // Whether to display left and right nav arrows on toolbar (defaults to false)
        photoBrowser.displaySelectionButtons = false; // Whether selection buttons are shown on each image (defaults to false)
        photoBrowser.zoomPhotosToFill = false; // Images that almost fill the screen will be initially zoomed to fill (defaults to true)
        photoBrowser.alwaysShowControls = false; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to false)
        photoBrowser.enableGrid = true; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to true)
        photoBrowser.startOnGrid = false; // Whether to start on the grid of thumbnails instead of the first photo (defaults to false)
        photoBrowser.delayToHideElements = UInt(8);
        photoBrowser.enableSwipeToDismiss = false; // dont dismiss
        photoBrowser.displayActionButton = true;
        photoBrowser.hidesBottomBarWhenPushed = true;
        return photoBrowser
    }
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
            estimatedHeight += estimatedTextSize.height + 80
            estimatedHeight += threads[indexPath.row].thumbnailURL == nil ? 0 : 100
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
extension HomeTableViewController: MWPhotoBrowserDelegate {
    
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
            let indexPath = tableView.indexPathForCell(cell),
            let imageURL = threads[indexPath.row].imageURL
        {
            selectedPhoto = MWPhoto(URL: imageURL)
            // Present
            navigationController?.pushViewController(photoBrowser, animated:true)
        }
    }
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser) -> UInt {
        return selectedPhoto == nil ? 0 : 1
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        return selectedPhoto ?? MWPhoto()
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