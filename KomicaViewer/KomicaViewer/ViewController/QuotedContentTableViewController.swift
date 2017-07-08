//
//  QuotedContentTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 8/7/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

class QuotedContentTableViewController: UITableViewController {
    
    var quotedThread: KomicaEngine.Thread!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.register(UINib(nibName: "ThreadTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: ThreadTableViewCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Layout early to set the frame.
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        preferredContentSize = tableView.contentSize
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath)
        if let threadTableViewCell = cell as? ThreadTableViewCell {
            threadTableViewCell.shouldShowImage = Configuration.singleton.showImage
            threadTableViewCell.layoutWithThread(quotedThread, forTableViewController: nil)
        }
        return cell
    }
    
}
