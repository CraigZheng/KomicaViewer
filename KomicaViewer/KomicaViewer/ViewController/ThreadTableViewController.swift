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

class ThreadTableViewController: UITableViewController, ThreadTableViewControllerProtocol, TableViewControllerBulkUpdateProtocol {
    
    var selectedThread: Thread! {
        didSet {
            title = selectedThread.title
        }
    }
    
    private let showParasitePostSegue = "showParasitePosts"
    private var selectedPhoto: MWPhoto?
    private var photoBrowser: MWPhotoBrowser?
    
    // MARK: ThreadTableViewControllerProtocol
    lazy var threads: [Thread] = {
        return [self.selectedThread]
    }()
    
    // MARK: TableViewControllerBulkUpdateProtocol
    var targetTableView: UITableView {
        return self.tableView
    }
    var bulkUpdateTimer: NSTimer?
    var pendingIndexPaths: [NSIndexPath] = [NSIndexPath]()
    
    func refreshWithPage(page: Int) {
        // For each thread ID, there is only 1 page.
        let stringArray = selectedThread.ID!.componentsSeparatedByCharactersInSet(
            NSCharacterSet.decimalDigitCharacterSet().invertedSet)
        if let threadID = Int(stringArray.joinWithSeparator("")) {
            loadResponsesWithThreadID(threadID)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    // MARK: Segue events.
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let parasitePostTableViewController = segue.destinationViewController as? ParasitePostTableViewController,
            let parasitePost = selectedThread.pushPost
        {
            parasitePostTableViewController.parasitePosts = parasitePost
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        var should = true
        if identifier == showParasitePostSegue {
            should = selectedThread.pushPost?.count > 0
        }
        return should
    }

}

// MARK: UIActions.
extension ThreadTableViewController: MWPhotoBrowserDelegate {
    
    @IBAction func tapOnParasitePostView(sender: UIButton) {
        // User tap on parasite post view, show all parasite posts.
        if shouldPerformSegueWithIdentifier(showParasitePostSegue, sender: sender) {
            performSegueWithIdentifier(showParasitePostSegue, sender: sender)
        }
    }
    
    @IBAction func tapOnImageView(sender: AnyObject) {
        if let sender = sender as? UIView,
            let cell = sender.superCell(),
            let indexPath = tableView.indexPathForCell(cell),
            let imageURL = threads[indexPath.row].imageURL
        {
            selectedPhoto = MWPhoto(URL: imageURL)
            photoBrowser = MWPhotoBrowser(delegate: self)
            // Present
            navigationController?.pushViewController(photoBrowser!, animated:true)
        }
    }
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        return selectedPhoto == nil ? 0 : 1
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        return selectedPhoto ?? MWPhoto()
    }
    
}