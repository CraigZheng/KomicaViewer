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
        static let scanQRCode = "scanQRCode"
        static let showForum = "showForum"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
        // Colours.
        self.navigationController?.toolbar.barTintColor = self.navigationController?.navigationBar.barTintColor
        self.navigationController?.toolbar.tintColor = self.navigationController?.navigationBar.tintColor
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
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
    
    // MARK: UITableView delegate
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            Forums.customForumGroup.forums?.removeAtIndex(indexPath.row)
            Forums.saveCustomForums()
            tableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.showForum,
            let destinationViewController = segue.destinationViewController as? AddForumTableViewController,
            let tableViewCell = sender as? UITableViewCell,
            let indexPath = tableView.indexPathForCell(tableViewCell),
            let customForum = Forums.customForumGroup.forums?[indexPath.row]
        {
            destinationViewController.displayType = .readonly
            destinationViewController.newForum = customForum
        }
    }

}


// MARK: UI actions.
extension CustomForumManagerTableViewController {
    
    @IBAction func editButtonAction(sender: AnyObject) {
        tableView.setEditing(!tableView.editing, animated: true)
    }
    
    @IBAction func addButtonAction(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add a board...", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Manually", style: .Default, handler: { (_) in
            self.performSegueWithIdentifier(SegueIdentifier.addForum, sender: sender)
        }))
        alertController.addAction(UIAlertAction(title: "Scan QR Code", style: .Default, handler: { (_) in
            self.performSegueWithIdentifier(SegueIdentifier.scanQRCode, sender: sender)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.barButtonItem = sender
        self .presentViewController(alertController, animated: true, completion: nil)
    }
}
