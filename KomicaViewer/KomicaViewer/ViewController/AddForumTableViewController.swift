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

}

// MARK: UI actions.
extension AddForumTableViewController {
    
    @IBAction func addForumAction(sender: UIButton) {
        DLog("")
    }

}

// MARK: ForumTextInputViewControllerProtocol
extension AddForumTableViewController: ForumTextInputViewControllerProtocol {
    
    func forumDetailEntered(inputViewController: ForumTextInputViewController, enteredDetails: String, forField: ForumField) {
        DLog("\(enteredDetails) - \(forField)")
    }
    
}