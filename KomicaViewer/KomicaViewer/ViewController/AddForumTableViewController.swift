//
//  AddForumTableViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

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
    private struct ForumField {
        static let name = "name"
        static let indexURL = "Index URL"
        static let listURL = "Page URL"
        static let responseURL = "Response URL"
        static let parserType = "Page Style"
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
                textInputViewController.title = ForumField.name
            case SegueIdentifier.index:
                textInputViewController.title = ForumField.indexURL
            case SegueIdentifier.page:
                textInputViewController.title = ForumField.listURL
            case SegueIdentifier.response:
                textInputViewController.title = ForumField.responseURL
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
    
    func forumDetailEntered(inputViewController: ForumTextInputViewController, enteredDetails: String, forField: String) {
        DLog("\(enteredDetails) - \(forField)")
    }
    
}