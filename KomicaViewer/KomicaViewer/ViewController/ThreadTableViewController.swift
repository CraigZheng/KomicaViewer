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
import MWPhotoBrowser
import SVWebViewController

class ThreadTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol, SVWebViewProtocol {
    
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
    // MARK: SVWebViewProtocol
    var svWebViewURL: NSURL?
    var svWebViewGuardDog: WebViewGuardDog?
    // MARK: private properties.
    private let _guardDog = WebViewGuardDog()
    private let showParasitePostSegue = "showParasitePosts"
    private var photoBrowser: MWPhotoBrowser {
        if _photoBrowser == nil {
            _photoBrowser = MWPhotoBrowser(delegate: self)
            _photoBrowser!.displayNavArrows = true; // Whether to display left and right nav arrows on toolbar (defaults to false)
            _photoBrowser!.displaySelectionButtons = false; // Whether selection buttons are shown on each image (defaults to false)
            _photoBrowser!.zoomPhotosToFill = false; // Images that almost fill the screen will be initially zoomed to fill (defaults to true)
            _photoBrowser!.alwaysShowControls = false; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to false)
            _photoBrowser!.enableGrid = true; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to true)
            _photoBrowser!.startOnGrid = false; // Whether to start on the grid of thumbnails instead of the first photo (defaults to false)
            _photoBrowser!.delayToHideElements = UInt(8);
            _photoBrowser!.enableSwipeToDismiss = false; // dont dismiss
            _photoBrowser!.displayActionButton = true;
            _photoBrowser!.hidesBottomBarWhenPushed = true;
        }
        return _photoBrowser!
    }
    private var _photoBrowser: MWPhotoBrowser?
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
            ProgressHUD.showMessage("Loading completed")
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
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(ThreadTableViewController.refresh),
                                  forControlEvents: UIControlEvents.ValueChanged)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        tableView.registerNib(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
        // Load page.
        refreshWithPage(0)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ThreadTableViewCell.identifier, forIndexPath: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = threads[indexPath.row]
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
extension ThreadTableViewController: MWPhotoBrowserDelegate, UIAlertViewDelegate {
    
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
            // Present
            _photoBrowser = nil
            if let index = imageThreads.indexOf(threads[indexPath.row]) {
                photoBrowser.setCurrentPhotoIndex(UInt(index))
            }
            navigationController?.pushViewController(photoBrowser, animated:true)
        }
    }
    
    @IBAction func openInSafariAction(sender: AnyObject) {
        let openURLAction = UIAlertAction(title: "Open URL", style: .Default) { _ in
            // Set the target URL to the currentURL.
            self.svWebViewGuardDog = self._guardDog
            self.svWebViewURL = self.currentURL
            self.presentSVWebView()
        }
        let reportAction = UIAlertAction(title: "Report Thread", style: .Default) { _ in
            // Set the URL to report URL.
            self.svWebViewGuardDog = nil
            self.svWebViewURL = Configuration.singleton.reportURL
            self.presentSVWebView()
        }

        let alertController = UIAlertController(title: "What would you want to do?", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(openURLAction)
        alertController.addAction(reportAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private var imageThreads: [Thread] {
        return self.threads.filter({ (thread) -> Bool in
            return thread.imageURL != nil
        })
    }
    
    // MARK: MWPhotoBrowserDelegate
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(imageThreads.count)
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        var photo: MWPhoto?
        if let imageURL = imageThreads[Int(index)].imageURL {
            photo = MWPhoto(URL: imageURL)
        }
        return photo ?? MWPhoto()
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, thumbPhotoAtIndex index: UInt) -> MWPhotoProtocol! {
        var thumbnail: MWPhoto?
        if let thumbnailURL = imageThreads[Int(index)].thumbnailURL {
            thumbnail = MWPhoto(URL: thumbnailURL)
        } else if let imageURL = imageThreads[Int(index)].imageURL {
            // Cannot find thumbnail URL for this thread, use full size image instead.
            thumbnail = MWPhoto(URL: imageURL)
        }
        return thumbnail ?? MWPhoto()
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