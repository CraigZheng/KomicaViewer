//
//  AddForumTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

enum ForumField: String {
    case name = "Name"
    case indexURL = "Index URL"
    case listURL = "Page URL"
    case responseURL = "Response URL"
    case parserType = "Page Style"
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
    
    var newForum: KomicaForum!
    
    // MARK: Private.
    private let pausedForumKey = "pausedForumKey"
    private let parserTypes = KomicaForum.parserNames
    private struct SegueIdentifier {
        static let name = "name"
        static let index = "index"
        static let page = "page"
        static let response = "response"
    }
    
    // MARK: SVWebViewProtocol
    var svWebViewURL: NSURL? {
        set {}
        get {
            return Configuration.singleton.addForumHelpURL
        }
    }
    var svWebViewGuardDog: WebViewGuardDog? = {
        let guardDog = WebViewGuardDog()
        guardDog.showWarningOnBlock = true
        guardDog.home = Configuration.singleton.addForumHelpURL?.host
        return guardDog
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if newForum == nil {
            // Restore from cache.
            if let jsonString = NSUserDefaults.standardUserDefaults().objectForKey(pausedForumKey) as? String where !jsonString.isEmpty {
                if let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
                    let rawDict = try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? Dictionary<String, AnyObject>,
                    let jsonDict = rawDict
                {
                    newForum = KomicaForum(jsonDict: jsonDict)
                }
            } else {
                // Cannot read from cache, create a new KomicaForum object.
                newForum = KomicaForum()
            }
        }
        reload()
    }
    
    deinit {
        // Save the incompleted forum to NSUserDefaults.
        if newForum.isModified() {
            if newForum.parserType == nil {
                newForum.parserType = KomicaForum.parserTypes[parserPickerView.selectedRowInComponent(0)]
            }
            if let jsonString = newForum.jsonEncode() where !jsonString.isEmpty {
                NSUserDefaults.standardUserDefaults().setObject(jsonString, forKey: pausedForumKey)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueIdentifier = segue.identifier,
            let textInputViewController = segue.destinationViewController as? ForumTextInputViewController
        {
            textInputViewController.delegate = self
            switch segueIdentifier {
            case SegueIdentifier.name:
                textInputViewController.field = ForumField.name
            case SegueIdentifier.index:
                textInputViewController.field = ForumField.indexURL
            case SegueIdentifier.page:
                textInputViewController.field = ForumField.listURL
            case SegueIdentifier.response:
                textInputViewController.field = ForumField.responseURL
            default:
                break
            }
        }
    }

    func reload() {
        addForumHelpButtonItem.enabled = Configuration.singleton.addForumHelpURL != nil
        let incompleted = "Incompleted..."
        nameDetailLabel.text = !(newForum.name ?? "").isEmpty ? newForum.name : incompleted
        indexDetailLabel.text = !(newForum.indexURL ?? "").isEmpty ? newForum.indexURL : incompleted
        pageDetailLabel.text = !(newForum.listURL ?? "").isEmpty ? newForum.listURL : incompleted
        responseDetailLabel.text = !(newForum.responseURL ?? "").isEmpty ? newForum.responseURL : incompleted
        var selectRow = 0
        if let parserType = newForum.parserType {
             selectRow = KomicaForum.parserTypes.indexOf({ $0 == parserType }) ?? 0
        }
        parserPickerView.selectRow(selectRow, inComponent: 0, animated: false)
    }
}

// MARK: UI actions.
extension AddForumTableViewController {
    
    @IBAction func addForumHelpAction(sender: AnyObject) {
        presentSVWebView()
    }
    
    @IBAction func addForumAction(sender: UIButton) {
        DLog("")
        if !newForum.isReady() {
            let warning = "Supplied information not enough to construct a new board"
            DLog(warning)
            ProgressHUD.showMessage(warning)
        } else {
            newForum.parserType = KomicaForum.parserTypes[parserPickerView.selectedRowInComponent(0)]
            Forums.addCustomForum(newForum)
            navigationController?.popToRootViewControllerAnimated(true)
            // The forum has been added, reset the forum.
            newForum = KomicaForum()
            // Remove the paused forum from the user default.
            NSUserDefaults.standardUserDefaults().removeObjectForKey(self.pausedForumKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            NSOperationQueue.mainQueue().addOperationWithBlock({
                ProgressHUD.showMessage("\(self.newForum.name ?? "A new board") has been added")
            })
        }
    }

    @IBAction func resetForumAction(sender: AnyObject) {
        let alertController = UIAlertController(title: "Reset?", message: nil, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (_) in
            self.newForum = KomicaForum()
            self.reload()
            // Remove the paused forum from the user default.
            NSUserDefaults.standardUserDefaults().removeObjectForKey(self.pausedForumKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = view.bounds
        if let topViewController = UIApplication.topViewController {
            topViewController.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: ForumTextInputViewControllerProtocol
extension AddForumTableViewController: ForumTextInputViewControllerProtocol {
    
    func forumDetailEntered(inputViewController: ForumTextInputViewController, enteredDetails: String, forField field: ForumField) {
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
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return parserTypes.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return parserTypes[row]
    }
}

extension KomicaForum {
    func isReady() -> Bool {
        var isReady = true
        if (name ?? "").isEmpty
            || (indexURL ?? "" ).isEmpty
            || (listURL ?? "").isEmpty
            || (responseURL ?? "").isEmpty {
            isReady = false
        }
        return isReady
    }
    
    func isModified() -> Bool {
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