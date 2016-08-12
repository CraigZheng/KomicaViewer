//
//  ParasitePostTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 12/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class ParasitePostTableViewController: UITableViewController {
    
    var parasitePosts: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parasitePosts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier", forIndexPath: indexPath)
        cell.textLabel?.text = parasitePosts[indexPath.row]
        return cell
    }

}
