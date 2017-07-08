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
