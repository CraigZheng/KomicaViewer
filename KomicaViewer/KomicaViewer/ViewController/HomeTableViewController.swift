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
import CCBottomRefreshControl
import SVWebViewController
import GoogleMobileAds
import Firebase
import TTTAttributedLabel
import SwiftMessages

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
    @IBOutlet weak var actionBarButton: UIBarButtonItem!
    
    // MARK: UIViewControllerMWPhotoBrowserProtocol
    @objc var photoURLs: [URL]?
    @objc var thumbnailURLs: [URL]?
    var photoIndex: Int?
    
    // MARK: ThreadTableViewControllerProtocol
    @objc var forum: KomicaForum? {
        set {
            // Setter does nothing.
        }
        
        get {
            return Forums.selectedForum
        }
    }
    @objc var threads:[KomicaEngine.Thread] = []
    
    @objc func refreshWithPage(_ page: Int) {
        DLog(" - \(page)")
        loadThreadsWithPage(page)
    }
    
    @objc lazy var postCompletion: KomicaDownloaderHandler? = { (success, page, result) in
        var suffix = "th"
        switch String(page).last! {
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
        self.bottomRefreshControl?.endRefreshing()
    }
    
    // MARK: TableViewControllerBulkUpdateProtocol
    @objc var targetTableView: UITableView {
        return self.tableView
    }
    @objc var bulkUpdateTimer: Timer?
    @objc var pendingIndexPaths: [IndexPath] = [IndexPath]()
    
    fileprivate var currentURL: URL? {
        return forum?.listURLForPage(pageIndex)
    }
    // MARK: SVWebViewProtocol
    @objc var svWebViewURL: URL? {
        set {}
        get {
            return currentURL
        }
    }
    @objc var svWebViewGuardDog: WebViewGuardDog? {
        set {}
        get {
            _guardDog.home = currentURL?.host
            _guardDog.showWarningOnBlock = true
            return _guardDog
        }
    }
    
    fileprivate let _guardDog = WebViewGuardDog()
    fileprivate var bottomRefreshControl: UIRefreshControl?
    fileprivate var pageIndex = 0
    fileprivate let showThreadSegue = "showThread"
    private let showMenuSegue = "showMenu"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(HomeTableViewController.refresh),
                                  for: UIControl.Event.valueChanged)
        bottomRefreshControl = UIRefreshControl()
        bottomRefreshControl?.addTarget(self,
                                       action: #selector(HomeTableViewController.loadMore),
                                       for: .valueChanged)
        // Row heights.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        tableView.register(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Add handler for Forum selected notification.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(HomeTableViewController.handleForumSelectedNotification(_:)),
                                               name: NSNotification.Name(rawValue: Forums.selectionUpdatedNotification),
                                               object: nil)
        // Add handler for blocked user updated notification.
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
        
        if forum == nil {
            performSegue(withIdentifier: showMenuSegue, sender: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if tableView.bottomRefreshControl == nil {
            tableView.bottomRefreshControl = bottomRefreshControl
        }
        if let announcement = Configuration.singleton.pendingAnnouncement, !announcement.isEmpty {
            MessagePopup.showMessage(title: "Announcement",
                                     message: announcement,
                                     layout: .cardView,
                                     theme: .info,
                                     position: .bottom,
                                     buttonTitle: "OK",
                                     buttonActionHandler: { _ in
                                        SwiftMessages.hide()
            })
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = threads[indexPath.row]
            // Home view does not show parasite view.
            cell.shouldShowParasitePost = false
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
            estimatedHeight += estimatedTextSize.height + ((threads[indexPath.row].title?.isEmpty ?? true) ? 50 : 82)
            // If thumbnail image is not nil, include the thumbnail image.
            if let thumbnailURL = threads[indexPath.row].thumbnailURL {
                if SDWebImageManager.shared().cachedImageExists(for: thumbnailURL) {
                    let cachedImage = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: SDWebImageManager.shared().cacheKey(for: thumbnailURL))
                    estimatedHeight += (cachedImage?.size.height)!
                }
            }
        }
        return estimatedHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showThreadSegue, sender: tableView.cellForRow(at: indexPath))
    }
    
}

// MARK: Prepare for segue.
extension HomeTableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectedCell = sender as? UITableViewCell,
            let destinationViewController = segue.destination as? ThreadTableViewController,
            let indexPath = tableView.indexPath(for: selectedCell)
        {
            destinationViewController.forum = forum
            destinationViewController.selectedThread = threads[indexPath.row]
        }
    }
    
}

// MARK: UIActions.
extension HomeTableViewController {
    
    @IBAction func openInSafariAction(_ sender: AnyObject) {
        let openURLAction = UIAlertAction(title: "Open in Browser", style: .default) { _ in
            // Set the target URL to the currentURL.
            self.svWebViewGuardDog = self._guardDog
            self.svWebViewURL = self.currentURL
            self.presentSVWebView()
        }
        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            // Default UIActivityViewController, no customisation other than the supplied URL.
            let activityViewController = UIActivityViewController(activityItems : [self.currentURL as Any], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        alertController.addAction(openURLAction)
        alertController.addAction(shareAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func unwindToHomeSegue(_ segue: UIStoryboardSegue) {
        // Unwind to home.
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
        if let imageURL = threads[index].imageURL ?? threads[index].thumbnailURL {
            photoURLs = [imageURL]
        }
        // Home table view controller has only 1 photo URL.
        photoIndex = 0
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
    
}

// MARK: Refresh controls
extension HomeTableViewController {
    
    @objc func refresh() {
        if let forum = forum {
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "REFRESH FORUM" as NSObject,
                AnalyticsParameterItemID: "\(forum.name ?? "id undefined")" as NSString,
                AnalyticsParameterItemName: "\(forum.name ?? "name undefined")" as NSString])
        }
        refreshWithPage(forum?.startingIndex ?? 0)
    }

    @objc func loadMore() {
        self.refreshWithPage(self.pageIndex + 1)
    }
    
}

// MARK: Forum selected notification handler.
extension HomeTableViewController {
    
    @objc func handleForumSelectedNotification(_ notification: Notification) {
        title = forum?.name
        threads.removeAll()
        tableView.reloadData()
        refreshWithPage(forum?.startingIndex ?? 0)
        // Disable/enable the webview bar button.
        actionBarButton.isEnabled = currentURL != nil
        if let forum = forum {
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "SELECT FORUM" as NSObject,
                AnalyticsParameterItemID: "\(forum.name ?? "id undefined")" as NSString,
                AnalyticsParameterItemName: "\(forum.name ?? "name undefined")" as NSString]
            )
        }
    }
    
}

// MAKR: GADBannerViewDelegate
extension HomeTableViewController: GADBannerViewDelegate {
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        DLog("")
        AdConfiguration.singleton.clickedAd()
    }
    
    @objc func toggleAdBanner(_ show: Bool) {
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
    
    @objc func attemptLoadRequest() {
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

extension HomeTableViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    
}
