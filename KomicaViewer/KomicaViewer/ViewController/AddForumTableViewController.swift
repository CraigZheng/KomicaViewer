//
//  AddForumTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import DTCoreText

enum ForumField: String {
    case name = "Name"
    case indexURL = "Index URL"
    case listURL = "Page URL"
    case responseURL = "Response URL"
    case parserType = "Page Style"
}

enum AddForumViewControllerType {
    case readonly
    case edit
}

class AddForumTableViewController: UITableViewController, SVWebViewProtocol {
    
    // MARK: UI elements.
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var pageURLLabel: UILabel!
    @IBOutlet weak var responseURLLabel: UILabel!
    @IBOutlet weak var pageStyleLabel: UILabel!
    @IBOutlet weak var nameDetailLabel: UILabel!
    @IBOutlet weak var indexDetailLabel: UILabel!
    @IBOutlet weak var pageDetailLabel: UILabel!
    @IBOutlet weak var responseDetailLabel: UILabel!
    @IBOutlet weak var parserPickerView: UIPickerView!
    @IBOutlet weak var addForumHelpButtonItem: UIBarButtonItem!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var addButtonTableViewCell: UITableViewCell!
    @IBOutlet weak var qrButtonTableViewCell: UITableViewCell!
    
    @objc var newForum: KomicaForum!
    @objc var unmodifiedForum: KomicaForum?
    var displayType = AddForumViewControllerType.edit
    
    // MARK: Private.
    fileprivate let pausedForumKey = "pausedForumKey"
    fileprivate let parserTypes = KomicaForum.parserNames
    fileprivate struct SegueIdentifier {
        static let name = "name"
        static let index = "index"
        static let page = "page"
        static let response = "response"
        static let showQRCode = "showQRCode"
    }
    
    // MARK: SVWebViewProtocol
    @objc var svWebViewURL: URL? {
        set {}
        get {
            return Configuration.singleton.addForumHelpURL as URL?
        }
    }
    @objc var svWebViewGuardDog: WebViewGuardDog? = {
        let guardDog = WebViewGuardDog()
        guardDog.showWarningOnBlock = true
        guardDog.home = Configuration.singleton.addForumHelpURL?.host
        return guardDog
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if newForum == nil {
            // Restore from cache.
            if let jsonString = UserDefaults.standard.object(forKey: pausedForumKey) as? String, !jsonString.isEmpty {
                if let jsonData = jsonString.data(using: String.Encoding.utf8),
                    let rawDict = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? Dictionary<String, AnyObject>,
                    let jsonDict = rawDict
                {
                    newForum = KomicaForum(jsonDict: jsonDict)
                }
            } else {
                // Cannot read from cache, create a new KomicaForum object.
                newForum = KomicaForum()
            }
        } else {
            unmodifiedForum = newForum
            addButton.setTitle("Save", for: .normal)
        }
        reload()
    }
    
    deinit {
        // Save the incompleted forum to NSUserDefaults.
        if displayType == .edit && newForum.isModified() {
            if newForum.parserType == nil {
                newForum.parserType = KomicaForum.parserTypes[parserPickerView.selectedRow(inComponent: 0)]
            }
            if let jsonString = newForum.jsonEncode(), !jsonString.isEmpty {
                UserDefaults.standard.set(jsonString, forKey: pausedForumKey)
                UserDefaults.standard.synchronize()
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var should = true
        if identifier == SegueIdentifier.showQRCode {
            should = newForum.isReady()
        }
        return should
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueIdentifier = segue.identifier,
            let textInputViewController = segue.destination as? ForumTextInputViewController
        {
            textInputViewController.delegate = self
            textInputViewController.allowEditing = displayType == .edit
            switch segueIdentifier {
            case SegueIdentifier.name:
                textInputViewController.field = ForumField.name
                textInputViewController.prefilledString = newForum.name
            case SegueIdentifier.index:
                textInputViewController.field = ForumField.indexURL
                textInputViewController.prefilledString = newForum.indexURL
            case SegueIdentifier.page:
                textInputViewController.field = ForumField.listURL
                textInputViewController.prefilledString = newForum.listURL
            case SegueIdentifier.response:
                textInputViewController.field = ForumField.responseURL
                textInputViewController.prefilledString = newForum.responseURL
            default:
                break
            }
        } else if segue.identifier == SegueIdentifier.showQRCode,
            let destinationViewController = segue.destination as? ShowForumQRCodeViewController
        {
            destinationViewController.forum = newForum
        }
    }

    @objc func reload() {
        addForumHelpButtonItem.isEnabled = Configuration.singleton.addForumHelpURL != nil
        let incompleted = "Incompleted..."
        title = newForum.name
        nameDetailLabel.text = !(newForum.name ?? "").isEmpty ? newForum.name : incompleted
        indexDetailLabel.text = !(newForum.indexURL ?? "").isEmpty ? newForum.indexURL : incompleted
        pageDetailLabel.text = !(newForum.listURL ?? "").isEmpty ? newForum.listURL : incompleted
        responseDetailLabel.text = !(newForum.responseURL ?? "").isEmpty ? newForum.responseURL : incompleted
        var selectRow = 0
        if let parserType = newForum.parserType {
             selectRow = KomicaForum.parserTypes.index(where: { $0 == parserType }) ?? 0
        }
        parserPickerView.selectRow(selectRow, inComponent: 0, animated: false)
        addButton.isEnabled = displayType == .edit
        resetButton.isEnabled = displayType == .edit
    }
    
    fileprivate func reportAdded(_ customForum: KomicaForum) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timeString = dateFormatter.string(from: Date())
        let nameString = "KV_ADD_CUSTOM_FORUM"
        if let vendorIDString = UIDevice.current.identifierForVendor?.uuidString,
            let contentString = customForum.jsonEncode(),
            let targetURL = URL(string: "http://civ.atwebpages.com/KomicaViewer/kv_add_custom_forum.php"),
            var targetURLComponent = URLComponents(url: targetURL, resolvingAgainstBaseURL: false) {
            let vendorQueryItem = URLQueryItem(name: "vendorID", value: vendorIDString)
            let nameQueryItem = URLQueryItem(name: "name", value: nameString)
            let timeQueryItem = URLQueryItem(name: "time", value: timeString)
            let contentQueryItem = URLQueryItem(name: "content", value: contentString)
            targetURLComponent.queryItems = [vendorQueryItem, nameQueryItem, timeQueryItem, contentQueryItem]
            // Create a quick and dirty connection to upload the content to server.
            if let url = targetURLComponent.url {
                NSURLConnection.sendAsynchronousRequest(URLRequest(url: url), queue: OperationQueue.main) {(response, data, error) in }
            }
        }
    }
}

// MARK: UI actions.
extension AddForumTableViewController {
    
    @IBAction func addForumHelpAction(_ sender: AnyObject) {
        presentSVWebView()
    }
    
    @IBAction func addForumAction(_ sender: UIButton) {
        DLog("")
        if !newForum.isReady() {
            let warning = "Supplied information not enough to construct a new board"
            DLog(warning)
            ProgressHUD.showMessage(warning)
        } else {
            newForum.parserType = KomicaForum.parserTypes[parserPickerView.selectedRow(inComponent: 0)]
            // Remove the original unmodified forum when it's presented.
            if let unmodifiedForum = unmodifiedForum {
                Forums.customForumGroup.forums?.removeObject(unmodifiedForum)
                Forums.saveCustomForums()
            }
            Forums.addCustomForum(newForum)
            // Report a custom forum has been added.
            reportAdded(newForum)
            _ = navigationController?.popToRootViewController(animated: true)
            // The forum has been added, reset the forum.
            newForum = KomicaForum()
            // Remove the paused forum from the user default.
            UserDefaults.standard.removeObject(forKey: self.pausedForumKey)
            UserDefaults.standard.synchronize()
            OperationQueue.main.addOperation({
                ProgressHUD.showMessage("\(self.newForum.name ?? "A new board") has been added")
            })
        }
    }

    @IBAction func resetForumAction(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Reset?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (_) in
            self.newForum = KomicaForum()
            self.reload()
            // Remove the paused forum from the user default.
            UserDefaults.standard.removeObject(forKey: self.pausedForumKey)
            UserDefaults.standard.synchronize()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = view.bounds
        if let topViewController = UIApplication.topViewController {
            topViewController.present(alertController, animated: true, completion: nil)
        }
    }
    
}

// MARK: ForumTextInputViewControllerProtocol
extension AddForumTableViewController: ForumTextInputViewControllerProtocol {
    
    func forumDetailEntered(_ inputViewController: ForumTextInputViewController, enteredDetails: String, forField field: ForumField) {
        // Safe guard.
        if enteredDetails.isEmpty {
            return
        }
        DLog("\(enteredDetails) - \(field)")
        switch field {
        case .indexURL:
            newForum.indexURL = enteredDetails
        case .listURL:
            newForum.listURL = enteredDetails
        case .name:
            newForum.name = enteredDetails
        case .responseURL:
            newForum.responseURL = enteredDetails
        default:
            break
        }
        reload()
    }
    
}


// MARK: UIPickerViewDelegate, UIPickerViewDataSource
extension AddForumTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return parserTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return parserTypes[row]
    }
}

// MARK: UITableViewDelegate
extension AddForumTableViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        // When the display type is editing, hide QR button.
        // When the display type is readyonly, hide the add/reset buttons.
        if (displayType == .edit && cell == qrButtonTableViewCell) ||
            (displayType == .readonly && cell == addButtonTableViewCell) {
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
}

extension KomicaForum {
    @objc func isReady() -> Bool {
        var isReady = true
        if (name ?? "").isEmpty
            || (indexURL ?? "" ).isEmpty
            || (listURL ?? "").isEmpty
            || (responseURL ?? "").isEmpty {
            isReady = false
        }
        return isReady
    }
    
    @objc func isModified() -> Bool {
        var isModified = false
        if !(name ?? "").isEmpty
            || !(indexURL ?? "" ).isEmpty
            || !(listURL ?? "").isEmpty
            || !(responseURL ?? "").isEmpty {
            isModified = true
        }
        return isModified
    }
}
