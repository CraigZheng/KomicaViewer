//
//  ActionTableViewCell.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 13/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class ActionTableViewCell: UITableViewCell {
    @IBOutlet weak var actionTableView: UITableView! {
        didSet {
            actionTableView.delegate = remoteActionDelegate
            actionTableView.dataSource = remoteActionDelegate
        }
    }
    @IBOutlet weak var _textLabel: UILabel!

    private let remoteActionDelegate = RemoteActionTableViewDelegate()
    
    override var textLabel: UILabel? {
        get { return _textLabel }
        set { _textLabel = newValue }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        actionTableView.reloadData()
    }
}

class RemoteActionTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
    let actionCellIdentifier = "actionCellIdentifier"
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = Configuration.singleton.remoteActions.count
        return count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(actionCellIdentifier, forIndexPath: indexPath)
        let dict = Configuration.singleton.remoteActions[indexPath.row]
        cell.textLabel?.text = dict.keys.first
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dict = Configuration.singleton.remoteActions[indexPath.row]
        if let key = dict.keys.first,
            let object = dict[key]
        {
            if let actionURL = NSURL(string: object) where UIApplication.sharedApplication().canOpenURL(actionURL) {
                UIApplication.sharedApplication().openURL(actionURL)
            }
        }
    }
    
}