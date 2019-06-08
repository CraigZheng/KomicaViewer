//
//  ParasitePostTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 12/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class ParasitePostTableViewController: UITableViewController {
    
    @objc var parasitePosts: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parasitePosts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath)
        cell.textLabel?.text = parasitePosts[indexPath.row]
        return cell
    }

}
