//
//  BookmarkTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 14/7/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

class BookmarkTableViewController: UITableViewController {
    
    let manager = BookmarkManager.shared
    
    private enum Segue: String {
        case showThread
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        tableView.register(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: ThreadTableViewCell.identifier)
    }
    
    @IBAction func editAction(_ sender: Any) {
        tableView.setEditing(tableView.isEditing, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.bookmarks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThreadTableViewCell.identifier, for: indexPath)
        if let cell = cell as? ThreadTableViewCell {
            let thread = manager.bookmarks[indexPath.row].thread
            // Home view does not show parasite view.
            cell.shouldShowParasitePost = false
            cell.shouldShowImage = Configuration.singleton.showImage
            cell.layoutWithThread(thread, forTableViewController: nil)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Segue.showThread.rawValue, sender: tableView.cellForRow(at: indexPath))
    }
}

// MARK: Prepare for segue.
extension BookmarkTableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectedCell = sender as? UITableViewCell,
            let destinationViewController = segue.destination as? ThreadTableViewController,
            let indexPath = tableView.indexPath(for: selectedCell)
        {
            destinationViewController.selectedThread = manager.bookmarks[indexPath.row].thread
        }
    }
    
}
