//
//  CustomForumManagerTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 11/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class CustomForumManagerTableViewController: UITableViewController {

    fileprivate struct CellIdentifier {
        static let customForum = "customForumCell"
    }
    
    fileprivate struct SegueIdentifier {
        static let addForum = "addForum"
        static let scanQRCode = "scanQRCode"
        static let showForum = "showForum"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
        // Colours.
        self.navigationController?.toolbar.barTintColor = self.navigationController?.navigationBar.barTintColor
        self.navigationController?.toolbar.tintColor = self.navigationController?.navigationBar.tintColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Forums.customForumGroup.forums?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.customForum, for: indexPath)

        if let forum = Forums.customForumGroup.forums?[indexPath.row] {
            cell.textLabel?.text = forum.name
            if let indexURLString = forum.indexURL,
                let indexURL = URL(string: indexURLString)
            {
                cell.detailTextLabel?.text = indexURL.host ?? ""
            } else {
                cell.detailTextLabel?.text = ""
            }
        }
        return cell
    }
    
    // MARK: UITableView delegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Forums.customForumGroup.forums?.remove(at: indexPath.row)
            Forums.saveCustomForums()
            tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.showForum,
            let destinationViewController = segue.destination as? AddForumTableViewController,
            let tableViewCell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: tableViewCell),
            let customForum = Forums.customForumGroup.forums?[indexPath.row]
        {
            destinationViewController.displayType = .readonly
            destinationViewController.newForum = customForum
        }
    }

}


// MARK: UI actions.
extension CustomForumManagerTableViewController {
    
    @IBAction func editButtonAction(_ sender: AnyObject) {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    @IBAction func addButtonAction(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add a board...", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Manually", style: .default, handler: { (_) in
            self.performSegue(withIdentifier: SegueIdentifier.addForum, sender: sender)
        }))
        alertController.addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: { (_) in
            self.performSegue(withIdentifier: SegueIdentifier.scanQRCode, sender: sender)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.barButtonItem = sender
        self .present(alertController, animated: true, completion: nil)
    }
}
