//
//  ForumPickerTableViewController.swift
//  KomicaViewer
//
//  Created by Craig on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

class ForumPickerTableViewController: UITableViewController {
    private enum Host: Int {
        case komica, futaba
    }
    // MARK: - UI elements.
    
    @IBOutlet weak var sourceSegmentedControl: UISegmentedControl!
    
    @objc var forumGroups: [KomicaForumGroup] {
        switch sourceSegmentedControl.selectedSegmentIndex {
        case 0: // Komica source.
            return Forums.remoteForumGroups ?? Forums.defaultForumsGroups
        default:
            return Forums.futabaForumGroup ?? []
        }
    }

    fileprivate let cellIdentifier = "cellIdentifier"
    fileprivate let remoteActionCellIdentifier = "remoteActionCellIdentifier"
    fileprivate let selectedIndexPathKey = "selectedIndexPathKey"

    fileprivate var shouldShowCustomForums: Bool {
        let should = Forums.customForumGroup.forums?.isEmpty != nil ?? false
        return should
    }
    fileprivate func forumsForSection(_ section: Int) -> [KomicaForum]? {
        let forums = section == 0 ? Forums.customForumGroup.forums : forumGroups[section - 1].forums
        return forums
    }
    fileprivate static var scrollOffset: CGPoint?
    private var selectedHost: Host {
        get {
            let selectedIndex = UserDefaults.standard.integer(forKey: "SelectedHost")
            guard let selectedHost = Host(rawValue: selectedIndex) else {
                return .komica
            }
            return selectedHost
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "SelectedHost")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: Notification.Name(rawValue: AdConfiguration.adConfigurationUpdatedNotification),
                                            object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Configuration.updatedNotification),
                                               object: nil,
                                               queue: OperationQueue.main) { [weak self] _ in
                                                self?.tableView.reloadData()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Forums.forumsUpdatedNotification),
                                                                object: nil,
                                                                queue: OperationQueue.main) { [weak self] (_) in
                                                                    // If remote forums is available, reload remote forums.
                                                                    if let remoteForumGroups = Forums.remoteForumGroups, remoteForumGroups.count > 0 {
                                                                        self?.tableView.reloadData()
                                                                        DLog("Remote Forums Updated.")
                                                                    }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        // Select previous segmented control index.
        sourceSegmentedControl.selectedSegmentIndex = selectedHost.rawValue
        
        // If user has previously selected an index, let's roll to the previous position.
        if let scrollOffset = ForumPickerTableViewController.scrollOffset
        {
            tableView.setContentOffset(scrollOffset, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ForumPickerTableViewController.scrollOffset = tableView.contentOffset
    }
    
    // MARK: - UI actions.
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        if let selectedHost = Host(rawValue: sourceSegmentedControl.selectedSegmentIndex) {
            self.selectedHost = selectedHost
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // +1 for the custom forums section.
        let sections = forumGroups.count + 1
        return sections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forumsForSection(section)?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && editingStyle == .delete {
            Forums.customForumGroup.forums?.remove(at: indexPath.row)
            Forums.saveCustomForums()
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        // If section == 0 and custom forums not empty, show the customForumGroup.
        let forums = forumsForSection(indexPath.section)
        if let forums = forums, !forums.isEmpty {
            cell.textLabel?.text = forums[indexPath.row].name
            if let indexURLString = forums[indexPath.row].indexURL,
                let indexURL = URL(string: indexURLString)
            {
                cell.detailTextLabel?.text = indexURL.host ?? ""
            } else {
                cell.detailTextLabel?.text = ""
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return (Forums.customForumGroup.forums?.isEmpty != nil ?? false) ? "" : "Custom Boards"
        } else if section - 1 < forumGroups.count {
            return forumGroups[section - 1].name
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let forums = forumsForSection(indexPath.section), indexPath.row < forums.count {
            Forums.selectedForum = forums[indexPath.row]
        }
        // Dismiss self.
        dismiss(animated: true, completion: nil)
    }
    
}
