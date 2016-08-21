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

class AddForumTableViewController: UITableViewController {
    
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
    @IBOutlet weak var pageStyleDetailLabel: UILabel!
    @IBOutlet weak var parserPickerFooterView: UIView!
    @IBOutlet weak var parserPickerView: UIPickerView!
    
    
    // MARK: Private.
    private let newForum = KomicaForum()
    private struct SegueIdentifier {
        static let name = "name"
        static let index = "index"
        static let page = "page"
        static let response = "response"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
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
        let incompleted = "Incompleted..."
        nameDetailLabel.text = newForum.name ?? incompleted
        indexDetailLabel.text = newForum.indexURL ?? incompleted
        pageDetailLabel.text = newForum.listURL ?? incompleted
        responseDetailLabel.text = newForum.responseURL ?? incompleted
//        pageStyleDetailLabel: UILabel! // TODO: complete the parser type.

    }
}

// MARK: UI actions.
extension AddForumTableViewController {
    @IBAction func okButtonAction(sender: AnyObject) {
    }
    
    @IBAction func addForumAction(sender: UIButton) {
        DLog("")
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
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
    }
}