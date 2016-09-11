//
//  CustomForumManagerTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 11/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class CustomForumManagerTableViewController: UITableViewController {

    private struct CellIdentifier {
        static let customForum = "customForumCell"
    }
    
    private struct SegueIdentifier {
        static let addForum = "addForum"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Forums.customForumGroup.forums?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.customForum, forIndexPath: indexPath)

        if let forum = Forums.customForumGroup.forums?[indexPath.row] {
            cell.textLabel?.text = forum.name
            if let indexURLString = forum.indexURL,
                let indexURL = NSURL(string: indexURLString)
            {
                cell.detailTextLabel?.text = indexURL.host ?? ""
            } else {
                cell.detailTextLabel?.text = ""
            }
        }
        return cell
    }

}


// MARK: UI actions.
extension CustomForumManagerTableViewController {
    
    @IBAction func editButtonAction(sender: AnyObject) {
        tableView.setEditing(!tableView.editing, animated: true)
    }
    
}
