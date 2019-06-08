//
//  ActionTableViewCell.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 13/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import Firebase

class ActionTableViewCell: UITableViewCell {
    @IBOutlet weak var actionTableView: UITableView! {
        didSet {
            actionTableView.delegate = remoteActionDelegate
            actionTableView.dataSource = remoteActionDelegate
        }
    }
    @IBOutlet weak var _textLabel: UILabel!

    fileprivate let remoteActionDelegate = RemoteActionTableViewDelegate()
    
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
    @objc let actionCellIdentifier = "actionCellIdentifier"
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = Configuration.singleton.remoteActions.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: actionCellIdentifier, for: indexPath)
        let dict = Configuration.singleton.remoteActions[indexPath.row]
        cell.textLabel?.text = dict.keys.first
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dict = Configuration.singleton.remoteActions[indexPath.row]
        if let key = dict.keys.first,
            let object = dict[key]
        {
            if let actionURL = URL(string: object), UIApplication.shared.canOpenURL(actionURL) {
                UIApplication.shared.openURL(actionURL)
                Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                    AnalyticsParameterContentType: "SELECT REMOTE ACTION" as NSObject,
                    AnalyticsParameterItemID: "\(key)" as NSString,
                    AnalyticsParameterItemName: "\(key) - \(object)" as NSString])
            }
        }
    }
    
}
